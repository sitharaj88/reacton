# Lint Rules

The `reacton_lint` package provides custom lint rules that detect common Reacton anti-patterns at analysis time. Rules are powered by `custom_lint` and appear as editor diagnostics in VS Code, IntelliJ, and the Dart analyzer.

## Setup

1. Add `reacton_lint` and `custom_lint` to your `dev_dependencies`:

```yaml
dev_dependencies:
  reacton_lint: ^0.1.0
  custom_lint: ^0.6.0
```

2. Enable the `custom_lint` plugin in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

3. Run `flutter pub get` (or `dart pub get`).

::: tip
The `reacton init` CLI command sets this up automatically.
:::

## Rules

The plugin registers three lint rules:

| Rule | Severity | Auto-fix | Description |
|------|----------|----------|-------------|
| `avoid_reacton_in_build` | Error | No | Do not create reactons inside `build()` methods |
| `avoid_read_in_build` | Warning | No | Do not use `context.read()` directly inside `build()` |
| `prefer_computed` | Info | No | Prefer `computed()` when a build method watches 3+ reactons |

---

## avoid_reacton_in_build

**Severity:** Error

Reacton declarations (`reacton()`, `computed()`, `asyncReacton()`, `family()`) must not appear inside `build()` methods. Every call to a factory function creates a new reacton identity, so placing it inside `build()` creates a fresh reacton on every rebuild -- losing all state and breaking the reactive graph.

### Bad

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ERROR: avoid_reacton_in_build
    final counter = reacton(0, name: 'counter');
    return Text('${context.watch(counter)}');
  }
}
```

### Good

```dart
// Declare at top level
final counterReacton = reacton(0, name: 'counter');

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('${context.watch(counterReacton)}');
  }
}
```

### Detection

The rule visits `build()` methods in class declarations and checks for calls to `reacton()`, `computed()`, `asyncReacton()`, or `family()` anywhere in the method body.

---

## avoid_read_in_build

**Severity:** Warning

Using `context.read()` directly inside a `build()` method is usually a mistake. `context.read()` returns the current value without subscribing, so the widget will not rebuild when the value changes. In most cases, `context.watch()` was intended.

::: warning
This rule only flags `context.read()` calls that are **not** inside a callback (e.g., `onPressed`, `onTap`). Using `context.read()` inside callbacks is correct and expected.
:::

### Bad

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // WARNING: avoid_read_in_build
    final count = context.read(counterReacton);
    return Text('$count'); // Will NOT update when counter changes
  }
}
```

### Good

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use watch() to rebuild on changes
    final count = context.watch(counterReacton);
    return ElevatedButton(
      // read() is fine inside callbacks
      onPressed: () => context.set(counterReacton, context.read(counterReacton) + 1),
      child: Text('$count'),
    );
  }
}
```

### Detection

The rule visits `build()` methods and looks for `context.read()` invocations. It distinguishes between direct calls in the build body (flagged) and calls nested inside function expressions like `onPressed` callbacks (allowed).

---

## prefer_computed

**Severity:** Info

When a single `build()` method calls `context.watch()` three or more times, consider extracting the derived value into a `computed()` reacton. This improves:

- **Reusability** -- The derived value can be shared across widgets
- **Testability** -- The computation can be unit-tested independently
- **Caching** -- Computed reactons cache their value and only recompute when dependencies change
- **Performance** -- A single computed subscription instead of multiple widget-level subscriptions

### Triggers Lint

```dart
class DashboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // INFO: prefer_computed -- 3+ watches in build
    final todos = context.watch(todosReacton);
    final filter = context.watch(filterReacton);
    final searchQuery = context.watch(searchQueryReacton);

    final filtered = todos
      .where((t) => t.matches(filter))
      .where((t) => t.title.contains(searchQuery))
      .toList();

    return ListView(children: filtered.map(_buildTile).toList());
  }
}
```

### Refactored

```dart
// Extract to a computed reacton
final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(filterReacton);
  final query = read(searchQueryReacton);
  return todos
    .where((t) => t.matches(filter))
    .where((t) => t.title.contains(query))
    .toList();
}, name: 'filteredTodos');

class DashboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Single watch -- clean and efficient
    final filtered = context.watch(filteredTodosReacton);
    return ListView(children: filtered.map(_buildTile).toList());
  }
}
```

### Detection

The rule counts `context.watch()` calls in `build()` methods. If the count reaches 3 or more, the diagnostic is reported on the method declaration.

---

## Disabling Rules

To disable a specific rule for a single line, use the standard `ignore` comment:

```dart
// ignore: avoid_reacton_in_build
final temp = reacton(0);
```

To disable a rule for an entire file:

```dart
// ignore_for_file: prefer_computed
```

::: danger
Disabling `avoid_reacton_in_build` is almost never appropriate. Creating reactons inside `build()` is a fundamental correctness issue, not a style preference.
:::

## What's Next

- [DevTools](./devtools) -- Runtime debugging and graph visualization
- [VS Code Extension](./vscode-extension) -- IDE-level diagnostics (includes additional rules)
- [Code Generation](./code-generation) -- Static analysis with build_runner
