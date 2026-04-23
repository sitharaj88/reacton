# Troubleshooting

Practical fixes for the most common issues when setting up and running Reacton. If something here does not match what you are seeing, open an [issue on GitHub](https://github.com/sitharaj88/reacton/issues).

[[toc]]

## Installation & Setup

### `flutter pub get` fails with dependency conflicts

Make sure your project meets the minimum SDK constraints documented in [Installation](/guide/installation):

- Dart SDK: `>= 3.0.0`
- Flutter: `>= 3.10.0` (for `flutter_reacton`)

If you previously pinned an older version of Reacton, update every Reacton package in `pubspec.yaml` in lock-step:

```yaml
dependencies:
  flutter_reacton: ^0.2.0
  reacton: ^0.2.0

dev_dependencies:
  reacton_test: ^0.2.0
  reacton_generator: ^0.2.0
  reacton_lint: ^0.2.0
```

Then:

```bash
flutter pub get
```

### `No ReactonScope found in widget tree`

You tried to call `context.watch()`, `context.read()`, `context.set()`, or `context.update()` from a widget that has no `ReactonScope` ancestor.

```dart
void main() {
  runApp(
    ReactonScope(           // ← must wrap anything that uses context.watch
      child: const MyApp(),
    ),
  );
}
```

If you have multiple `MaterialApp` instances (e.g. inside a navigator), put `ReactonScope` **above** the top-level `MaterialApp`.

### Build runner can't find `reacton_generator`

For generator-based workflows:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If the command fails:

- Confirm `reacton_generator` and `build_runner` are in `dev_dependencies`.
- Re-run `flutter pub get`.
- Delete the `.dart_tool/build/` cache and run `build_runner clean` followed by the build command.

See [Code Generation](/tooling/code-generation) for the full setup.

## Runtime & Reactivity

### My widget does not rebuild when I update a reacton

Five checks, in order:

1. **Are you using `context.watch()` and not `context.read()`?** `read` deliberately does not subscribe.
2. **Is the watch call inside `build()`?** Subscriptions are tracked via the `BuildContext` — calling `watch()` in `initState` or event handlers does not subscribe.
3. **Did the value actually change (by `==`)?** By default Reacton skips notifications when the new value equals the old one. Set a custom `equals` in `ReactonOptions` if you need stricter comparison, or reach for an [observable collection](/advanced/collections) when mutating the same list.
4. **Are you mutating a list/map in place?** `list.add(...)` does not change the reference — wrap with a new list or use `ObservableList`.
5. **Is your widget inside the `ReactonScope` subtree?** A sibling above the scope will not see updates.

### Infinite rebuild loop

Typical cause: an `effect()` that writes to a reacton it also reads.

```dart
// ❌ infinite loop — effect reads `counter`, then writes to it
createEffect((read) {
  final n = read(counter);
  store.set(counter, n + 1);
});
```

Fix: break the cycle. Read in the effect, write from a separate trigger (a button callback, a timer, another reacton that you read but do not write).

### `StateError: No reacton with ref id …`

Thrown by `ReactonStore.getByRef(refId)` when a ref does not resolve. Common causes:

- You passed an outdated `ReactonRef` from a previous store.
- You called `store.remove(ref)` and then tried to read the same ref.

Solution: always read/write through the reacton object itself (`store.get(myReacton)`) rather than raw refs, unless you are writing low-level tooling.

### `StateError: Module of type X is not installed.`

You called `store.moduleOf<MyModule>()` before calling `store.installModule(MyModule())`. Install the module once, at app start:

```dart
final store = ReactonStore();
store.installModule(AuthModule());
store.installModule(CartModule());
runApp(ReactonScope(store: store, child: const MyApp()));
```

### `StateError: Field "…" not found in form "…"`

The form reacton does not know about that field name. Register every field when building the form, and reference fields by the exact string you registered.

```dart
final loginForm = formReacton(
  fields: {
    'email':    fieldReacton(''),
    'password': fieldReacton(''),
  },
);
```

### Effect cleanup never runs

Return a cleanup function from the effect body:

```dart
createEffect((read) {
  final sub = stream.listen((e) => ...);
  return () => sub.cancel();      // ← this is the cleanup
});
```

Without a returned cleanup, Reacton assumes there is nothing to dispose.

## Async

### Query stays in `AsyncLoading` forever

- Check that your `queryFn` actually completes (`await someFuture` — not bare `Future` construction).
- If you throw from `queryFn`, the value transitions to `AsyncError`, not loading. If you see loading forever, nothing resolved.
- Use [DevTools](/tooling/devtools) → Timeline to confirm the query even started.

### `QueryCancelledException` in production

Queries cancel automatically when their dependent reactons change or the subscriber is disposed. Check `ctx.isCancelled` at yield points:

```dart
reactonQuery<User>(
  queryFn: (ctx) async {
    final partial = await api.fetchProfile();
    ctx.throwIfCancelled();
    final full = await api.fetchOrders(partial.id);
    return User.merge(partial, full);
  },
);
```

Treat `QueryCancelledException` as "nothing to do", never as a bug to report to the user.

### Retries don't happen

`RetryPolicy` only retries when `shouldRetry(error)` returns `true`. The default retries on all errors, but if you set a custom `shouldRetry`, make sure it returns `true` for the errors you actually want to retry.

## Flutter / Widget issues

### Widget throws during hot reload

Reactons declared as top-level `final` variables survive hot reload, but their values in the `ReactonStore` do not — the store is recreated.

If you see stale data after hot reload, restart the app (`R` in the terminal, or the restart button in your IDE). Use a persistence adapter if you need state to survive app restarts.

### `ReactonScope` is not found in tests

Wrap the widget under test:

```dart
testWidgets('shows counter', (tester) async {
  await tester.pumpWidget(
    ReactonScope(
      store: TestReactonStore(),
      child: const MaterialApp(home: CounterPage()),
    ),
  );
});
```

See [Widget Testing](/testing/widget-testing) for more patterns.

## DevTools

### DevTools extension does not appear

1. Add `reacton_devtools` to `dev_dependencies`.
2. Run the app with DevTools enabled (`flutter run` prints a URL; open it, or use the IDE's "Open DevTools" button).
3. Look for the **Reacton** tab next to Performance/Memory.

If the tab still does not show, confirm your Flutter version is `>= 3.10` and your DevTools is `>= 2.28`.

### DevTools shows stale data

Click **Refresh** in the Reacton tab, or disconnect and reconnect DevTools. Some views cache until the next frame.

## CI / deploy

### `vitepress build` fails in GitHub Actions

The [docs deploy workflow](https://github.com/sitharaj88/reacton/blob/main/.github/workflows/deploy-docs.yml) uses Node 20 with an npm cache keyed to `docs/package-lock.json`. If builds fail:

- Re-run the workflow — transient npm registry hiccups are common.
- Bump `vitepress` locally, commit the updated `package-lock.json`.
- Check the `base: '/reacton/'` setting in [`.vitepress/config.ts`](/api/) matches your Pages URL.

### `flutter pub publish --dry-run` reports warnings

The repo ships pre-configured pubspecs for publish. If warnings appear:

- Confirm the package has a short `description` (60–180 chars).
- Confirm `homepage`/`repository` URLs are public and resolve.
- Run `dart analyze` — pub.dev scores drop on analyzer warnings.

## Still stuck?

- Re-read [Common Pitfalls](/guide/pitfalls) — most runtime issues trace to a handful of anti-patterns.
- Check the [Error Reference](/guide/errors) for the exact message you hit.
- Browse the [FAQ](/resources/faq).
- Open an [issue on GitHub](https://github.com/sitharaj88/reacton/issues) with a minimal reproduction.
