# reacton

A novel reactive graph engine for Dart. Fine-grained state management with reactons, computed values, effects, async reactons, selectors, families, state branching, time-travel, middleware, and persistence.

## Installation

```yaml
dependencies:
  reacton: ^0.1.0
```

## Quick Start

```dart
import 'package:reacton/reacton.dart';

// Create reactons -- the smallest unit of reactive state
final counterReacton = atom(0, name: 'counter');
final nameReacton = atom('World', name: 'name');

// Derive state with computed reactons (auto-tracked dependencies)
final greetingReacton = computed<String>(
  (read) => 'Hello ${read(nameReacton)}, count is ${read(counterReacton)}',
  name: 'greeting',
);

// Use the store
final store = ReactonStore();
print(store.get(greetingReacton)); // "Hello World, count is 0"

store.set(counterReacton, 5);
print(store.get(greetingReacton)); // "Hello World, count is 5"
```

## Core Concepts

### Reactons

Reactons are the smallest unit of reactive state. They hold a single value and notify subscribers when it changes.

```dart
final counterReacton = atom(0, name: 'counter');
final todosReacton = atom<List<Todo>>([], name: 'todos');
```

### Computed

Computed reactons derive their value from other reactons. Dependencies are automatically tracked -- no manual subscription lists.

```dart
final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(filterReacton);
  return todos.where((t) => t.matches(filter)).toList();
}, name: 'filteredTodos');
```

### Effects

Effects run side effects when their dependencies change. They can return a cleanup function.

```dart
final dispose = store.registerEffect(createEffect((read) {
  final count = read(counterReacton);
  print('Counter changed to: $count');
  return () => print('Cleaning up');
}));
```

### Async Reactons

Async reactons manage asynchronous data with built-in loading, error, and data states.

```dart
final weatherReacton = asyncAtom<Weather>((read) async {
  final city = read(selectedCityReacton);
  return await weatherApi.getWeather(city);
}, name: 'weather', retryPolicy: RetryPolicy(maxAttempts: 3));
```

### Selectors

Selectors watch a sub-value of another reacton, rebuilding only when the selected value changes.

```dart
final userNameReacton = selector(userReacton, (user) => user.name);
```

### Families

Families create parameterized reactons on demand. Each unique argument produces a distinct reacton.

```dart
final userReacton = family<AsyncValue<User>, int>((userId) {
  return asyncAtom((read) => api.getUser(userId), name: 'user_$userId');
});

// Usage: store.get(userReacton(42))
```

### State Branching

Branches create isolated copy-on-write overlays for speculative updates and previews.

```dart
final branch = store.createBranch('dark-theme-preview');
branch.set(themeReacton, ThemeData.dark());

// Preview without affecting main state
print(branch.get(themeReacton)); // dark
print(store.get(themeReacton));  // still light

// Apply when ready
store.mergeBranch(branch);
```

### Time-Travel (Undo/Redo)

Enable history tracking on any writable reacton.

```dart
final history = store.enableHistory(counterReacton, maxHistory: 50);
store.set(counterReacton, 1);
store.set(counterReacton, 2);
store.set(counterReacton, 3);

history.undo(); // counter = 2
history.undo(); // counter = 1
history.redo(); // counter = 2
history.jumpTo(0); // counter = initial value
```

### Middleware

Intercept reads and writes for logging, validation, persistence, and more.

```dart
final store = ReactonStore(
  globalMiddleware: [LoggingMiddleware()],
);
```

### Batch Updates

Group multiple mutations into a single propagation pass.

```dart
store.batch(() {
  store.set(firstNameReacton, 'John');
  store.set(lastNameReacton, 'Doe');
  // fullNameReacton recomputes only once
});
```

## Reactive Graph

Reacton uses a two-phase **mark/propagate** algorithm on a directed acyclic graph (DAG):

1. **Mark** -- When a reacton changes, all downstream computed nodes are marked stale in topological order.
2. **Propagate** -- Stale nodes are recomputed level-by-level. If a recomputed value equals the previous value, propagation stops (glitch-free).

This ensures minimal recomputation and no diamond-problem glitches.

## Documentation

See the [Reacton documentation](https://github.com/sitharaj/reacton) for full API reference and guides.

## License

MIT
