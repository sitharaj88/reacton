# ReactonScope

`ReactonScope` is an `InheritedWidget` that provides a `ReactonStore` to the widget tree. It is the entry point for all Flutter integration with Reacton.

## Basic Usage

Wrap your app (or any subtree) with `ReactonScope` to make reactons available via `context.watch()`, `context.read()`, and other extensions:

```dart
void main() {
  runApp(ReactonScope(child: const MyApp()));
}
```

A new `ReactonStore` is created automatically. If you need to provide your own store instance (for example, one pre-configured with middleware or a storage adapter), pass it explicitly:

```dart
void main() {
  final store = ReactonStore(
    storageAdapter: SharedPrefsAdapter(),
    globalMiddleware: [LoggingMiddleware()],
  );

  runApp(ReactonScope(store: store, child: const MyApp()));
}
```

## Constructor

```dart
ReactonScope({
  Key? key,
  ReactonStore? store,
  List<ReactonOverride>? overrides,
  required Widget child,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `store` | `ReactonStore?` | An existing store to provide. If `null`, a new one is created. |
| `overrides` | `List<ReactonOverride>?` | Override reacton values (primarily for testing). |
| `child` | `Widget` | The widget tree that gains access to the store. |

## Accessing the Store

### `ReactonScope.of(context)`

Returns the `ReactonStore` from the nearest `ReactonScope` ancestor **and** creates a dependency on it. This means the widget will rebuild if the `ReactonScope` is replaced with a different store.

```dart
final store = ReactonScope.of(context);
final count = store.get(counterReacton);
```

::: tip
In practice, you rarely call `ReactonScope.of()` directly. The `context.watch()` and `context.read()` extensions use it internally.
:::

### `ReactonScope.read(context)`

Returns the `ReactonStore` **without** creating a dependency. The widget will not rebuild if the scope changes. This is used internally by `context.set()` and `context.update()` since writes do not need to track scope changes.

```dart
final store = ReactonScope.read(context);
store.set(counterReacton, 42);
```

### `ReactonScope.maybeOf(context)`

Returns the `ReactonStore` if a `ReactonScope` exists, or `null` if none is found. Useful for optional scope detection:

```dart
final store = ReactonScope.maybeOf(context);
if (store != null) {
  // ReactonScope is available
}
```

## Nested Scopes

You can nest `ReactonScope` widgets to create isolated state regions. Each scope creates its own store, so reactons in a child scope are independent of the parent:

```dart
ReactonScope(
  child: Column(
    children: [
      // This widget uses the outer store
      Text('${context.watch(counterReacton)}'),

      // This subtree has its own isolated store
      ReactonScope(
        child: IsolatedFeatureWidget(),
      ),
    ],
  ),
)
```

::: warning
A reacton watched through a child scope will hold a separate value from the same reacton watched through the parent scope. They are distinct stores with distinct values.
:::

## Testing Overrides

`ReactonOverride` lets you pre-set reacton values for testing. This avoids needing to replicate real initialization logic in tests:

```dart
testWidgets('shows count', (tester) async {
  await tester.pumpWidget(
    ReactonScope(
      overrides: [
        ReactonOverride(counterReacton, 42),
        ReactonOverride(nameReacton, 'Test User'),
      ],
      child: const MaterialApp(home: CounterPage()),
    ),
  );

  expect(find.text('42'), findsOneWidget);
});
```

### ReactonOverride

```dart
class ReactonOverride<T> {
  final ReactonBase<T> reacton;
  final T value;

  const ReactonOverride(this.reacton, this.value);
}
```

Overrides are applied via `store.forceSet()`, which sets the value without triggering middleware. This ensures deterministic test setup.

## How It Works

`ReactonScope` extends `InheritedWidget`. The `updateShouldNotify` method returns `true` only when the store instance itself changes (i.e., a different `ReactonStore` object is provided). In practice, this almost never happens -- the store is created once and remains stable for the lifetime of the scope.

The actual widget rebuilds are driven by reacton subscriptions (via `store.subscribe()`), not by the `InheritedWidget` mechanism. This is what makes Reacton fine-grained: widgets rebuild only when their specific reactons change, not when "any state" changes.

## What's Next

- [Context Extensions](/flutter/context-extensions) -- `context.watch()`, `context.read()`, `context.set()`, `context.update()`
- [Widgets](/flutter/widgets) -- `ReactonBuilder`, `ReactonConsumer`, `ReactonListener`, `ReactonSelector`
- [Core Concepts](/guide/core-concepts) -- Understand the `ReactonStore` API in depth
