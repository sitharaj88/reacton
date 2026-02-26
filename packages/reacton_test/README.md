# reacton_test

Testing utilities for the Reacton state management library. Provides `TestReactonStore`, reacton mocks, effect trackers, graph assertions, and widget test helpers.

## Installation

```yaml
dev_dependencies:
  reacton_test: ^0.1.0
```

## Quick Start

```dart
import 'package:reacton/reacton.dart';
import 'package:reacton_test/reacton_test.dart';
import 'package:test/test.dart';

final counterReacton = reacton(0, name: 'counter');
final doubleReacton = computed<int>((read) => read(counterReacton) * 2);

void main() {
  test('counter increments', () {
    final store = TestReactonStore();
    store.set(counterReacton, 5);

    expect(store.get(counterReacton), 5);
    expect(store.get(doubleReacton), 10);
  });
}
```

## TestReactonStore

An isolated store with support for overrides. Each test gets a fresh store with no shared state.

```dart
final store = TestReactonStore(
  overrides: [
    ReactonTestOverride(counterReacton, 10),
    AsyncReactonTestOverride.data(weatherReacton, Weather.sunny()),
    AsyncReactonTestOverride.loading(userReacton),
    AsyncReactonTestOverride.error(profileReacton, Exception('not found')),
  ],
);

expect(store.get(counterReacton), 10);
```

## MockReacton

Track read and write operations on reactons.

```dart
final mock = MockReacton(counterReacton, initialValue: 0);
store.forceSet(mock.reacton, 10);

mock.recordWrite(10);
expect(mock.writeCount, 1);
expect(mock.lastValue, 10);
expect(mock.valueHistory, [0, 10]);
```

## EffectTracker

Track effect invocations in tests.

```dart
final tracker = EffectTracker();

final dispose = store.registerEffect(createEffect((read) {
  tracker.record('myEffect');
  final count = read(counterReacton);
  return null;
}));

store.set(counterReacton, 1);

expect(tracker.wasCalled('myEffect'), isTrue);
expect(tracker.callCount('myEffect'), 2); // initial + update
```

## Widget Test Helpers

The `ReactonWidgetTester` extension adds convenience methods for pumping widgets with a Reacton store.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

testWidgets('counter displays value', (tester) async {
  await tester.pumpReacton(
    CounterWidget(),
    overrides: [ReactonTestOverride(counterReacton, 42)],
  );

  expect(find.text('42'), findsOneWidget);

  // Update and pump in one call
  await tester.setReactonAndPump(counterReacton, 99);
  expect(find.text('99'), findsOneWidget);
});
```

### Available Methods

| Method | Description |
|--------|-------------|
| `tester.pumpReacton(widget)` | Pump a widget wrapped in `ReactonScope` with optional overrides |
| `tester.reactonStore` | Get the `ReactonStore` from the widget tree |
| `tester.setReactonAndPump(reacton, value)` | Set a reacton value and pump |
| `tester.updateReactonAndPump(reacton, fn)` | Update a reacton with a function and pump |

## Documentation

See the [Reacton documentation](https://github.com/sitharaj/reacton) for full API reference and guides.

## License

MIT
