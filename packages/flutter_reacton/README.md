# flutter_reacton

Flutter widgets and bindings for the Reacton state management library. Provides `ReactonScope`, `context.watch()`, `ReactonBuilder`, `ReactonConsumer`, `ReactonListener`, `ReactonSelector`, and automatic disposal.

## Installation

```yaml
dependencies:
  flutter_reacton: ^0.1.0
```

`flutter_reacton` re-exports `package:reacton/reacton.dart`, so you only need this single dependency.

## Quick Start

```dart
import 'package:flutter_reacton/flutter_reacton.dart';

// 1. Define reactons at the top level
final counterReacton = atom(0, name: 'counter');

// 2. Wrap your app in ReactonScope
void main() => runApp(ReactonScope(child: MyApp()));

// 3. Use in widgets
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterReacton);

    return Scaffold(
      body: Center(child: Text('Count: $count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.update(counterReacton, (n) => n + 1),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## Widgets

### ReactonScope

Provides the `ReactonStore` to all descendants. Must wrap your app or the subtree that uses Reacton.

```dart
ReactonScope(
  store: ReactonStore(), // optional, creates one if omitted
  child: MyApp(),
)
```

### context.watch()

Reads a reacton and subscribes the widget to changes. The widget rebuilds when the reacton value changes.

```dart
final count = context.watch(counterReacton);
```

### context.read()

Reads a reacton without subscribing. Use this in event handlers, **not** in `build()`.

```dart
onPressed: () {
  final current = context.read(counterReacton);
  context.set(counterReacton, current + 1);
}
```

### context.set()

Sets a writable reacton's value.

```dart
context.set(counterReacton, 42);
```

### context.update()

Updates a writable reacton using a function.

```dart
context.update(counterReacton, (count) => count + 1);
```

### ReactonBuilder

A widget that rebuilds when a specific reacton changes. Useful when you need a builder pattern instead of `context.watch()`.

```dart
ReactonBuilder<int>(
  atom: counterReacton,
  builder: (context, count) => Text('$count'),
)
```

### ReactonConsumer

Combines watching a reacton with access to both the value and the store for dispatching updates.

```dart
ReactonConsumer<int>(
  atom: counterReacton,
  builder: (context, count, store) {
    return ElevatedButton(
      onPressed: () => store.set(counterReacton, count + 1),
      child: Text('$count'),
    );
  },
)
```

### ReactonListener

Listens to a reacton and runs a callback on change without rebuilding. Useful for navigation, snackbars, and other side effects.

```dart
ReactonListener<String>(
  atom: errorReacton,
  listener: (context, error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
  child: MyPage(),
)
```

### ReactonSelector

Watches a sub-value of a reacton and only rebuilds when the selected value changes.

```dart
ReactonSelector<User, String>(
  atom: userReacton,
  selector: (user) => user.name,
  builder: (context, name) => Text(name),
)
```

## Auto-Dispose

Reacton automatically cleans up reacton subscriptions when widgets are removed from the tree. No manual `dispose()` calls are needed for `context.watch()` subscriptions.

## Documentation

See the [Reacton documentation](https://github.com/sitharaj/reacton) for full API reference and guides.

## License

MIT
