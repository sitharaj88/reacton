# Context Extensions

The `ReactonBuildContextExtension` on `BuildContext` provides the primary API for using Reacton in Flutter widgets. These are the methods you will use most often.

```dart
import 'package:flutter_reacton/flutter_reacton.dart';
```

## `context.watch<T>()`

Reads a reacton's current value **and subscribes** the widget to future changes. When the reacton's value changes, the widget rebuilds.

```dart
@override
Widget build(BuildContext context) {
  final count = context.watch(counterReacton);   // int
  final name = context.watch(nameReacton);       // String
  return Text('$name: $count');
}
```

### Signature

```dart
T watch<T>(ReactonBase<T> reacton)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | Any reacton (writable, computed, selector, async, etc.) |

**Returns:** The current value of type `T`.

### When to Use

Use `context.watch()` **inside `build()` methods** whenever a widget needs to display or derive its output from a reacton's value.

You can watch multiple reactons in the same `build()`. The widget rebuilds when **any** of them change:

```dart
@override
Widget build(BuildContext context) {
  final firstName = context.watch(firstNameReacton);
  final lastName = context.watch(lastNameReacton);
  return Text('$firstName $lastName');
}
```

## `context.read<T>()`

Reads a reacton's current value **without subscribing**. The widget does **not** rebuild when the value changes.

```dart
onPressed: () {
  final current = context.read(counterReacton);
  print('Current value: $current');
}
```

### Signature

```dart
T read<T>(ReactonBase<T> reacton)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | Any reacton |

**Returns:** The current value of type `T`.

### When to Use

Use `context.read()` in **event handlers**, `onPressed` callbacks, lifecycle methods, and anywhere outside of `build()` where you need a one-time snapshot of the value.

::: danger
**Never use `context.read()` inside `build()`.** The widget will display stale data because it will not rebuild when the value changes. Use `context.watch()` instead.

```dart
// BAD -- widget won't update when counter changes
@override
Widget build(BuildContext context) {
  final count = context.read(counterReacton); // [!code error]
  return Text('$count');
}

// GOOD -- widget rebuilds when counter changes
@override
Widget build(BuildContext context) {
  final count = context.watch(counterReacton); // [!code highlight]
  return Text('$count');
}
```
:::

## `context.set<T>()`

Writes a new value to a writable reacton.

```dart
context.set(counterReacton, 42);
context.set(nameReacton, 'Alice');
```

### Signature

```dart
void set<T>(WritableReacton<T> reacton, T value)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `WritableReacton<T>` | A writable reacton (not computed/readonly) |
| `value` | `T` | The new value |

### When to Use

Use `context.set()` when you already know the exact value to write, independent of the current value:

```dart
FloatingActionButton(
  onPressed: () => context.set(counterReacton, 0), // Reset to 0
  child: const Icon(Icons.refresh),
)
```

## `context.update<T>()`

Updates a writable reacton using a function that receives the current value and returns the new value.

```dart
context.update(counterReacton, (count) => count + 1);
context.update(todosReacton, (todos) => [...todos, newTodo]);
```

### Signature

```dart
void update<T>(WritableReacton<T> reacton, T Function(T current) updater)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `WritableReacton<T>` | A writable reacton |
| `updater` | `T Function(T current)` | A function that receives the current value and returns the new value |

### When to Use

Use `context.update()` when the new value depends on the current value:

```dart
// Increment
context.update(counterReacton, (c) => c + 1);

// Toggle
context.update(isDarkModeReacton, (dark) => !dark);

// Add to list
context.update(itemsReacton, (items) => [...items, newItem]);
```

## `context.reactonStore`

Provides direct access to the `ReactonStore` instance from the nearest `ReactonScope`. Useful for advanced operations like batching, snapshots, or registering effects.

```dart
final store = context.reactonStore;

store.batch(() {
  store.set(firstNameReacton, 'John');
  store.set(lastNameReacton, 'Doe');
});
```

### Signature

```dart
ReactonStore get reactonStore
```

**Returns:** The `ReactonStore` from the nearest `ReactonScope`.

## How Subscription Tracking Works

Understanding the subscription mechanism helps explain why `watch()` and `read()` behave differently.

### The Expando-Based Tracker

Reacton uses Dart's `Expando` class to attach a `_ReactonSubscriptionTracker` to each `Element` (the internal representation of a widget in the widget tree). This avoids requiring a custom base widget class.

When `context.watch(reacton)` is called:

1. The `BuildContext` is cast to its underlying `Element`
2. An `Expando` lookup retrieves (or creates) a `_ReactonSubscriptionTracker` for that element
3. The tracker calls `store.subscribe(reacton, callback)` if not already subscribed
4. The callback calls `element.markNeedsBuild()` to trigger a rebuild
5. The current value is returned from the store

```dart
// Simplified internal flow of context.watch()
T watch<T>(ReactonBase<T> reacton) {
  final store = ReactonScope.of(this);
  final element = this as Element;
  final tracker = _ReactonSubscriptionTracker.of(element);
  tracker.track(reacton, store); // Subscribe if not already
  return store.get(reacton);
}
```

### Subscription Lifecycle

- **Created:** On the first call to `context.watch(reacton)` for a given element
- **Deduplicated:** Subsequent calls to `context.watch()` with the same reacton in the same element are no-ops (already tracked)
- **Cleaned up:** When the element is unmounted, the tracker disposes all subscriptions

::: tip
Because subscriptions are per-element, the same reacton can be watched by many widgets. Each gets its own independent subscription that only affects its own rebuilds.
:::

## API Summary

| Method | Subscribes? | Use In | Purpose |
|--------|:-----------:|--------|---------|
| `context.watch(r)` | Yes | `build()` | Read value, rebuild on change |
| `context.read(r)` | No | Event handlers | One-time read |
| `context.set(r, v)` | No | Event handlers | Direct write |
| `context.update(r, fn)` | No | Event handlers | Functional update |
| `context.reactonStore` | No | Anywhere | Direct store access |

## What's Next

- [Widgets](/flutter/widgets) -- `ReactonBuilder`, `ReactonConsumer`, `ReactonListener`, `ReactonSelector`
- [ReactonScope](/flutter/reacton-scope) -- How the store is provided to the tree
- [Form State](/flutter/forms) -- Reactive form validation with `FieldReacton`
