# Counter App

A minimal counter application that demonstrates the core Reacton concepts: creating state with `reacton()`, deriving state with `computed()`, reading reactively with `context.watch()`, and modifying state with `context.update()` and `context.set()`.

## Full Source

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// 1. Create reactons (top-level declarations)
final counterReacton = reacton(0, name: 'counter');

// 2. Derived state with computed
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

final isEvenReacton = computed(
  (read) => read(counterReacton) % 2 == 0,
  name: 'isEven',
);

void main() {
  // 3. Wrap app with ReactonScope
  runApp(ReactonScope(child: const CounterApp()));
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Counter',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Watch reactons - rebuilds automatically when values change
    final count = context.watch(counterReacton);
    final doubleCount = context.watch(doubleCountReacton);
    final isEven = context.watch(isEvenReacton);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reacton Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Double: $doubleCount',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isEven ? 'Even' : 'Odd',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isEven ? Colors.green : Colors.orange,
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'increment',
            // 5. Update state
            onPressed: () => context.update(counterReacton, (c) => c + 1),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: () => context.update(counterReacton, (c) => c - 1),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: () => context.set(counterReacton, 0),
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
```

## Walkthrough

### Step 1: Declare Reactons

```dart
final counterReacton = reacton(0, name: 'counter');
```

`reacton()` creates a `WritableReacton<int>` with an initial value of `0`. The `name` parameter is optional but recommended for debugging and DevTools. Reactons are declared at the top level -- they are lightweight identity objects, not instances of state.

### Step 2: Derive State with Computed

```dart
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

final isEvenReacton = computed(
  (read) => read(counterReacton) % 2 == 0,
  name: 'isEven',
);
```

`computed()` creates a `ReadonlyReacton` that automatically recomputes when its dependencies change. The `read` function is used to access other reactons -- dependencies are tracked automatically. There is no need to declare a dependency list.

- `doubleCountReacton` derives its value from `counterReacton` by multiplying by 2
- `isEvenReacton` derives a boolean from `counterReacton`

Both recompute automatically whenever `counterReacton` changes.

### Step 3: Provide the Store

```dart
void main() {
  runApp(ReactonScope(child: const CounterApp()));
}
```

`ReactonScope` creates a `ReactonStore` and makes it available to the entire widget tree. Every descendant can use `context.watch()`, `context.read()`, `context.set()`, and `context.update()`.

### Step 4: Watch Reactons in Widgets

```dart
final count = context.watch(counterReacton);
final doubleCount = context.watch(doubleCountReacton);
final isEven = context.watch(isEvenReacton);
```

`context.watch()` reads the current value and subscribes the widget to changes. When any watched reacton's value changes, the widget rebuilds automatically. No `setState`, no `ChangeNotifier`, no streams.

### Step 5: Modify State

```dart
// Update with a function (increment/decrement)
onPressed: () => context.update(counterReacton, (c) => c + 1),

// Set directly (reset)
onPressed: () => context.set(counterReacton, 0),
```

- `context.update()` reads the current value, applies the function, and writes the result
- `context.set()` writes a new value directly

Both trigger reactive propagation: `counterReacton` changes, which causes `doubleCountReacton` and `isEvenReacton` to recompute, which causes the widget to rebuild with new values.

## Key Takeaways

1. **Reactons are declared at the top level** -- They are identity objects, not state containers. The store holds the actual values.
2. **Computed reactons auto-track dependencies** -- No need to manually specify what they depend on.
3. **Widgets are plain StatelessWidget** -- No special base class needed. Just use `context.watch()`.
4. **State changes propagate automatically** -- Modify a source reacton and everything downstream updates.

## What's Next

- [Todo App](./todo-app) -- CRUD operations with filtering and computed counts
- [Authentication](./authentication) -- State machine patterns
- [Form Validation](./form-validation) -- Complex forms with per-field validation
