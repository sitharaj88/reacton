/// Abstract interface for persistent storage backends.
///
/// Implement this to provide custom storage (SharedPreferences, Hive,
/// SQLite, etc.). The default [MemoryStorage] is non-persistent.
///
/// ```dart
/// class SharedPrefsStorage implements StorageAdapter {
///   final SharedPreferences _prefs;
///   SharedPrefsStorage(this._prefs);
///
///   @override
///   String? read(String key) => _prefs.getString(key);
///
///   @override
///   Future<void> write(String key, String value) =>
///       _prefs.setString(key, value);
///   // ...
/// }
/// ```
abstract class StorageAdapter {
  /// Read a value by key. Returns null if not found.
  String? read(String key);

  /// Write a value by key.
  Future<void> write(String key, String value);

  /// Delete a value by key.
  Future<void> delete(String key);

  /// Check if a key exists.
  bool containsKey(String key);

  /// Clear all stored values.
  Future<void> clear();
}

/// In-memory storage adapter (non-persistent, for testing).
class MemoryStorage implements StorageAdapter {
  final Map<String, String> _data = {};

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<void> clear() async {
    _data.clear();
  }
}
