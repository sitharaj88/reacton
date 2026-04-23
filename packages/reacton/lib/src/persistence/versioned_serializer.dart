import 'dart:convert';

import 'serializer.dart';

/// A migration function that transforms persisted JSON from one version to the
/// next. Migrations are keyed by the **target** version — `migrations[N]`
/// takes data persisted at version `N - 1` and returns data in the shape
/// expected at version `N`.
typedef JsonMigration = Map<String, dynamic> Function(
  Map<String, dynamic> oldData,
);

/// A [Serializer] that embeds a schema version and runs migrations on load.
///
/// Every real app eventually needs to change the shape of its persisted data.
/// [VersionedJsonSerializer] gives you a first-class way to do that without
/// writing a custom `onInit` or risking crashes on upgrade.
///
/// ```dart
/// final settingsSerializer = VersionedJsonSerializer<Settings>(
///   version: 3,
///   fromJson: Settings.fromJson,
///   toJson: (s) => s.toJson(),
///   migrations: {
///     // v0 -> v1: rename "dark" to "themeMode"
///     1: (old) => {...old, 'themeMode': old.remove('dark') == true ? 'dark' : 'light'},
///     // v1 -> v2: add default analytics opt-in
///     2: (old) => {...old, 'analytics': old['analytics'] ?? true},
///     // v2 -> v3: nest notifications under "prefs"
///     3: (old) => {
///       'prefs': {
///         'notifications': old.remove('notifications') ?? true,
///       },
///       ...old,
///     },
///   },
/// );
/// ```
///
/// On load:
///
/// 1. The wrapper reads the embedded `_v` field from the JSON payload.
/// 2. If `_v` equals [version], it decodes directly with [fromJson].
/// 3. Otherwise it runs every migration from `_v + 1` up to [version] in order.
/// 4. If any migration is missing, a [StateError] is thrown with a clear
///    message so you can add the missing step.
/// 5. If the stored version is **newer** than [version] — someone downgraded
///    the app — a [StateError] is thrown to prevent silent data corruption.
///
/// Legacy data (serialized without `_v`) is treated as version `0` and
/// migrations are applied from `1` upwards. This means an app that adopts
/// versioning mid-life should typically ship `version: 1` with a single
/// `migrations[1]` that handles the pre-versioned shape.
class VersionedJsonSerializer<T> implements Serializer<T> {
  /// The current schema version. Persisted values are tagged with this.
  final int version;

  /// Decode the (fully migrated) JSON map into a typed value.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Encode a typed value into a JSON map.
  final Map<String, dynamic> Function(T value) toJson;

  /// Migration step map. Keys are the **target** version of each step.
  ///
  /// A migration keyed `N` receives data in the shape expected at version
  /// `N - 1` and must return data in the shape expected at version `N`.
  final Map<int, JsonMigration> migrations;

  /// The name of the version field embedded in the serialized payload.
  /// Defaults to `_v`. Change it only if your domain type already uses that
  /// key for something else.
  final String versionKey;

  const VersionedJsonSerializer({
    required this.version,
    required this.fromJson,
    required this.toJson,
    this.migrations = const {},
    this.versionKey = '_v',
  }) : assert(version >= 1, 'version must be >= 1');

  @override
  String serialize(T value) {
    final payload = Map<String, dynamic>.from(toJson(value));
    payload[versionKey] = version;
    return jsonEncode(payload);
  }

  @override
  T deserialize(String data) {
    final decoded = jsonDecode(data);
    if (decoded is! Map) {
      throw FormatException(
        'VersionedJsonSerializer expected a JSON object, got ${decoded.runtimeType}',
      );
    }

    final payload = Map<String, dynamic>.from(decoded);
    final storedVersion = _readVersion(payload);

    payload.remove(versionKey);

    if (storedVersion > version) {
      throw StateError(
        'Persisted data is at version $storedVersion but the current '
        'serializer is at version $version. Refusing to downgrade — '
        'bump the serializer version or delete the persisted key.',
      );
    }

    var current = payload;
    for (var v = storedVersion + 1; v <= version; v++) {
      final step = migrations[v];
      if (step == null) {
        throw StateError(
          'Missing migration to version $v. Add `migrations[$v]` to the '
          'VersionedJsonSerializer so stored data at version ${v - 1} can '
          'be upgraded.',
        );
      }
      current = Map<String, dynamic>.from(step(current));
    }

    return fromJson(current);
  }

  int _readVersion(Map<String, dynamic> payload) {
    final raw = payload[versionKey];
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    throw FormatException(
      'Invalid "$versionKey" field: expected int, got ${raw.runtimeType}',
    );
  }
}
