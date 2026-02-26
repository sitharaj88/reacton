# Test Package API (`reacton_test`)

Complete API reference for the `reacton_test` package -- testing utilities for the Reacton state management library.

```dart
import 'package:reacton_test/reacton_test.dart';
```

---

## TestReactonStore

An isolated test store with support for overrides. Extends `ReactonStore` and defaults to `MemoryStorage` for the storage adapter.

```dart
TestReactonStore({
  List<TestOverride>? overrides,
  StorageAdapter? storageAdapter, // defaults to MemoryStorage()
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `overrides` | `List<TestOverride>?` | `null` | Initial value overrides applied to the store |
| `storageAdapter` | `StorageAdapter?` | `MemoryStorage()` | Storage backend for persistence testing |

Inherits all methods from `ReactonStore` (`get`, `set`, `update`, `subscribe`, `batch`, `snapshot`, `restore`, `registerEffect`, `forceSet`, `remove`, `dispose`).

---

## Test Overrides

### TestOverride

Abstract base class for test overrides.

| Method | Signature | Description |
|--------|-----------|-------------|
| `apply(store)` | `void` | Apply the override to a `ReactonStore` |

### ReactonTestOverride\<T\>

Override a writable reacton's initial value.

```dart
ReactonTestOverride<T>(ReactonBase<T> reacton, T value)
```

| Member | Type | Description |
|--------|------|-------------|
| `reacton` | `ReactonBase<T>` | The reacton to override |
| `value` | `T` | The override value |

### AsyncReactonTestOverride\<T\>

Override an async reacton to return a synchronous `AsyncValue<T>`.

| Factory Constructor | Signature | Description |
|---------------------|-----------|-------------|
| `.data(reacton, data)` | `AsyncReactonTestOverride<T>` | Override with `AsyncData(data)` |
| `.loading(reacton)` | `AsyncReactonTestOverride<T>` | Override with `AsyncLoading()` |
| `.error(reacton, error, [stackTrace])` | `AsyncReactonTestOverride<T>` | Override with `AsyncError(error, stackTrace)` |

| Member | Type | Description |
|--------|------|-------------|
| `reacton` | `ReactonBase<AsyncValue<T>>` | The async reacton to override |
| `value` | `AsyncValue<T>` | The override async value |

---

## MockReacton\<T\>

A mock wrapper that tracks read/write operations and value history for a reacton.

```dart
MockReacton<T>(ReactonBase<T> reacton, {required T initialValue})
```

| Member | Type | Description |
|--------|------|-------------|
| `reacton` | `ReactonBase<T>` | The underlying reacton |
| `initialValue` | `T` | The initial value |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `readCount` | `int` | Number of times `recordRead()` was called |
| `writeCount` | `int` | Number of times `recordWrite()` was called |
| `valueHistory` | `List<T>` | All values in order (starts with `initialValue`, unmodifiable) |
| `lastValue` | `T` | The most recent value in the history |

### Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `recordRead()` | `void` | Increment the read counter |
| `recordWrite(value)` | `void` | Increment the write counter and add the value to history |
| `reset()` | `void` | Reset all counters and history (resets to `initialValue`) |

---

## EffectTracker

Tracks invocations of effects for testing. Records invocation name, timestamp, and optional metadata.

```dart
EffectTracker()
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `invocations` | `List<EffectInvocation>` | All recorded invocations (unmodifiable) |
| `totalCallCount` | `int` | Total number of invocations across all effects |
| `wasAnyCalled` | `bool` | Whether any effect was called |

### Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `record(name, [metadata])` | `void` | Record an invocation with optional metadata |
| `callCount(name)` | `int` | Number of times a specific effect was called |
| `wasCalled(name)` | `bool` | Whether a specific effect was ever called |
| `invocationsOf(name)` | `List<EffectInvocation>` | All invocations for a specific effect |
| `reset()` | `void` | Clear all recorded invocations |

### EffectInvocation

