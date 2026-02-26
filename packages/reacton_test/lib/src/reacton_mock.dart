import 'package:reacton/reacton.dart';

/// A mock writable reacton for testing.
///
/// Provides additional tracking of read/write operations.
///
/// ```dart
/// final mockCounter = MockReacton(counterReacton, initialValue: 0);
/// store.forceSet(mockCounter.reacton, 10);
/// expect(mockCounter.writeCount, 1);
/// ```
class MockReacton<T> {
  final ReactonBase<T> reacton;
  final T initialValue;
  int _readCount = 0;
  int _writeCount = 0;
  final List<T> _valueHistory = [];

  MockReacton(this.reacton, {required this.initialValue}) {
    _valueHistory.add(initialValue);
  }

  /// Number of times this reacton was read.
  int get readCount => _readCount;

  /// Number of times this reacton was written.
  int get writeCount => _writeCount;

  /// All values this reacton has held, in order.
  List<T> get valueHistory => List.unmodifiable(_valueHistory);

  /// The last value written.
  T get lastValue => _valueHistory.last;

  /// Record a read.
  void recordRead() => _readCount++;

  /// Record a write.
  void recordWrite(T value) {
    _writeCount++;
    _valueHistory.add(value);
  }

  /// Reset all tracking counters.
  void reset() {
    _readCount = 0;
    _writeCount = 0;
    _valueHistory.clear();
    _valueHistory.add(initialValue);
  }
}
