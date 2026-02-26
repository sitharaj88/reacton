# Unit Testing

Reacton provides `TestReactonStore` for isolated, deterministic unit tests. It supports value overrides for both synchronous and async reactons, and uses in-memory storage by default so persistence logic can be tested without touching the filesystem.

## TestReactonStore

`TestReactonStore` extends `ReactonStore` with two additions: it accepts a list of `TestOverride` objects and defaults to `MemoryStorage` for the storage adapter.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  test('reads initial value', () {
    expect(store.get(counterReacton), 0);
  });

  test('sets and reads a value', () {
    store.set(counterReacton, 42);
    expect(store.get(counterReacton), 42);
  });
}
```

### Constructor

```dart
TestReactonStore({
  List<TestOverride>? overrides,
  StorageAdapter? storageAdapter, // defaults to MemoryStorage()
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `overrides` | `List<TestOverride>?` | `null` | Initial value overrides applied to the store |
| `storageAdapter` | `StorageAdapter?` | `MemoryStorage()` | Storage backend for persistence tests |

## Overriding Reacton Values

Use `ReactonTestOverride` for writable reactons and `AsyncReactonTestOverride` for async reactons.

### ReactonTestOverride

Override a writable reacton with a specific initial value:

```dart
final store = TestReactonStore(overrides: [
  ReactonTestOverride(counterReacton, 10),
  ReactonTestOverride(nameReacton, 'Test User'),
]);

expect(store.get(counterReacton), 10);
expect(store.get(nameReacton), 'Test User');
```

### AsyncReactonTestOverride

Override an async reacton with a synchronous state. Three factory constructors are available:

#### `.data` -- Provide resolved data

```dart
final store = TestReactonStore(overrides: [
  AsyncReactonTestOverride.data(weatherReacton, Weather(temp: 72)),
]);

final weather = store.get(weatherReacton);
expect(weather.hasData, isTrue);
expect(weather.valueOrNull?.temp, 72);
```

#### `.loading` -- Start in loading state

```dart
final store = TestReactonStore(overrides: [
  AsyncReactonTestOverride.loading(weatherReacton),
]);

expect(store.get(weatherReacton).isLoading, isTrue);
```

#### `.error` -- Start in error state

```dart
final store = TestReactonStore(overrides: [
  AsyncReactonTestOverride.error(
    weatherReacton,
    Exception('Network error'),
  ),
]);

expect(store.get(weatherReacton).hasError, isTrue);
```

## MemoryStorage for Persistence Testing

`TestReactonStore` uses `MemoryStorage` by default, which is an in-memory implementation of `StorageAdapter`. This lets you test persistence behavior without external dependencies.

```dart
import 'package:reacton_test/reacton_test.dart';

final persistedReacton = reacton(
  'default',
  name: 'persisted',
  options: ReactonOptions(
    persistKey: 'my_key',
    serializer: PrimitiveSerializer<String>(),
  ),
);

void main() {
  test('persists and restores value', () async {
    final storage = MemoryStorage();

    // Write a value to storage
    await storage.write('my_key', '"saved_value"');

    // Create store with that storage
    final store = TestReactonStore(storageAdapter: storage);

    // The persisted reacton should pick up the stored value
    expect(store.get(persistedReacton), 'saved_value');
  });

  test('MemoryStorage basic operations', () async {
    final storage = MemoryStorage();

    expect(storage.read('key'), isNull);
    expect(storage.containsKey('key'), isFalse);

    await storage.write('key', 'value');
    expect(storage.read('key'), 'value');
    expect(storage.containsKey('key'), isTrue);

    await storage.delete('key');
    expect(storage.read('key'), isNull);

    await storage.write('a', '1');
    await storage.write('b', '2');
    await storage.clear();
    expect(storage.containsKey('a'), isFalse);
    expect(storage.containsKey('b'), isFalse);
  });
}
```

## Complete Unit Test Patterns

### Testing Computed Reactons

Computed reactons derive their value from other reactons. Test them by setting the source reactons and checking the computed result:

```dart
final todosReacton = reacton<List<String>>([], name: 'todos');
final todoCountReacton = computed(
  (read) => read(todosReacton).length,
  name: 'todoCount',
);

test('todoCount updates when todos change', () {
  final store = TestReactonStore();

  expect(store.get(todoCountReacton), 0);

  store.set(todosReacton, ['Buy milk', 'Walk dog']);
  expect(store.get(todoCountReacton), 2);

  store.update(todosReacton, (todos) => [...todos, 'Read book']);
  expect(store.get(todoCountReacton), 3);
});
```

### Testing with Subscriptions

```dart
test('subscriber receives updates', () {
  final store = TestReactonStore();
  final values = <int>[];

  final unsub = store.subscribe(counterReacton, (v) => values.add(v));

  store.set(counterReacton, 1);
  store.set(counterReacton, 2);
  store.set(counterReacton, 3);

  expect(values, [1, 2, 3]);

  unsub(); // Clean up
});
```

### Testing Batch Updates

```dart
test('batch updates propagate once', () {
  final store = TestReactonStore();
  var computeCount = 0;

  final firstName = reacton('', name: 'first');
  final lastName = reacton('', name: 'last');
  final fullName = computed((read) {
    computeCount++;
    return '${read(firstName)} ${read(lastName)}'.trim();
  }, name: 'full');

  // Initialize
  store.get(fullName);
  computeCount = 0;

  store.batch(() {
    store.set(firstName, 'John');
    store.set(lastName, 'Doe');
  });

  expect(store.get(fullName), 'John Doe');
});
```

### Testing with Snapshots

```dart
test('snapshot and restore', () {
  final store = TestReactonStore();

  store.set(counterReacton, 42);
  final snap = store.snapshot();

  store.set(counterReacton, 0);
  expect(store.get(counterReacton), 0);

  store.restore(snap);
  expect(store.get(counterReacton), 42);
});
```

::: tip
Always create a fresh `TestReactonStore` in `setUp` to avoid state leaking between tests.
:::

## What's Next

- [Widget Testing](./widget-testing) -- Testing Flutter widgets with Reacton
- [Assertions](./assertions) -- Fluent assertion helpers
- [Effect Testing](./effect-testing) -- Testing side effects
