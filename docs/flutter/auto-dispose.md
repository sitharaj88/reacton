# Auto-Dispose

The `AutoDisposeManager` handles automatic cleanup of reacton values when no widgets are watching them. This prevents memory leaks from abandoned state while supporting temporary navigation patterns through a grace period.

## How It Works

When the last widget watching a reacton unmounts, the `AutoDisposeManager` starts a **grace period timer**. If no new widget starts watching the same reacton before the timer expires, the reacton is removed from the store.

If a new watcher appears during the grace period (e.g., the user navigates back to a previous screen), the timer is cancelled and the reacton's value is preserved.

```
Widget A watches reacton X
Widget A unmounts
  -> Grace period starts (5 seconds by default)

Case 1: Timer expires
  -> reacton X is removed from the store

Case 2: Widget B watches reacton X before timer expires
  -> Timer is cancelled, reacton X is preserved
```

## AutoDisposeManager

### Constructor

```dart
AutoDisposeManager(
  ReactonStore store, {
  Duration gracePeriod = const Duration(seconds: 5),
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `store` | `ReactonStore` | (required) | The store to manage |
| `gracePeriod` | `Duration` | 5 seconds | How long to wait before disposing an unwatched reacton |

### API

| Method | Signature | Description |
|--------|-----------|-------------|
| `onWatch` | `void onWatch(ReactonRef ref)` | Notify that a watcher started. Increments the watcher count and cancels any pending disposal timer. |
| `onUnwatch` | `void onUnwatch(ReactonRef ref)` | Notify that a watcher stopped. Decrements the watcher count and starts a disposal timer if count reaches zero. |
| `watcherCount` | `int watcherCount(ReactonRef ref)` | Get the current number of active watchers for a reacton. |
| `cancelAll` | `void cancelAll()` | Cancel all pending disposal timers without removing any reactons. |
| `dispose` | `void dispose()` | Cancel all timers and clear all tracking state. |

### Usage

```dart
final store = ReactonStore();
final autoDispose = AutoDisposeManager(store, gracePeriod: const Duration(seconds: 10));

// When a widget starts watching
autoDispose.onWatch(counterReacton.ref);

// When a widget stops watching
autoDispose.onUnwatch(counterReacton.ref);

// Check watcher count
print(autoDispose.watcherCount(counterReacton.ref)); // 0

// Clean up
autoDispose.dispose();
```

## Opting Out with `keepAlive`

If a reacton should never be auto-disposed (e.g., global app state like authentication), set `keepAlive: true` in its options:

```dart
final authTokenReacton = reacton<String?>(
  null,
  name: 'authToken',
  options: const ReactonOptions(keepAlive: true),
);
```

Reactons with `keepAlive: true` remain in the store regardless of watcher count. The `AutoDisposeManager` checks the `keepAlive` flag before scheduling disposal.

## Grace Period

The grace period prevents premature disposal during navigation transitions. For example:

1. User is on Screen A, which watches `userReacton`
2. User navigates to Screen B (Screen A is unmounted)
3. Grace period starts for `userReacton`
4. User navigates back to Screen A within 5 seconds
5. Screen A calls `context.watch(userReacton)` -- grace period is cancelled, value is preserved

Without a grace period, the user would see a loading state every time they navigate back, because the reacton would have been removed and re-initialized.

### Configuring the Grace Period

Set a shorter or longer grace period based on your app's navigation patterns:

```dart
// Shorter grace period for data that's cheap to re-fetch
final autoDispose = AutoDisposeManager(
  store,
  gracePeriod: const Duration(seconds: 2),
);

// Longer grace period for expensive computations
final autoDispose = AutoDisposeManager(
  store,
  gracePeriod: const Duration(seconds: 30),
);
```

## Lifecycle Integration

The auto-dispose system integrates with Flutter's widget lifecycle through the subscription tracking mechanism:

1. `context.watch()` calls `store.subscribe()`, which increments the subscriber count on the `GraphNode`
2. When the `Element` is unmounted, the `_ReactonSubscriptionTracker` disposes all subscriptions
3. Each disposed subscription decrements the subscriber count via `node.removeSubscriber()`
4. When the count reaches zero, the auto-dispose timer starts (if configured)

This means auto-dispose works automatically with `context.watch()`, `ReactonBuilder`, `ReactonConsumer`, and `ReactonSelector` -- no extra code is needed in your widgets.

## Example: Scoped Auto-Dispose

```dart
class FeatureScope extends StatefulWidget {
  final Widget child;
  const FeatureScope({super.key, required this.child});

  @override
  State<FeatureScope> createState() => _FeatureScopeState();
}

class _FeatureScopeState extends State<FeatureScope> {
  late final AutoDisposeManager _autoDispose;

  @override
  void initState() {
    super.initState();
    final store = ReactonScope.read(context);
    _autoDispose = AutoDisposeManager(
      store,
      gracePeriod: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _autoDispose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

## What's Next

- [ReactonScope](/flutter/reacton-scope) -- The widget that provides the store to the tree
- [Context Extensions](/flutter/context-extensions) -- How `context.watch()` sets up subscriptions
- [Core Concepts](/guide/core-concepts) -- Understanding `ReactonOptions` and `keepAlive`
