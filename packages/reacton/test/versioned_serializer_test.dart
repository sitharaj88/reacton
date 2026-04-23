import 'dart:convert';

import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

class Settings {
  final String themeMode;
  final bool analytics;
  final Map<String, Object?> prefs;

  const Settings({
    required this.themeMode,
    required this.analytics,
    this.prefs = const {},
  });

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'analytics': analytics,
        'prefs': prefs,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        themeMode: j['themeMode'] as String,
        analytics: j['analytics'] as bool,
        prefs: (j['prefs'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.themeMode == themeMode &&
      other.analytics == analytics &&
      _mapEq(other.prefs, prefs);

  @override
  int get hashCode => Object.hash(themeMode, analytics, prefs.length);

  static bool _mapEq(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (a[k] != b[k]) return false;
    }
    return true;
  }
}

Map<String, dynamic> _toSettings(Settings s) => s.toJson();

void main() {
  group('VersionedJsonSerializer — basic round-trip', () {
    const serializer = VersionedJsonSerializer<Settings>(
      version: 1,
      fromJson: Settings.fromJson,
      toJson: _toSettings,
    );

    test('serialize embeds the version field', () {
      const s = Settings(themeMode: 'dark', analytics: true);
      final raw = serializer.serialize(s);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['_v'], 1);
      expect(decoded['themeMode'], 'dark');
      expect(decoded['analytics'], isTrue);
    });

    test('serialize then deserialize at same version is an identity', () {
      const original = Settings(themeMode: 'light', analytics: false);
      final raw = serializer.serialize(original);
      final restored = serializer.deserialize(raw);
      expect(restored, original);
    });

    test('custom version key is respected', () {
      final custom = VersionedJsonSerializer<Settings>(
        version: 1,
        fromJson: Settings.fromJson,
        toJson: (s) => s.toJson(),
        versionKey: 'schema',
      );
      final raw = custom.serialize(
        const Settings(themeMode: 'dark', analytics: true),
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['schema'], 1);
      expect(decoded.containsKey('_v'), isFalse);
    });

    test('constructor rejects version < 1', () {
      expect(
        () => VersionedJsonSerializer<Settings>(
          version: 0,
          fromJson: Settings.fromJson,
          toJson: (s) => s.toJson(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('VersionedJsonSerializer — forward migrations', () {
    final serializer = VersionedJsonSerializer<Settings>(
      version: 3,
      fromJson: Settings.fromJson,
      toJson: (s) => s.toJson(),
      migrations: {
        1: (old) {
          // v0 -> v1: rename boolean "dark" to string "themeMode"
          final dark = old.remove('dark') == true;
          return {
            ...old,
            'themeMode': dark ? 'dark' : 'light',
          };
        },
        2: (old) => {
              ...old,
              'analytics': old['analytics'] ?? true,
            },
        3: (old) => {
              ...old,
              'prefs': <String, Object?>{
                'notifications': old.remove('notifications') ?? true,
              },
            },
      },
    );

    test('migrates data persisted before versioning (no _v field)', () {
      final legacy = jsonEncode({'dark': true, 'notifications': false});
      final restored = serializer.deserialize(legacy);
      expect(restored.themeMode, 'dark');
      expect(restored.analytics, isTrue); // defaulted in v2
      expect(restored.prefs['notifications'], isFalse);
    });

    test('migrates data persisted at version 1', () {
      final v1 = jsonEncode({
        '_v': 1,
        'themeMode': 'light',
        'notifications': true,
      });
      final restored = serializer.deserialize(v1);
      expect(restored.themeMode, 'light');
      expect(restored.analytics, isTrue);
      expect(restored.prefs['notifications'], isTrue);
    });

    test('migrates data persisted at version 2', () {
      final v2 = jsonEncode({
        '_v': 2,
        'themeMode': 'dark',
        'analytics': false,
        'notifications': false,
      });
      final restored = serializer.deserialize(v2);
      expect(restored.themeMode, 'dark');
      expect(restored.analytics, isFalse);
      expect(restored.prefs['notifications'], isFalse);
    });

    test('at current version skips migrations entirely', () {
      final v3 = jsonEncode({
        '_v': 3,
        'themeMode': 'dark',
        'analytics': true,
        'prefs': {'notifications': true},
      });
      final restored = serializer.deserialize(v3);
      expect(restored.themeMode, 'dark');
      expect(restored.analytics, isTrue);
      expect(restored.prefs['notifications'], isTrue);
    });

    test('migrations run in order (counts steps)', () {
      final log = <int>[];
      final s = VersionedJsonSerializer<Settings>(
        version: 3,
        fromJson: Settings.fromJson,
        toJson: (m) => m.toJson(),
        migrations: {
          1: (old) {
            log.add(1);
            return {
              ...old,
              'themeMode': old.remove('dark') == true ? 'dark' : 'light',
            };
          },
          2: (old) {
            log.add(2);
            return {...old, 'analytics': true};
          },
          3: (old) {
            log.add(3);
            return {
              ...old,
              'prefs': <String, Object?>{'notifications': true},
            };
          },
        },
      );
      s.deserialize(jsonEncode({'dark': false}));
      expect(log, [1, 2, 3]);
    });
  });

  group('VersionedJsonSerializer — error paths', () {
    test('missing migration step throws with a specific, grep-able message',
        () {
      final s = VersionedJsonSerializer<Settings>(
        version: 3,
        fromJson: Settings.fromJson,
        toJson: (m) => m.toJson(),
        migrations: {
          // 1 defined
          1: (old) => {
                'themeMode': 'light',
                'analytics': true,
                'prefs': <String, Object?>{},
              },
          // 2 missing
          3: (old) => old,
        },
      );
      expect(
        () => s.deserialize(jsonEncode({'_v': 1, 'themeMode': 'dark'})),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Missing migration to version 2'),
        )),
      );
    });

    test('stored version newer than serializer version throws', () {
      final s = VersionedJsonSerializer<Settings>(
        version: 2,
        fromJson: Settings.fromJson,
        toJson: (m) => m.toJson(),
        migrations: {
          1: (old) => old,
          2: (old) => old,
        },
      );
      expect(
        () => s.deserialize(jsonEncode({
          '_v': 5,
          'themeMode': 'dark',
          'analytics': true,
          'prefs': <String, Object?>{},
        })),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Refusing to downgrade'),
        )),
      );
    });

    test('non-object payload throws a FormatException', () {
      final s = VersionedJsonSerializer<Settings>(
        version: 1,
        fromJson: Settings.fromJson,
        toJson: (m) => m.toJson(),
      );
      expect(
        () => s.deserialize('[1, 2, 3]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('non-int version field throws a FormatException', () {
      final s = VersionedJsonSerializer<Settings>(
        version: 1,
        fromJson: Settings.fromJson,
        toJson: (m) => m.toJson(),
      );
      expect(
        () => s.deserialize(jsonEncode({'_v': 'oops', 'themeMode': 'dark'})),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('VersionedJsonSerializer — integration with PersistenceMiddleware', () {
    test('writes wrapped payload and reads it back unchanged', () {
      final storage = MemoryStorage();
      final serializer = VersionedJsonSerializer<Settings>(
        version: 2,
        fromJson: Settings.fromJson,
        toJson: (m) => m.toJson(),
        migrations: {
          1: (old) => {
                ...old,
                'themeMode': old.remove('dark') == true ? 'dark' : 'light',
              },
          2: (old) => {...old, 'analytics': true},
        },
      );

      // Seed legacy data (no version, booleans)
      storage.write('settings', jsonEncode({'dark': true}));

      final middleware = PersistenceMiddleware<Settings>(
        storage: storage,
        serializer: serializer,
        key: 'settings',
      );

      final reactonRef = reacton<Settings>(
        const Settings(themeMode: 'light', analytics: false),
        name: 'settings',
        options: ReactonOptions<Settings>(middleware: [middleware]),
      );

      final store = ReactonStore();
      final restored = store.get(reactonRef);
      expect(restored.themeMode, 'dark');
      expect(restored.analytics, isTrue);

      // Writing now re-saves at current version 2
      store.set(
        reactonRef,
        const Settings(themeMode: 'light', analytics: false),
      );

      final stored = storage.read('settings')!;
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      expect(decoded['_v'], 2);
      expect(decoded['themeMode'], 'light');
      expect(decoded['analytics'], isFalse);
    });
  });
}
