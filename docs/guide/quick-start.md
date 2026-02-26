# Quick Start

Build a reactive counter app in 5 minutes. This tutorial walks through every line of the Reacton counter example to teach the fundamental concepts.

## The Complete App

Here is the full counter application. The sections below explain each part.

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
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Watch reactons — rebuilds automatically when values change
    final count = context.watch(counterReacton);
    final doubleCount = context.watch(doubleCountReacton);
    final isEven = context.watch(isEvenReacton);

    return Scaffold(
      appBar: AppBar(title: const Text('Reacton Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 16),
            Text('Double: $doubleCount'),
            const SizedBox(height: 8),
            Text(isEven ? 'Even' : 'Odd'),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 5. Update state
          FloatingActionButton(
            heroTag: 'increment',
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

## Step-by-Step Walkthrough

### Step 1: Define Reactons at the Top Level

```dart
final counterReacton = reacton(0, name: 'counter');
```

`reacton<T>(initialValue)` creates a **writable reacton** -- the smallest unit of reactive state. It returns a `WritableReacton<int>` that holds the value `0`.

Reactons are typically declared as top-level variables. They are lightweight identity objects -- the actual values live inside the `ReactonStore`.

The `name` parameter is optional but recommended. It shows up in DevTools and log output.

### Step 2: Derive State with `computed`

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

`computed<T>((read) => ...)` creates a **read-only reacton** whose value is derived from other reactons. The `read` function passed into the callback accesses other reactons and **automatically tracks dependencies**.

When `counterReacton` changes:
- `doubleCountReacton` recomputes because it reads `counterReacton`
- `isEvenReacton` recomputes for the same reason
- Any widgets watching these computed reactons rebuild with the new values

::: tip
Computed reactons are lazy -- they are not evaluated until something reads their value for the first time.
:::

### Step 3: Wrap Your App with ReactonScope

```dart
void main() {
  runApp(ReactonScope(child: const CounterApp()));
}
```

`ReactonScope` is an `InheritedWidget` that creates and provides a `ReactonStore` to the entire widget tree below it. The store is where all reacton values actually live.

You can also pass an existing store if needed:

```dart
final store = ReactonStore();
runApp(ReactonScope(store: store, child: const CounterApp()));
```

### Step 4: Read State with `context.watch()`

```dart
final count = context.watch(counterReacton);
final doubleCount = context.watch(doubleCountReacton);
final isEven = context.watch(isEvenReacton);
```

`context.watch<T>(reacton)` does two things:
1. **Returns** the current value of the reacton from the store
2. **Subscribes** the widget so it rebuilds when the value changes

Each call to `watch()` sets up a subscription that is automatically tracked per `Element`. If the reacton's value changes, only this widget (and other watchers) rebuilds -- not the entire tree.

::: warning
Only use `context.watch()` inside `build()` methods. For one-time reads (e.g., in button callbacks), use `context.read()` instead.
:::

### Step 5: Write State with `context.update()` and `context.set()`

```dart
// Functional update: transform the current value
onPressed: () => context.update(counterReacton, (c) => c + 1),

// Direct set: replace the value entirely
onPressed: () => context.set(counterReacton, 0),
```

**`context.update(reacton, (current) => newValue)`** reads the current value, applies your function, and writes the result. Use this when the new value depends on the old value.

**`context.set(reacton, value)`** directly sets a new value. Use this when you already know the exact value to write.

Both methods trigger the reactive graph engine, which propagates changes to all dependent computed reactons and subscribed widgets.

## What Happens Under the Hood

When you press the increment button:

1. `context.update(counterReacton, (c) => c + 1)` writes `1` to the store
2. The graph engine marks `counterReacton` as `Dirty`
3. **Phase 1 (Mark):** `doubleCountReacton` and `isEvenReacton` are marked `Check`
4. **Phase 2 (Propagate):** Both computed reactons are recomputed in topological order
5. Subscriber callbacks fire, calling `markNeedsBuild()` on the watching `Element`
6. Flutter rebuilds `CounterPage` with the new values

All of this happens synchronously within a single frame.

## What's Next

- [Core Concepts](/guide/core-concepts) -- Deep dive into reactons, computed, selectors, families, effects, and the store
- [Flutter Integration](/flutter/) -- Explore ReactonScope, widgets, and context extensions
- [Context Extensions](/flutter/context-extensions) -- Full API reference for `context.watch()`, `context.read()`, `context.set()`, and `context.update()`
