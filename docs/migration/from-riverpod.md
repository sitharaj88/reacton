# Migrating from Riverpod

A side-by-side guide for migrating from Riverpod to Reacton. Both libraries share the concept of reactive providers/reactons with automatic dependency tracking, so the migration is mostly mechanical.

## Concept Mapping

| Riverpod | Reacton | Notes |
|----------|---------|-------|
| `StateProvider<T>` | `reacton<T>()` | Simple writable state |
| `StateNotifierProvider` | `reacton()` + `computed()` | No separate notifier class needed |
| `Provider<T>` (read-only) | `computed<T>()` | Computed derived state |
| `FutureProvider<T>` | `asyncReacton<T>()` | Async data fetching |
| `StreamProvider<T>` | `asyncReacton<T>()` | Convert stream to async reacton |
| `Provider.family` | `family<T, Arg>()` | Parameterized providers |
| `ProviderScope` | `ReactonScope` | Root scope for the widget tree |
| `ref.watch(provider)` | `context.watch(reacton)` | Reactive read in widgets |
| `ref.read(provider)` | `context.read(reacton)` | One-time read |
| `ref.listen(provider)` | `ReactonListener` | Side effects on change |
| `ConsumerWidget` | `StatelessWidget` | No special base class needed |
| `ConsumerStatefulWidget` | `StatefulWidget` | No special base class needed |
| `Consumer` | `ReactonConsumer` | Multi-reacton builder |
| `AsyncValue` | `AsyncValue` | Same concept, same API |

## Side-by-Side Examples

### Simple State

**Riverpod:**

```dart
final counterProvider = StateProvider<int>((ref) => 0);

class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}

// Modify:
ref.read(counterProvider.notifier).state++;
```

**Reacton:**

```dart
final counterReacton = reacton(0, name: 'counter');

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterReacton);
    return Text('$count');
  }
}

// Modify:
context.update(counterReacton, (c) => c + 1);
```

::: tip
In Reacton, you do not need `ConsumerWidget` or `ConsumerStatefulWidget`. Use plain `StatelessWidget` or `StatefulWidget` and access reactons through `context.watch()` and `context.read()`.
:::

### Computed / Derived State

**Riverpod:**

```dart
final todosProvider = StateProvider<List<Todo>>((ref) => []);
final filterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todosProvider);
  final filter = ref.watch(filterProvider);
  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.done).toList(),
    TodoFilter.done => todos.where((t) => t.done).toList(),
  };
});
```

**Reacton:**

```dart
final todosReacton = reacton<List<Todo>>([], name: 'todos');
final filterReacton = reacton(TodoFilter.all, name: 'filter');

final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(filterReacton);
  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.done).toList(),
    TodoFilter.done => todos.where((t) => t.done).toList(),
  };
}, name: 'filteredTodos');
```

### Async Data

**Riverpod:**

```dart
final weatherProvider = FutureProvider<Weather>((ref) async {
  final city = ref.watch(cityProvider);
  return await weatherApi.getWeather(city);
});

// In widget:
final weather = ref.watch(weatherProvider);
return weather.when(
  loading: () => CircularProgressIndicator(),
  data: (w) => Text('${w.temp}°C'),
  error: (e, _) => Text('Error: $e'),
);
```

**Reacton:**

```dart
final weatherReacton = asyncReacton<Weather>((read) async {
  final city = read(cityReacton);
  return await weatherApi.getWeather(city);
}, name: 'weather');

// In widget:
final weather = context.watch(weatherReacton);
return weather.when(
  loading: () => CircularProgressIndicator(),
  data: (w) => Text('${w.temp}°C'),
  error: (e, _) => Text('Error: $e'),
);
```

::: tip
Reacton's `AsyncValue` has the same `when()` API as Riverpod's, so your pattern matching code migrates directly.
:::

### Family (Parameterized)

**Riverpod:**

```dart
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await api.getUser(userId);
});

// In widget:
final user = ref.watch(userProvider('user-123'));
```

**Reacton:**

```dart
final userReacton = family<AsyncValue<User>, String>((userId) {
  return asyncReacton((read) => api.getUser(userId), name: 'user_$userId');
});

// In widget:
final user = context.watch(userReacton('user-123'));
```

### Provider Scope / Override

**Riverpod:**

```dart
ProviderScope(
  overrides: [
    counterProvider.overrideWith((ref) => 10),
  ],
  child: MyApp(),
)
```

**Reacton:**

```dart
ReactonScope(
  overrides: [
    ReactonOverride(counterReacton, 10),
  ],
  child: MyApp(),
)
```

### Listening for Side Effects

**Riverpod:**

```dart
ref.listen(errorProvider, (previous, next) {
  if (next != null) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
});
```

**Reacton:**

```dart
ReactonListener(
  reacton: errorReacton,
  listener: (context, error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  },
  child: MyWidget(),
)
```

### StateNotifier -> reacton + computed

**Riverpod:**

```dart
class TodosNotifier extends StateNotifier<List<Todo>> {
  TodosNotifier() : super([]);

  void add(Todo todo) {
    state = [...state, todo];
  }

  void toggle(String id) {
    state = state.map((t) {
      if (t.id == id) return t.copyWith(done: !t.done);
      return t;
    }).toList();
  }
}

final todosProvider = StateNotifierProvider<TodosNotifier, List<Todo>>(
  (ref) => TodosNotifier(),
);
```

**Reacton:**

```dart
final todosReacton = reacton<List<Todo>>([], name: 'todos');

// No class needed. Use context.update() directly:
// Add:
context.update(todosReacton, (todos) => [...todos, newTodo]);

// Toggle:
context.update(todosReacton, (todos) => todos.map((t) {
  if (t.id == id) return t.copyWith(done: !t.done);
  return t;
}).toList());
```

## Testing Migration

**Riverpod:**

```dart
test('counter increments', () {
  final container = ProviderContainer();
  expect(container.read(counterProvider), 0);
  container.read(counterProvider.notifier).state++;
  expect(container.read(counterProvider), 1);
});
```

**Reacton:**

```dart
test('counter increments', () {
  final store = TestReactonStore();
  expect(store.get(counterReacton), 0);
  store.update(counterReacton, (c) => c + 1);
  store.expectReacton(counterReacton, 1);
});
```

## Migration Checklist

- [ ] Replace `ProviderScope` with `ReactonScope`
- [ ] Replace `StateProvider<T>((ref) => value)` with `reacton<T>(value)`
- [ ] Replace `Provider<T>((ref) { ... })` with `computed<T>((read) { ... })`
- [ ] Replace `FutureProvider<T>` with `asyncReacton<T>()`
- [ ] Replace `ref.watch()` with `context.watch()`
- [ ] Replace `ref.read()` with `context.read()`
- [ ] Replace `ConsumerWidget` with `StatelessWidget`
- [ ] Replace `StateNotifier` classes with direct `context.update()` calls
- [ ] Replace `ref.listen()` with `ReactonListener`
- [ ] Replace `ProviderContainer` in tests with `TestReactonStore`

## What's Next

- [From BLoC](./from-bloc) -- Migration guide from BLoC
- [From Provider](./from-provider) -- Migration guide from Provider
