# reacton_lint

Custom lint rules for the Reacton state management library. Detects common mistakes like creating reactons inside `build()`, using `context.read()` in `build()`, and patterns that should use `computed()`.

Built with [custom_lint](https://pub.dev/packages/custom_lint).

## Installation

Add both `reacton_lint` and `custom_lint` to your dev dependencies:

```yaml
dev_dependencies:
  reacton_lint: ^0.1.0
  custom_lint: ^0.6.0
```

Enable `custom_lint` in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

## Rules

### avoid_reacton_in_build

Do not create reactons inside `build()` methods. Reactons should be declared at the top level or as static fields. Creating them in `build()` generates a new reacton on every rebuild, breaking identity and causing memory leaks.

```dart
// BAD
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counterReacton = reacton(0); // LINT: avoid_reacton_in_build
    return Text('${context.watch(counterReacton)}');
  }
}

// GOOD
final counterReacton = reacton(0, name: 'counter');

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('${context.watch(counterReacton)}');
  }
}
```

### avoid_read_in_build

Do not use `context.read()` inside `build()`. Use `context.watch()` instead so the widget rebuilds when the value changes. Reserve `context.read()` for event handlers and callbacks.

```dart
// BAD
Widget build(BuildContext context) {
  final count = context.read(counterReacton); // LINT: avoid_read_in_build
  return Text('$count');
}

// GOOD
Widget build(BuildContext context) {
  final count = context.watch(counterReacton);
  return Text('$count');
}
```

### prefer_computed

When you derive a value from multiple reactons inside `build()`, prefer using a `computed()` reacton. This moves the derivation out of the widget and enables caching at the graph level.

```dart
// LINT suggests using computed
Widget build(BuildContext context) {
  final first = context.watch(firstNameReacton);
  final last = context.watch(lastNameReacton);
  final full = '$first $last'; // prefer_computed
  return Text(full);
}

// BETTER
final fullNameReacton = computed<String>(
  (read) => '${read(firstNameReacton)} ${read(lastNameReacton)}',
);

Widget build(BuildContext context) {
  return Text(context.watch(fullNameReacton));
}
```

## Documentation

See the [Reacton documentation](https://github.com/sitharaj/reacton) for full API reference and guides.

## License

MIT
