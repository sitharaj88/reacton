# Persistence Migrations

Every real app eventually needs to change the shape of its persisted data. Rename a field. Add a default. Nest something under a new object. Without migrations, a user who upgrades their app to a new schema wakes up to a crash or a wiped-out profile.

`VersionedJsonSerializer<T>` is a first-class migration layer on top of the existing [persistence](/advanced/persistence) API. It embeds a schema version in the stored payload and runs your migrations in order on load.

[[toc]]

## Why embedded versions

Alternatives we considered and rejected:

- **Storage-key versioning** (e.g. `settings_v2`). Leaks old keys on disk indefinitely, requires manual migration code, and forces you to care about the whole storage adapter.
- **Heuristic detection** (sniff the shape of the JSON). Brittle, slow, silently wrong when two versions happen to parse equally.
- **Deleting-on-change**. Loses user data. Never acceptable for settings, auth, or any state the user created.

Embedded versioning puts one extra field (`_v`) inside the serialized payload. The payload travels with its version; migrations are declarative; rollbacks are explicit errors instead of silent corruption.

## Basic usage

```dart
final settingsSerializer = VersionedJsonSerializer<Settings>(
  version: 2,
  fromJson: Settings.fromJson,
  toJson: (s) => s.toJson(),
  migrations: {
    // v0 (legacy, no _v field) -> v1: rename "dark" boolean to "themeMode" string
    1: (old) => {
      ...old,
      'themeMode': old.remove('dark') == true ? 'dark' : 'light',
    },
    // v1 -> v2: add an "analytics" opt-in, defaulting to true
    2: (old) => {...old, 'analytics': old['analytics'] ?? true},
  },
);

final settingsReacton = reacton<Settings>(
  Settings.defaults(),
  name: 'settings',
  options: ReactonOptions<Settings>(
    middleware: [
      PersistenceMiddleware<Settings>(
        storage: sharedPrefsStorage,
        serializer: settingsSerializer,
        key: 'settings',
      ),
    ],
  ),
);
```

On load:

1. The serializer reads `_v` from the stored payload. Missing `_v` is treated as version `0`.
2. It walks `migrations[stored+1]`, `migrations[stored+2]`, ..., `migrations[version]` in order.
3. The fully-migrated JSON is passed to `fromJson`.
4. Writes always save at the current `version`.

## API

```dart
class VersionedJsonSerializer<T> implements Serializer<T> {
  const VersionedJsonSerializer({
    required int version,                                  // must be >= 1
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    Map<int, JsonMigration> migrations = const {},
    String versionKey = '_v',
  });
}

typedef JsonMigration = Map<String, dynamic> Function(
  Map<String, dynamic> oldData,
);
```

- **`version`** — current schema version. Writes tag the payload with this.
- **`fromJson` / `toJson`** — your normal JSON codec. Runs only on data already at the current version.
- **`migrations[N]`** — takes data in shape `N-1`, returns data in shape `N`. Keyed by target version.
- **`versionKey`** — the field embedded in the payload. Change only if `_v` conflicts with your domain.

## Adopting versioning mid-flight

Existing apps will have pre-versioned data on disk. Treat those payloads as **version `0`** and ship your first versioned serializer at `version: 1` with `migrations[1]` handling the legacy shape:

```dart
VersionedJsonSerializer<User>(
  version: 1,
  fromJson: User.fromJson,
  toJson: (u) => u.toJson(),
  migrations: {
    1: (old) {
      // Legacy payloads used `full_name`; we now split into first/last.
      final parts = (old['full_name'] as String? ?? '').split(' ');
      return {
        'firstName': parts.isNotEmpty ? parts.first : '',
        'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        ...old..remove('full_name'),
      };
    },
  },
);
```

## Error handling

| Situation | Behavior |
|-----------|----------|
| Stored version equals `version` | Skip migrations, decode directly. |
| Stored version less than `version`, all migrations present | Apply each migration in order, decode. |
| Stored version less than `version`, **any** migration missing | Throws `StateError: Missing migration to version N` so the omission is discovered during development. |
| Stored version **greater** than `version` | Throws `StateError: Refusing to downgrade`. This protects against users downgrading the app without a rollback plan. |
| Payload is not a JSON object | Throws `FormatException`. |
| `_v` field is not an int | Throws `FormatException`. |

Every error message includes the specific version pair so you can grep for it in crash logs.

## Patterns

### Adding a field with a default

```dart
2: (old) => {...old, 'analytics': old['analytics'] ?? true},
```

### Renaming a field

```dart
3: (old) {
  final copy = Map<String, dynamic>.from(old);
  copy['themeMode'] = copy.remove('theme');
  return copy;
},
```

### Nesting under a new key

```dart
4: (old) => {
  'prefs': {
    'notifications': old.remove('notifications') ?? true,
    'sound': old.remove('sound') ?? false,
  },
  ...old,
},
```

### Splitting one field into many

```dart
5: (old) {
  final fullName = old['name'] as String? ?? '';
  final parts = fullName.split(' ');
  return {
    ...old..remove('name'),
    'firstName': parts.isNotEmpty ? parts.first : '',
    'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
  };
},
```

### Dropping a field

```dart
6: (old) => {...old..remove('deprecatedField')},
```

## Testing your migrations

Migrations are pure `Map<String, dynamic> -> Map<String, dynamic>` functions. Unit-test them with literal JSON:

```dart
test('v1 -> v2 adds analytics default', () {
  final v1 = {'themeMode': 'dark'};
  final v2 = migrations[2]!(v1);
  expect(v2['analytics'], isTrue);
  expect(v2['themeMode'], 'dark');
});
```

For end-to-end safety, also test a full upgrade path:

```dart
test('upgrades legacy v0 data all the way to current', () {
  storage.write('settings', jsonEncode({'dark': true}));

  final store = ReactonStore();
  final restored = store.get(settingsReacton);

  expect(restored.themeMode, 'dark');
  expect(restored.analytics, isTrue);
});
```

## Tips

- **Ship every migration forever.** Once a migration is in production, removing it breaks users who haven't opened the app in a while.
- **Make migrations idempotent-ish.** If a field is already in the new shape, the migration should tolerate it. Users sometimes restore backups from different versions.
- **Keep migrations tiny.** One schema change per step is easier to reason about and test than one-shot mega-migrations.
- **Log the migration path in dev.** When a user reports a weird settings bug, knowing which migrations ran and in what order is gold.
- **Never downgrade silently.** The built-in "Refusing to downgrade" error is a feature, not a bug — users who flashed an older build should not overwrite new-schema data.
