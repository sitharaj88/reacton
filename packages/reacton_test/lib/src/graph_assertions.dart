import 'package:flutter_test/flutter_test.dart';
import 'package:reacton/reacton.dart';

/// Assertion extensions on [ReactonStore] for testing.
extension ReactonStoreTestExtensions on ReactonStore {
  /// Assert that a reacton has the expected value.
  void expectReacton<T>(ReactonBase<T> reacton, T expected) {
    final actual = get(reacton);
    expect(actual, equals(expected),
        reason: 'Expected ${reacton.ref} to be $expected, but was $actual');
  }

  /// Assert that an async reacton is in loading state.
  void expectLoading<T>(ReactonBase<AsyncValue<T>> reacton) {
    final value = get(reacton);
    expect(value.isLoading, isTrue,
        reason: 'Expected ${reacton.ref} to be loading, but was $value');
  }

  /// Assert that an async reacton has data.
  void expectData<T>(ReactonBase<AsyncValue<T>> reacton, T expected) {
    final value = get(reacton);
    expect(value.hasData, isTrue,
        reason: 'Expected ${reacton.ref} to have data, but was $value');
    expect(value.valueOrNull, equals(expected));
  }

  /// Assert that an async reacton has an error.
  void expectError<T>(ReactonBase<AsyncValue<T>> reacton) {
    final value = get(reacton);
    expect(value.hasError, isTrue,
        reason: 'Expected ${reacton.ref} to have error, but was $value');
  }

  /// Collect all values emitted by a reacton during [action].
  List<T> collectValues<T>(ReactonBase<T> reacton, void Function() action) {
    final values = <T>[];
    final unsub = subscribe(reacton, (T v) => values.add(v));
    action();
    unsub();
    return values;
  }

  /// Assert that a reacton emitted the expected values in order during [action].
  void expectEmissions<T>(
    ReactonBase<T> reacton,
    void Function() action,
    List<T> expectedValues,
  ) {
    final actual = collectValues(reacton, action);
    expect(actual, equals(expectedValues),
        reason: 'Expected emissions $expectedValues, but got $actual');
  }

  /// Assert that a reacton emitted exactly N values during [action].
  void expectEmissionCount<T>(
    ReactonBase<T> reacton,
    void Function() action,
    int expectedCount,
  ) {
    final actual = collectValues(reacton, action);
    expect(actual.length, equals(expectedCount),
        reason: 'Expected $expectedCount emissions, but got ${actual.length}');
  }
}