A single effect invocation record.

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | The name passed to `record()` |
| `timestamp` | `DateTime` | When the invocation was recorded |
| `metadata` | `Map<String, dynamic>?` | Optional metadata |

---

## Graph Assertions

Extension methods on `ReactonStore` for fluent test assertions.

### ReactonStoreTestExtensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `expectReacton<T>(reacton, expected)` | `void` | Assert a reacton has the expected value |
| `expectLoading<T>(reacton)` | `void` | Assert an async reacton is in loading state |
| `expectData<T>(reacton, expected)` | `void` | Assert an async reacton has specific data |
| `expectError<T>(reacton)` | `void` | Assert an async reacton is in error state |
| `collectValues<T>(reacton, action)` | `List<T>` | Collect all values emitted during an action |
| `expectEmissions<T>(reacton, action, expectedValues)` | `void` | Assert specific emissions during an action |
| `expectEmissionCount<T>(reacton, action, expectedCount)` | `void` | Assert the number of emissions during an action |

#### expectReacton

```dart
void expectReacton<T>(ReactonBase<T> reacton, T expected)
```

Reads the reacton's current value and asserts it equals `expected`. Error message includes the reacton ref name.

#### expectLoading

```dart
void expectLoading<T>(ReactonBase<AsyncValue<T>> reacton)
```

Asserts the async value's `isLoading` is true.

#### expectData

```dart
void expectData<T>(ReactonBase<AsyncValue<T>> reacton, T expected)
```

Asserts `hasData` is true and `valueOrNull` equals `expected`.

#### expectError

```dart
void expectError<T>(ReactonBase<AsyncValue<T>> reacton)
```

Asserts the async value's `hasError` is true.

#### collectValues

```dart
List<T> collectValues<T>(ReactonBase<T> reacton, void Function() action)
```

Subscribes to the reacton, runs the action, unsubscribes, and returns all emitted values.

#### expectEmissions

```dart
void expectEmissions<T>(
  ReactonBase<T> reacton,
  void Function() action,
  List<T> expectedValues,
)
```

Collects values during the action and asserts they match `expectedValues` in order.

#### expectEmissionCount

```dart
void expectEmissionCount<T>(
  ReactonBase<T> reacton,
  void Function() action,
  int expectedCount,
)
```

Collects values during the action and asserts the count matches.

---

## Widget Pump Helpers

Extension on `WidgetTester` for testing widgets that use Reacton.

### ReactonWidgetTester

| Method | Signature | Description |
|--------|-----------|-------------|
| `pumpReacton(widget, {overrides, store})` | `Future<void>` | Pump a widget wrapped in `ReactonScope` and `MaterialApp` |
| `reactonStore` | `ReactonStore` | Get the store from the widget tree |
| `setReactonAndPump<T>(reacton, value)` | `Future<void>` | Set a reacton value and pump |
| `updateReactonAndPump<T>(reacton, updater)` | `Future<void>` | Update a reacton value and pump |

#### pumpReacton

```dart
Future<void> pumpReacton(
  Widget widget, {
  List<TestOverride>? overrides,
  ReactonStore? store,
})
```

Wraps the widget in `ReactonScope(store: ..., child: MaterialApp(home: widget))` and pumps. If no store is provided, creates a `TestReactonStore` with the given overrides.

#### reactonStore

```dart
ReactonStore get reactonStore
```

Finds the `ReactonScope` in the widget tree and returns its store.

#### setReactonAndPump

```dart
Future<void> setReactonAndPump<T>(WritableReacton<T> reacton, T value)
```

Calls `store.set(reacton, value)` followed by `pump()`.

#### updateReactonAndPump

```dart
Future<void> updateReactonAndPump<T>(
  WritableReacton<T> reacton,
  T Function(T) updater,
)
```

Calls `store.update(reacton, updater)` followed by `pump()`.

---

## What's Next

- [Core Package API](./reacton) -- Core reactive primitives
- [Flutter Package API](./flutter-reacton) -- Widgets and context extensions
