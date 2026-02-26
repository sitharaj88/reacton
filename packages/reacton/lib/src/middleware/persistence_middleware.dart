import '../core/reacton_base.dart';
import '../persistence/serializer.dart';
import '../persistence/storage_adapter.dart';
import 'middleware.dart';

/// Built-in middleware for automatic reacton persistence.
///
/// Loads the stored value on initialization and saves after every write.
///
/// ```dart
/// final themeReacton = reacton(
///   ThemeMode.system,
///   options: ReactonOptions(
///     middleware: [
///       PersistenceMiddleware(
///         storage: sharedPrefsStorage,
///         serializer: EnumSerializer(ThemeMode.values),
///         key: 'app_theme',
///       ),
///     ],
///   ),
/// );
/// ```
class PersistenceMiddleware<T> extends Middleware<T> {
  final StorageAdapter _storage;
  final Serializer<T> _serializer;
  final String _key;

  PersistenceMiddleware({
    required StorageAdapter storage,
    required Serializer<T> serializer,
    required String key,
  })  : _storage = storage,
        _serializer = serializer,
        _key = key;

  @override
  T onInit(ReactonBase<T> reacton, T initialValue) {
    // Try to load persisted value
    final stored = _storage.read(_key);
    if (stored != null) {
      try {
        return _serializer.deserialize(stored);
      } catch (_) {
        // Deserialization failed - fall back to initial value
        return initialValue;
      }
    }
    return initialValue;
  }

  @override
  void onAfterWrite(ReactonBase<T> reacton, T value) {
    try {
      final serialized = _serializer.serialize(value);
      _storage.write(_key, serialized);
    } catch (_) {
      // Serialization failed - silently ignore
    }
  }

  @override
  void onDispose(ReactonBase<T> reacton) {
    // Optionally clear persisted value on dispose
    // _storage.delete(_key);
  }
}

/// Convenience middleware for persisting reactons with JSON serialization.
///
/// ```dart
/// final settingsReacton = reacton(
///   Settings.defaults(),
///   options: ReactonOptions(
///     middleware: [
///       JsonPersistenceMiddleware(
///         storage: memoryStorage,
///         key: 'settings',
///         toJson: (s) => s.toJson(),
///         fromJson: (j) => Settings.fromJson(j),
///       ),
///     ],
///   ),
/// );
/// ```
class JsonPersistenceMiddleware<T> extends PersistenceMiddleware<T> {
  JsonPersistenceMiddleware({
    required super.storage,
    required super.key,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
  }) : super(
          serializer: JsonSerializer<T>(toJson: toJson, fromJson: fromJson),
        );
}
