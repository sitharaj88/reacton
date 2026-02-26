import '../core/writable_reacton.dart';
import '../store/store.dart';
import '../utils/disposable.dart';

/// A single entry in the history log.
class HistoryEntry<T> {
  /// The value at this point in history.
  final T value;

  /// When this entry was recorded.
  final DateTime timestamp;

  /// Optional label describing what caused this change.
  final String? label;

  const HistoryEntry({
    required this.value,
    required this.timestamp,
    this.label,
  });

  @override
  String toString() => 'HistoryEntry($value, $timestamp${label != null ? ', $label' : ''})';
}

/// Time-travel controller for a reacton.
///
/// Records all value changes and provides undo/redo/jumpTo capabilities.
///
/// ```dart
/// final history = store.enableHistory(counterReacton, maxHistory: 50);
/// store.set(counterReacton, 1);
/// store.set(counterReacton, 2);
/// store.set(counterReacton, 3);
///
/// history.undo(); // counter = 2
/// history.undo(); // counter = 1
/// history.redo(); // counter = 2
/// history.jumpTo(0); // counter = initial value
/// ```
class History<T> with Disposable {
  final ReactonStore _store;
  final WritableReacton<T> _reacton;
  final int _maxHistory;
  final List<HistoryEntry<T>> _entries = [];
  int _currentIndex = -1;
  bool _isUndoRedo = false;
  Unsubscribe? _unsubscribe;

  History(this._store, this._reacton, {int maxHistory = 100})
      : _maxHistory = maxHistory {
    // Record initial value
    _record(_store.get(_reacton));

    // Subscribe to changes
    _unsubscribe = _store.subscribe(_reacton, (T value) {
      if (!_isUndoRedo) {
        _record(value);
      }
    });
  }

  /// All history entries.
  List<HistoryEntry<T>> get entries => List.unmodifiable(_entries);

  /// The current position in history.
  int get currentIndex => _currentIndex;

  /// Whether undo is available.
  bool get canUndo => _currentIndex > 0;

  /// Whether redo is available.
  bool get canRedo => _currentIndex < _entries.length - 1;

  /// The total number of history entries.
  int get length => _entries.length;

  /// The current value.
  T get currentValue => _entries[_currentIndex].value;

  /// Undo: go back one step in history.
  void undo() {
    if (!canUndo) return;
    _currentIndex--;
    _applyCurrentEntry();
  }

  /// Redo: go forward one step in history.
  void redo() {
    if (!canRedo) return;
    _currentIndex++;
    _applyCurrentEntry();
  }

  /// Jump to a specific index in history.
  void jumpTo(int index) {
    assert(index >= 0 && index < _entries.length, 'Index out of range');
    _currentIndex = index;
    _applyCurrentEntry();
  }

  /// Clear all history and start fresh with the current value.
  void clear() {
    _entries.clear();
    _record(_store.get(_reacton));
  }

  void _record(T value, {String? label}) {
    // If we're not at the end, remove future entries (fork)
    if (_currentIndex < _entries.length - 1) {
      _entries.removeRange(_currentIndex + 1, _entries.length);
    }

    _entries.add(HistoryEntry(
      value: value,
      timestamp: DateTime.now(),
      label: label,
    ));

    // Enforce max history
    while (_entries.length > _maxHistory) {
      _entries.removeAt(0);
    }

    _currentIndex = _entries.length - 1;
  }

  void _applyCurrentEntry() {
    _isUndoRedo = true;
    try {
      _store.set(_reacton, _entries[_currentIndex].value);
    } finally {
      _isUndoRedo = false;
    }
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _entries.clear();
    super.dispose();
  }
}

/// Extension on ReactonStore for time-travel.
extension ReactonStoreHistory on ReactonStore {
  /// Enable time-travel (undo/redo) for a reacton.
  ///
  /// Returns a [History] controller that tracks all changes.
  History<T> enableHistory<T>(WritableReacton<T> reacton, {int maxHistory = 100}) {
    return History<T>(this, reacton, maxHistory: maxHistory);
  }
}
