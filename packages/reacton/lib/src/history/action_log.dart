import '../core/reacton_base.dart';

/// A record of a single state mutation.
class ActionRecord {
  /// The reacton that was modified.
  final ReactonRef reactonRef;

  /// The previous value.
  final dynamic oldValue;

  /// The new value.
  final dynamic newValue;

  /// When the action occurred.
  final DateTime timestamp;

  /// Stack trace at the point of mutation (for debugging).
  final StackTrace? stackTrace;

  const ActionRecord({
    required this.reactonRef,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    this.stackTrace,
  });

  @override
  String toString() => 'ActionRecord($reactonRef, $oldValue -> $newValue)';
}

/// A complete audit log of all state mutations.
///
/// Useful for debugging, analytics, and DevTools integration.
class ActionLog {
  final List<ActionRecord> _records = [];
  final int _maxRecords;
  bool _enabled = true;

  ActionLog({int maxRecords = 1000}) : _maxRecords = maxRecords;

  /// All recorded actions.
  List<ActionRecord> get records => List.unmodifiable(_records);

  /// Whether logging is enabled.
  bool get isEnabled => _enabled;

  /// Enable logging.
  void enable() => _enabled = true;

  /// Disable logging.
  void disable() => _enabled = false;

  /// Record a mutation.
  void record(ActionRecord action) {
    if (!_enabled) return;
    _records.add(action);
    while (_records.length > _maxRecords) {
      _records.removeAt(0);
    }
  }

  /// Get all records for a specific reacton.
  List<ActionRecord> forReacton(ReactonRef ref) {
    return _records.where((r) => r.reactonRef == ref).toList();
  }

  /// Get records within a time range.
  List<ActionRecord> inRange(DateTime from, DateTime to) {
    return _records.where(
      (r) => r.timestamp.isAfter(from) && r.timestamp.isBefore(to),
    ).toList();
  }

  /// Clear all records.
  void clear() => _records.clear();

  /// Total number of recorded actions.
  int get length => _records.length;
}
