# Common Pitfalls

Most Reacton bugs trace back to the same handful of mistakes. This page catalogs each, shows the symptom, and gives a one-line fix.

[[toc]]

## 1. Creating reactons inside `build()`

**Symptom.** Your app rebuilds frenetically, DevTools shows a new reacton every frame, memory climbs.

**Anti-pattern.**

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = reacton(0); // ← created every build
    final count = context.watch(counter);
    return Text('$count');
  }
}
```

**Fix.** Declare reactons as top-level `final` variables, or inside a module.

```dart
final counter = reacton(0, name: 'counter');

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counter);
    return Text('$count');
  }
}
```

The `avoid_reacton_in_build` [lint rule](/tooling/lint-rules) catches this statically.

## 2. Calling `context.read()` inside `build()`

**Symptom.** Widget never rebuilds when the underlying reacton changes.

**Anti-pattern.**

```dart
@override
Widget build(BuildContext context) {
  final count = context.read(counter); // ← no subscription created
  return Text('$count');
}
```

**Fix.** Use `context.watch()` in `build()`. Keep `context.read()` for event handlers where you need a one-time read.

```dart
@override
Widget build(BuildContext context) {
  final count = context.watch(counter);          // subscribes + rebuilds
  return ElevatedButton(
    onPressed: () {
      final current = context.read(counter);     // one-off read, no subscription
      logger.info('current: $current');
    },
    child: Text('$count'),
  );
}
```

The `avoid_read_in_build` lint rule catches this.

## 3. Mutating a list/map in place

**Symptom.** You called `list.add(...)` and widgets didn't rebuild.

**Anti-pattern.**

```dart
final todos = reacton<List<Todo>>([], name: 'todos');

void add(Todo t) {
  final list = store.get(todos);
  list.add(t);                     // ← same list reference
  store.set(todos, list);          // set with the same ref; equality returns true
}
```

**Fix.** Either return a new list…

```dart
store.update(todos, (list) => [...list, t]);
```

…or use [observable collections](/advanced/collections), which emit granular events on mutation:

```dart
final todos = reactonList<Todo>([], name: 'todos');
store.mutateList(todos, (list) => list.add(t));
```

## 4. Using `computed()` where `selector()` would do

**Symptom.** A widget rebuilds on every state change, even ones that do not affect the value you care about.

**Anti-pattern.**

```dart
final userName = computed((read) => read(userReacton).name);
```

This works, but if `userReacton` has many fields and most changes do not affect `name`, every widget reading `userName` still re-runs the compute.

**Fix.** `selector()` applies equality on the selected sub-value, so it only propagates when the slice actually changes.

```dart
final userName = selector(userReacton, (u) => u.name);
```

Rule of thumb: pure projection of a sub-value → `selector`. Derivation that combines multiple reactons → `computed`.

## 5. Effects that write to their own dependencies

**Symptom.** Infinite loop, stack overflow, app freezes.

**Anti-pattern.**

```dart
createEffect((read) {
  final count = read(counter);
  store.set(counter, count + 1); // ← effect writes to what it reads
});
```

**Fix.** Break the cycle. Derive via `computed()` if you just need a value, or trigger the write from a user event / timer / another reacton that you do not read in the effect.

## 6. Forgetting the cleanup from effects

**Symptom.** Subscriptions, timers, stream listeners leak.

**Anti-pattern.**

```dart
createEffect((read) {
  final sub = stream.listen((e) => ...);
  // ← nothing returned
});
```

**Fix.** Return a cleanup callback.

```dart
createEffect((read) {
  final sub = stream.listen((e) => ...);
  return () => sub.cancel();
});
```

## 7. Wrapping every reacton in async

**Symptom.** Loading spinners for synchronous data. Complicated pattern matching for values that cannot fail.

**Anti-pattern.**

```dart
final feature = asyncReacton((read) async => Feature.defaults());
```

**Fix.** `reacton()` and `computed()` are synchronous and free. Use `AsyncValue` only when the value truly comes from a Future/Stream — network, disk, cross-isolate.

## 8. Nesting `ReactonScope` unnecessarily

**Symptom.** Child scope loses access to parent reactons, or worse — the same reacton is read from two different stores.

**Rule.**

- **Top-level app state** lives in one `ReactonScope` at the root.
- **Feature-scoped, disposable state** (e.g. a wizard flow, a modal) is a good case for a nested `ReactonScope` with its own store.

Nesting works, but nest with intent. If in doubt, have one scope.

## 9. Reading reactons in `initState` / `dispose`

**Symptom.** `State` lifecycle events run once; subsequent changes never reach your code.

**Fix.** Use `context.read()` inside `initState` / `didChangeDependencies` for a one-time read, and a `ReactonListener` widget for ongoing side-effect callbacks:

```dart
ReactonListener(
  reacton: errorReacton,
  listener: (ctx, err) {
    if (err != null) showSnack(ctx, err);
  },
  child: const MyView(),
);
```

## 10. Persisting non-serializable state

**Symptom.** `PersistenceMiddleware` throws on app start, or restored values are junk.

**Fix.** Every persisted reacton needs a `Serializer`. Use `PrimitiveSerializer` for primitives, `JsonSerializer` for Dart classes with `toJson`/`fromJson`, and hand-roll a serializer for anything exotic. Non-serializable values (closures, `BuildContext`, futures) must never be persisted.

See [Persistence](/advanced/persistence) for the full contract.

## 11. Testing without `TestReactonStore`

**Symptom.** Tests pass locally but fail in CI because of stale global state.

**Fix.** Every test gets its own `TestReactonStore`, with overrides for dependencies:

```dart
test('doubled reflects counter', () {
  final store = TestReactonStore(overrides: [
    ReactonTestOverride(counter, 5),
  ]);

  expectReacton(store, doubled).toHaveValue(10);
});
```

See [Unit Testing](/testing/unit-testing).

## 12. Using `context.set()` inside a computed

**Symptom.** Works in dev, crashes or produces glitches in release.

**Anti-pattern.**

```dart
final total = computed((read) {
  final items = read(cart);
  store.set(totalCache, items.length); // ← side effect inside compute
  return items.length;
});
```

**Fix.** `computed` must be pure. Move the side effect into an `effect()`, or remove the cache (Reacton's graph engine already memoizes computed values).

## Lint rules that catch most of these

Enable `reacton_lint` in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - avoid_reacton_in_build
    - avoid_read_in_build
    - prefer_computed
```

See [Lint Rules](/tooling/lint-rules) for the full list, including auto-fixes.
