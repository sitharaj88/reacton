# Assertions

The `reacton_test` package provides assertion extensions on `ReactonStore` for clean, expressive test expectations. These are defined in the `ReactonStoreTestExtensions` extension.

## Import

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';
```

## API Reference

| Method | Description |
|--------|-------------|
| `expectReacton<T>(reacton, expected)` | Assert a reacton has a specific value |
| `expectLoading<T>(reacton)` | Assert an async reacton is in loading state |
| `expectData<T>(reacton, expected)` | Assert an async reacton has specific data |
| `expectError<T>(reacton)` | Assert an async reacton is in error state |
| `collectValues<T>(reacton, action)` | Collect all emitted values during an action |
| `expectEmissions<T>(reacton, action, expected)` | Assert specific emissions during an action |
| `expectEmissionCount<T>(reacton, action, count)` | Assert the number of emissions during an action |

## expectReacton

Assert that a reacton currently holds a specific value.

```dart
void expectReacton<T>(ReactonBase<T> reacton, T expected)
```

```dart
test('counter has expected value', () {
  final store = TestReactonStore();
  store.set(counterReacton, 42);

  store.expectReacton(counterReacton, 42);
});
```

When the assertion fails, it provides a clear error message:

```
Expected counter to be 42, but was 0
```

## expectLoading

Assert that an async reacton is currently in the loading state.

```dart
void expectLoading<T>(ReactonBase<AsyncValue<T>> reacton)
```

```dart
test('weather starts as loading', () {
  final store = TestReactonStore(overrides: [
    AsyncReactonTestOverride.loading(weatherReacton),
  ]);

  store.expectLoading(weatherReacton);
});
```

## expectData

Assert that an async reacton has completed with specific data.

```dart
void expectData<T>(ReactonBase<AsyncValue<T>> reacton, T expected)
```

```dart
test('weather has data', () {
  final store = TestReactonStore(overrides: [
    AsyncReactonTestOverride.data(weatherReacton, Weather(temp: 72)),
  ]);

  store.expectData(weatherReacton, Weather(temp: 72));
});
```

This asserts two things:
1. The async value is in the data state (`hasData` is true)
2. The contained value equals the expected value

## expectError

Assert that an async reacton is in the error state.

```dart
void expectError<T>(ReactonBase<AsyncValue<T>> reacton)
```

```dart
test('weather has error', () {
  final store = TestReactonStore(overrides: [
    AsyncReactonTestOverride.error(
      weatherReacton,
      Exception('timeout'),
    ),
  ]);

  store.expectError(weatherReacton);
});
```

## collectValues

Collect all values emitted by a reacton during a synchronous action block. Returns the list of emitted values.

```dart
List<T> collectValues<T>(ReactonBase<T> reacton, void Function() action)
```

```dart
test('collects emitted values', () {
  final store = TestReactonStore();

  final values = store.collectValues(counterReacton, () {
    store.set(counterReacton, 1);
    store.set(counterReacton, 2);
    store.set(counterReacton, 3);
  });

  expect(values, [1, 2, 3]);
});
```

::: tip
`collectValues` subscribes before the action and unsubscribes after, so it only captures values emitted during the action block. The subscription is automatically cleaned up.
:::

## expectEmissions

Assert that a reacton emits exactly the expected values in order during an action block.

```dart
void expectEmissions<T>(
  ReactonBase<T> reacton,
  void Function() action,
  List<T> expectedValues,
)
```

```dart
test('counter emits correct sequence', () {
  final store = TestReactonStore();

  store.expectEmissions(
    counterReacton,
    () {
      store.set(counterReacton, 10);
      store.set(counterReacton, 20);
      store.set(counterReacton, 30);
    },
    [10, 20, 30],
  );
});
```

When the assertion fails:

```
Expected emissions [10, 20, 30], but got [10, 20]
```

## expectEmissionCount

Assert that a reacton emits exactly N values during an action block.

```dart
void expectEmissionCount<T>(
  ReactonBase<T> reacton,
  void Function() action,
  int expectedCount,
)
```

```dart
test('batch emits once', () {
  final store = TestReactonStore();

  // Without batch: two emissions
  store.expectEmissionCount(
    counterReacton,
    () {
      store.set(counterReacton, 1);
      store.set(counterReacton, 2);
    },
    2,
  );
});
```

This is useful for verifying that batch operations or equality checks reduce unnecessary notifications.

## Combining Assertions

These assertions compose well together for thorough tests:

```dart
test('full computed reacton test', () {
  final store = TestReactonStore();

  // Verify initial state
  store.expectReacton(todosReacton, []);
  store.expectReacton(todoCountReacton, 0);

  // Verify emissions during mutation
  store.expectEmissions(
    todoCountReacton,
    () {
      store.set(todosReacton, ['A']);
      store.set(todosReacton, ['A', 'B']);
      store.set(todosReacton, ['A', 'B', 'C']);
    },
    [1, 2, 3],
  );

  // Verify final state
  store.expectReacton(todoCountReacton, 3);
});
```

## Testing Equality Suppression

Reacton skips notifications when the new value equals the old value. Use `expectEmissionCount` to verify this behavior:

```dart
test('skips duplicate values', () {
  final store = TestReactonStore();

  store.expectEmissionCount(
    counterReacton,
    () {
      store.set(counterReacton, 1);
      store.set(counterReacton, 1); // duplicate -- skipped
      store.set(counterReacton, 2);
    },
    2, // only 1 and 2, not the duplicate
  );
});
```

## What's Next

- [Effect Testing](./effect-testing) -- EffectTracker and MockReacton
- [Unit Testing](./unit-testing) -- TestReactonStore and overrides
- [Widget Testing](./widget-testing) -- Pump helpers for Flutter tests
