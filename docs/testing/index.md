# Testing Overview

Reacton ships with a dedicated testing package (`reacton_test`) that provides isolated test environments, mocks, assertions, and widget test helpers. Every piece of state in Reacton is a plain Dart value, so testing is straightforward and fast.

## Packages

| Package | Purpose |
|---------|---------|
| `reacton_test` | Core testing utilities -- test stores, mocks, assertions, effect tracking, widget helpers |

Add it as a dev dependency:

```yaml
dev_dependencies:
  reacton_test: ^0.1.0
```

Then import everything you need:

```dart
import 'package:reacton_test/reacton_test.dart';
```

## What You Get

- **TestReactonStore** -- An isolated store with override support, backed by in-memory storage. See [Unit Testing](./unit-testing).
- **Widget Pump Helpers** -- Extensions on `WidgetTester` that wrap widgets in a `ReactonScope` automatically. See [Widget Testing](./widget-testing).
- **Graph Assertions** -- Fluent assertion helpers like `expectReacton`, `expectLoading`, `expectData`, `expectEmissions`, and more. See [Assertions](./assertions).
- **EffectTracker and MockReacton** -- Tools for verifying side effects and tracking read/write counts. See [Effect Testing](./effect-testing).

## Quick Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

// Your app's reactons
final counterReacton = reacton(0, name: 'counter');
final doubleReacton = computed((read) => read(counterReacton) * 2);

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  test('counter increments and computed updates', () {
    store.set(counterReacton, 5);

    store.expectReacton(counterReacton, 5);
    store.expectReacton(doubleReacton, 10);
  });

  test('tracks emissions during action', () {
    store.expectEmissions(
      counterReacton,
      () {
        store.set(counterReacton, 1);
        store.set(counterReacton, 2);
        store.set(counterReacton, 3);
      },
      [1, 2, 3],
    );
  });
}
```

## What's Next

- [Unit Testing](./unit-testing) -- TestReactonStore, overrides, and MemoryStorage
- [Widget Testing](./widget-testing) -- Pump helpers and ReactonScope in tests
- [Assertions](./assertions) -- Fluent assertions for reacton values and emissions
- [Effect Testing](./effect-testing) -- EffectTracker and MockReacton
