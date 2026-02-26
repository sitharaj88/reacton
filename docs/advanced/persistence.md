# Persistence

Reacton supports automatic persistence of reacton values to any storage backend. When a reacton has a `persistKey` and `serializer` configured, its value is automatically saved when written and restored when initialized.

## How It Works

1. Configure a `StorageAdapter` (the storage backend) when creating the store.
2. Set `persistKey` and `serializer` in the reacton's `ReactonOptions`.
3. On initialization, the store reads the persisted value (if any) and uses it instead of the initial value.
4. On write, the store serializes and saves the new value.

```dart
final store = ReactonStore(
  storageAdapter: SharedPrefsStorage(prefs),
);

final themeReacton = reacton(
  ThemeMode.system,
  name: 'theme',
  options: ReactonOptions(
    persistKey: 'user_theme',
    serializer: EnumSerializer(ThemeMode.values),
  ),
);
```

## StorageAdapter

`StorageAdapter` is an abstract interface for persistent storage backends. Implement it for your chosen storage technology (SharedPreferences, Hive, SQLite, etc.).

```dart
abstract class StorageAdapter {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  bool containsKey(String key);
  Future<void> clear();
}
```

| Method | Returns | Description |
|--------|---------|-------------|
| `read(key)` | `String?` | Read a value by key. Returns `null` if not found. |
| `write(key, value)` | `Future<void>` | Write a value by key. |
| `delete(key)` | `Future<void>` | Delete a value by key. |
| `containsKey(key)` | `bool` | Check if a key exists. |
| `clear()` | `Future<void>` | Clear all stored values. |

### MemoryStorage (Built-in)

A non-persistent in-memory adapter, useful for testing:

```dart
final store = ReactonStore(
  storageAdapter: MemoryStorage(),
);
```

### SharedPreferences Adapter

```dart
class SharedPrefsStorage implements StorageAdapter {
  final SharedPreferences _prefs;

  SharedPrefsStorage(this._prefs);

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);

  @override
  bool containsKey(String key) => _prefs.containsKey(key);

  @override
  Future<void> clear() => _prefs.clear();
}
```

### Hive Adapter

```dart
class HiveStorage implements StorageAdapter {
  final Box _box;

  HiveStorage(this._box);

  @override
  String? read(String key) => _box.get(key) as String?;

  @override
  Future<void> write(String key, String value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  bool containsKey(String key) => _box.containsKey(key);

  @override
  Future<void> clear() => _box.clear();
}
```

## Serializer&lt;T&gt;

A `Serializer<T>` converts between a value of type `T` and a `String` for storage.

```dart
abstract class Serializer<T> {
  String serialize(T value);
  T deserialize(String data);
}
```

### Built-in Serializers

Reacton ships with serializers for common types.

#### PrimitiveSerializer

For `int`, `double`, `String`, and `bool`:

```dart
final counterReacton = reacton(0, options: ReactonOptions(
  persistKey: 'counter',
  serializer: PrimitiveSerializer<int>(),
));

final nameReacton = reacton('', options: ReactonOptions(
  persistKey: 'user_name',
  serializer: PrimitiveSerializer<String>(),
));
```

#### EnumSerializer

For enum values. Pass the enum's `.values` list:

```dart
enum ThemeMode { light, dark, system }

final themeReacton = reacton(ThemeMode.system, options: ReactonOptions(
  persistKey: 'theme',
  serializer: EnumSerializer(ThemeMode.values),
));
```

#### JsonSerializer

For types with `toJson()` / `fromJson()` methods:

```dart
final userReacton = reacton(
  User.guest(),
  options: ReactonOptions(
    persistKey: 'current_user',
    serializer: JsonSerializer<User>(
      toJson: (user) => user.toJson(),
      fromJson: (json) => User.fromJson(json),
    ),
  ),
);
```

**Constructor:**

```dart
const JsonSerializer({
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
});
```

#### ListSerializer

For `List<T>` values, wrapping an item serializer:

```dart
final tagsReacton = reacton<List<String>>(
  [],
  options: ReactonOptions(
    persistKey: 'tags',
    serializer: ListSerializer(PrimitiveSerializer<String>()),
  ),
);

final usersReacton = reacton<List<User>>(
  [],
  options: ReactonOptions(
    persistKey: 'users',
    serializer: ListSerializer(JsonSerializer<User>(
      toJson: (u) => u.toJson(),
      fromJson: (json) => User.fromJson(json),
    )),
  ),
);
```

### Serializer Summary

| Serializer | Type | Usage |
|-----------|------|-------|
| `PrimitiveSerializer<T>()` | `int`, `double`, `String`, `bool` | Basic types |
| `EnumSerializer<T>(T.values)` | Any `Enum` | Enum values |
| `JsonSerializer<T>(fromJson, toJson)` | Custom objects | Classes with JSON conversion |
| `ListSerializer<T>(itemSerializer)` | `List<T>` | Lists of any serializable type |

