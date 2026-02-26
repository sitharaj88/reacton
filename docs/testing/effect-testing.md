# Effect Testing

The `reacton_test` package provides two tools for testing side effects and tracking reacton interactions: `EffectTracker` and `MockReacton`.

## EffectTracker

`EffectTracker` records invocations of effects during tests. Use it to verify that effects ran, how many times they ran, and in what order.

### API

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `record(name, [metadata])` | `void` | Record an invocation with an optional metadata map |
| `invocations` | `List<EffectInvocation>` | All recorded invocations (unmodifiable) |
| `totalCallCount` | `int` | Total number of invocations across all effects |
| `callCount(name)` | `int` | Number of times a specific effect was called |
| `wasCalled(name)` | `bool` | Whether a specific effect was ever called |
| `wasAnyCalled` | `bool` | Whether any effect was called |
| `invocationsOf(name)` | `List<EffectInvocation>` | All invocations for a specific effect |
| `reset()` | `void` | Clear all recorded invocations |

### EffectInvocation

Each recorded invocation is an `EffectInvocation`:

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | The name passed to `record()` |
| `timestamp` | `DateTime` | When the invocation was recorded |
| `metadata` | `Map<String, dynamic>?` | Optional metadata |

### Basic Usage

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

final counterReacton = reacton(0, name: 'counter');

void main() {
  test('effect runs when dependency changes', () {
    final store = TestReactonStore();
    final tracker = EffectTracker();

    final dispose = store.registerEffect(createEffect((read) {
      tracker.record('logger');
      final count = read(counterReacton);
      // Side effect: log the count
      return null;
    }));

    // Effect runs once on registration (initial)
    expect(tracker.callCount('logger'), 1);

    // Change the dependency
    store.set(counterReacton, 1);
    expect(tracker.callCount('logger'), 2);

    store.set(counterReacton, 2);
    expect(tracker.callCount('logger'), 3);

    dispose();
  });
}
```

### Tracking with Metadata

Pass metadata to capture additional context about each invocation:

```dart
test('effect records metadata', () {
  final store = TestReactonStore();
  final tracker = EffectTracker();

  store.registerEffect(createEffect((read) {
    final count = read(counterReacton);
    tracker.record('counter_effect', {'value': count});
    return null;
  }));

  store.set(counterReacton, 5);

  final invocations = tracker.invocationsOf('counter_effect');
  expect(invocations.length, 2); // initial + update
  expect(invocations.last.metadata?['value'], 5);
});
```

### Verifying Effect Not Called

```dart
test('effect does not run for unrelated changes', () {
  final store = TestReactonStore();
  final tracker = EffectTracker();

  final nameReacton = reacton('', name: 'name');

  store.registerEffect(createEffect((read) {
    tracker.record('name_effect');
    read(nameReacton); // Only depends on nameReacton
    return null;
  }));

  tracker.reset(); // Clear initial invocation

  // Change a different reacton
  store.set(counterReacton, 42);

  expect(tracker.wasCalled('name_effect'), isFalse);
});
```

### Testing Effect Cleanup

Effects can return a cleanup function that runs before the next execution or on disposal:

```dart
test('effect cleanup runs', () {
  final store = TestReactonStore();
  final tracker = EffectTracker();

  final dispose = store.registerEffect(createEffect((read) {
    tracker.record('setup');
    read(counterReacton);

    return () {
      tracker.record('cleanup');
    };
  }));

  // Setup runs on registration
  expect(tracker.callCount('setup'), 1);
  expect(tracker.callCount('cleanup'), 0);

  // Change triggers cleanup then re-setup
  store.set(counterReacton, 1);
  expect(tracker.callCount('cleanup'), 1);
  expect(tracker.callCount('setup'), 2);

  // Disposal triggers cleanup
  dispose();
  expect(tracker.callCount('cleanup'), 2);
});
```

### Resetting Between Tests

Call `tracker.reset()` to clear all invocations:

```dart
late EffectTracker tracker;

setUp(() {
  tracker = EffectTracker();
});

// Or reset within a test:
test('multi-phase test', () {
  // ... phase 1 ...
  tracker.reset();
  // ... phase 2 starts fresh ...
});
```

## MockReacton

`MockReacton` wraps a real reacton and tracks how many times it was read and written. It also keeps a history of all values.

### API

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `reacton` | `ReactonBase<T>` | The underlying reacton being mocked |
| `initialValue` | `T` | The initial value |
| `readCount` | `int` | Number of recorded reads |
| `writeCount` | `int` | Number of recorded writes |
| `valueHistory` | `List<T>` | All values in order (starts with `initialValue`) |
| `lastValue` | `T` | The most recent value |
| `recordRead()` | `void` | Increment the read counter |
| `recordWrite(value)` | `void` | Increment the write counter and add to history |
| `reset()` | `void` | Reset all counters and history |

### Basic Usage

```dart
test('tracks read and write counts', () {
  final mock = MockReacton(counterReacton, initialValue: 0);
  final store = TestReactonStore();

  // Simulate writes
  store.forceSet(mock.reacton, 10);
  mock.recordWrite(10);

  store.forceSet(mock.reacton, 20);
  mock.recordWrite(20);

  expect(mock.writeCount, 2);
  expect(mock.valueHistory, [0, 10, 20]);
  expect(mock.lastValue, 20);
});
```

### Tracking Value History

```dart
test('value history captures all changes', () {
  final mock = MockReacton(counterReacton, initialValue: 0);

  mock.recordWrite(1);
  mock.recordWrite(2);
  mock.recordWrite(3);

  expect(mock.valueHistory, [0, 1, 2, 3]);
  expect(mock.lastValue, 3);
  expect(mock.writeCount, 3);
});
```

### Reset

```dart
test('reset clears all tracking', () {
  final mock = MockReacton(counterReacton, initialValue: 0);

  mock.recordRead();
  mock.recordRead();
  mock.recordWrite(5);

  expect(mock.readCount, 2);
  expect(mock.writeCount, 1);

  mock.reset();

  expect(mock.readCount, 0);
  expect(mock.writeCount, 0);
  expect(mock.valueHistory, [0]); // Reset to initial value
});
```

## Combining EffectTracker and MockReacton

Use both together for comprehensive side-effect verification:

```dart
test('effect reads counter and logs', () {
  final store = TestReactonStore();
  final tracker = EffectTracker();
  final mock = MockReacton(counterReacton, initialValue: 0);

  store.registerEffect(createEffect((read) {
    mock.recordRead();
    final count = read(counterReacton);
    tracker.record('log', {'count': count});
    return null;
  }));

  store.set(counterReacton, 42);
  mock.recordWrite(42);

  expect(tracker.callCount('log'), 2); // initial + update
  expect(mock.readCount, 2);           // read during each run
  expect(mock.writeCount, 1);          // one explicit write

  final lastInvocation = tracker.invocationsOf('log').last;
  expect(lastInvocation.metadata?['count'], 42);
});
```

## What's Next

- [Unit Testing](./unit-testing) -- TestReactonStore and overrides
- [Widget Testing](./widget-testing) -- Flutter widget test helpers
- [Assertions](./assertions) -- Fluent assertion helpers
