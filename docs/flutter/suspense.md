# Suspense & Error Boundary

Two widgets that take the pattern matching out of async UI. `ReactonSuspense` unwraps a single async reacton; `ReactonErrorBoundary` groups several under one loading/error surface with a retry affordance.

Both widgets are part of [flutter_reacton](/api/flutter-reacton). They compose naturally with `asyncReacton`, `reactonQuery`, and any other reacton whose value type is `AsyncValue<T>`.

[[toc]]

## When to use which

| Situation | Use |
|-----------|-----|
| A screen reads **one** async reacton and needs to show loading / error / data | `ReactonSuspense<T>` |
| A screen reads **multiple** async reactons and should not render until they all resolve | `ReactonErrorBoundary` |
| You need a **retry** button that invalidates queries | `ReactonErrorBoundary` with `onReset` |
| You want stale-while-revalidate behavior in the UI | `ReactonSuspense(keepPreviousData: true)` (the default) |

## `ReactonSuspense<T>`

Unwraps an `AsyncValue<T>` reacton so your builder receives `T`, not `AsyncValue<T>`.

```dart
final userReacton = asyncReacton<User>((read) => api.fetchUser());

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactonSuspense<User>(
      reacton: userReacton,
      loading: (ctx) => const Center(child: CircularProgressIndicator()),
      error: (ctx, err, stack) => ErrorView(error: err),
      data: (ctx, user) => UserCard(user: user),
    );
  }
}
```

### API

```dart
ReactonSuspense<T>({
  required ReactonBase<AsyncValue<T>> reacton,
  required Widget Function(BuildContext, T) data,
  required Widget Function(BuildContext) loading,
  Widget Function(BuildContext, Object, StackTrace?)? error,
  bool keepPreviousData = true,
})
```

- **`data`** receives the unwrapped value. Called whenever the reacton is in `AsyncData`, or in `AsyncLoading`/`AsyncError` with `previousData` when `keepPreviousData` is `true`.
- **`loading`** called only when the reacton is in `AsyncLoading` and there is no previous data (or `keepPreviousData` is `false`).
- **`error`** optional. When omitted, the default `ErrorWidget` is rendered. If `keepPreviousData` is `true` and previous data exists, the previous data is shown instead of the error.
- **`keepPreviousData`** defaults to `true`. Set to `false` if stale data would be misleading (e.g. for a live-updating counter where an old value is worse than a spinner).

### Behavior at a glance

| Reacton state | `keepPreviousData: true` | `keepPreviousData: false` |
|---------------|--------------------------|---------------------------|
| `AsyncLoading()` (no prev) | `loading` | `loading` |
| `AsyncLoading(prev)` | `data(prev)` | `loading` |
| `AsyncData(v)` | `data(v)` | `data(v)` |
| `AsyncError(err)` (no prev) | `error` or default | `error` or default |
| `AsyncError(err, _, prev)` | `data(prev)` | `error` or default |

## `ReactonErrorBoundary`

Groups multiple async reactons into a single loading/error surface. The `child` only renders once **every** listed reacton has `AsyncData`.

```dart
ReactonErrorBoundary(
  reactons: [userReacton, postsReacton, settingsReacton],
  loading: (ctx) => const Center(child: CircularProgressIndicator()),
  error: (ctx, err, stack, reset) => ErrorView(
    error: err,
    onRetry: reset,
  ),
  onReset: () {
    store.invalidateQuery(userReacton);
    store.invalidateQuery(postsReacton);
    store.invalidateQuery(settingsReacton);
  },
  child: const ProfilePage(), // can safely call context.watch() inside
);
```

### API

```dart
ReactonErrorBoundary({
  required List<ReactonBase<AsyncValue<Object?>>> reactons,
  required Widget Function(BuildContext) loading,
  required Widget child,
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback reset)? error,
  VoidCallback? onReset,
})
```

- **`reactons`** must be non-empty. Mixed value types are fine — they're held as `AsyncValue<Object?>`.
- **`loading`** rendered while any reacton is in `AsyncLoading`.
- **`error`** rendered when any reacton is in `AsyncError`. The `reset` closure invokes `onReset`. When omitted, a default `ErrorWidget` is shown (no retry affordance).
- **`onReset`** the recovery callback. Typical use: invalidate the queries in the boundary; optionally clear caches.
- **`child`** rendered once every reacton has `AsyncData`. Inside `child`, `context.watch(reacton).valueOrNull!` is safe to call.

### Priority rules

- **Error > loading > data.** If any reacton errored, the boundary shows the error fallback even if others are still loading.
- **First-error wins.** If multiple reactons error, the first one in the list surfaces.

## Composing Suspense and ErrorBoundary

Both widgets compose. An `ErrorBoundary` can wrap a subtree that contains individual `Suspense` widgets — each Suspense can handle its local fallback, and the surrounding boundary handles the "one of them failed" case with a shared reset.

```dart
ReactonErrorBoundary(
  reactons: [userReacton, postsReacton],
  loading: (ctx) => const FullScreenSpinner(),
  error: (ctx, err, _, reset) => FullScreenError(onRetry: reset),
  onReset: () {
    store.invalidateQuery(userReacton);
    store.invalidateQuery(postsReacton);
  },
  child: Column(
    children: [
      ReactonSuspense<User>(
        reacton: userReacton,
        loading: (_) => const UserSkeleton(),
        data: (_, u) => UserHeader(u),
      ),
      ReactonSuspense<List<Post>>(
        reacton: postsReacton,
        loading: (_) => const PostsSkeleton(),
        data: (_, posts) => PostList(posts),
      ),
    ],
  ),
);
```

In practice you'll pick one or the other per screen. Suspense handles the single-resource case; ErrorBoundary handles the dashboard-style multi-resource case.

## Tips

- **Skeletons, not spinners.** `loading` is a full `Widget` — prefer skeleton placeholders over blocking spinners when the data shape is known.
- **Don't reach around the widget.** If you find yourself calling `context.watch()` above a `ReactonSuspense` to conditionally render it, that's a sign you want the boundary instead — push the gate upward.
- **Error isolation.** An uncaught error inside a `data` builder is a **build error**, not a reacton error; neither Suspense nor ErrorBoundary will catch it. Use Flutter's standard error handling (`ErrorWidget.builder`) for that.
- **Testing.** Drive the widget with a writable `reacton<AsyncValue<T>>(...)` in tests so you can flip states without real timers. See the Suspense widget tests in the source tree for a worked example.