### Custom Serializer

For types that need special handling, implement `Serializer<T>` directly:

```dart
class DateTimeSerializer implements Serializer<DateTime> {
  @override
  String serialize(DateTime value) => value.toIso8601String();

  @override
  DateTime deserialize(String data) => DateTime.parse(data);
}

class ColorSerializer implements Serializer<Color> {
  @override
  String serialize(Color value) => value.value.toString();

  @override
  Color deserialize(String data) => Color(int.parse(data));
}
```

## ReactonOptions for Persistence

The relevant fields in `ReactonOptions`:

| Property | Type | Description |
|----------|------|-------------|
| `persistKey` | `String?` | The storage key. If set (and a `StorageAdapter` is configured on the store), the reacton is auto-persisted. |
| `serializer` | `Serializer<T>?` | The serializer used to convert values to/from strings. Required when `persistKey` is set. |

::: warning
If `persistKey` is set but no `serializer` is provided, or if the store has no `StorageAdapter`, persistence is silently skipped. No error is thrown.
:::

::: tip
If deserialization fails (e.g., the stored format has changed), the reacton falls back to its initial value. This prevents crashes from stale persisted data after schema changes.
:::

## Complete Example

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Storage adapter
late final SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();

  runApp(
    ReactonScope(
      store: ReactonStore(
        storageAdapter: SharedPrefsStorage(prefs),
      ),
      child: MyApp(),
    ),
  );
}

// Persisted reactons
final themeReacton = reacton(ThemeMode.system, options: ReactonOptions(
  persistKey: 'app_theme',
  serializer: EnumSerializer(ThemeMode.values),
));

final localeReacton = reacton('en', options: ReactonOptions(
  persistKey: 'app_locale',
  serializer: PrimitiveSerializer<String>(),
));

final onboardingCompleteReacton = reacton(false, options: ReactonOptions(
  persistKey: 'onboarding_complete',
  serializer: PrimitiveSerializer<bool>(),
));

// Widget
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch(themeReacton);

    return SwitchListTile(
      title: Text('Dark Mode'),
      value: theme == ThemeMode.dark,
      onChanged: (dark) {
        // Automatically persisted to SharedPreferences
        context.set(themeReacton, dark ? ThemeMode.dark : ThemeMode.light);
      },
    );
  }
}
```

## Middleware-Based Persistence

In addition to the manual `persistKey` + `serializer` approach shown above, Reacton provides a `PersistenceMiddleware` that handles persistence entirely through the middleware system. See the [Middleware](/advanced/middleware#built-in-persistencemiddleware) page for full API details.

`PersistenceMiddleware` simplifies setup by bundling the storage adapter, serializer, and key into a single middleware instance -- no store-level `StorageAdapter` required.

### Manual vs Middleware Comparison

**Manual approach** (store-level `StorageAdapter` + `ReactonOptions`):

```dart
// 1. Configure storage on the store
final store = ReactonStore(
  storageAdapter: SharedPrefsStorage(prefs),
);

// 2. Set persistKey and serializer in options
final themeReacton = reacton(
  ThemeMode.system,
  options: ReactonOptions(
    persistKey: 'app_theme',
    serializer: EnumSerializer(ThemeMode.values),
  ),
);
```

**Middleware approach** (`PersistenceMiddleware`):

```dart
// No store-level storage adapter needed
final store = ReactonStore();

// Storage, serializer, and key are all on the middleware
final themeReacton = reacton(
  ThemeMode.system,
  options: ReactonOptions(
    middleware: [
      PersistenceMiddleware<ThemeMode>(
        storage: SharedPrefsStorage(prefs),
        serializer: EnumSerializer(ThemeMode.values),
        key: 'app_theme',
      ),
    ],
  ),
);
```

Both approaches produce the same result: the reacton value is loaded from storage on initialization and saved after every write. The key differences are:

| | Manual (`persistKey`) | `PersistenceMiddleware` |
|---|---|---|
| **Store setup** | Requires a `StorageAdapter` on the store. | No store-level configuration needed. |
| **Storage backend** | All persisted reactons share one storage backend. | Each reacton can use a different storage backend. |
| **Composability** | Standalone -- not part of the middleware pipeline. | Composes with other middleware (e.g., logging, validation). |

::: tip
For JSON-serializable objects, `JsonPersistenceMiddleware` lets you pass `toJson` and `fromJson` callbacks directly, removing the need to construct a `JsonSerializer` separately. See [Middleware: PersistenceMiddleware](/advanced/middleware#built-in-persistencemiddleware) for details.
:::

## What's Next

- [History](/advanced/history) -- Add undo/redo and time-travel debugging
- [State Branching](/advanced/branching) -- Preview state changes before committing
- [Middleware](/advanced/middleware) -- Intercept writes for logging and validation
