# Migrating from Provider

A side-by-side guide for migrating from the Provider package to Reacton. Provider's `ChangeNotifier` pattern is replaced by immutable reacton values with automatic dependency tracking.

## Concept Mapping

| Provider | Reacton | Notes |
|----------|---------|-------|
| `ChangeNotifierProvider` | `ReactonScope` + `reacton()` | No ChangeNotifier class needed |
| `ChangeNotifier` | `reacton()` + `computed()` | Replace mutable class with immutable values |
| `Provider<T>` (read-only) | `computed<T>()` | Computed derived value |
| `FutureProvider<T>` | `asyncReacton<T>()` | Async data |
| `StreamProvider<T>` | `asyncReacton<T>()` | Async data from streams |
| `Provider.of<T>(context)` | `context.watch(reacton)` | Reactive read |
| `Provider.of<T>(context, listen: false)` | `context.read(reacton)` | One-time read |
| `Consumer<T>` | `ReactonConsumer` | Multi-reacton builder |
| `Selector<T, S>` | `ReactonSelector` or `selector()` | Fine-grained rebuilds |
| `MultiProvider` | `ReactonScope` (single) | One scope for all state |
| `ProxyProvider` | `computed()` | Derived from other values |
| `notifyListeners()` | Automatic | Propagation is automatic on `set()` / `update()` |

## Side-by-Side Examples

### ChangeNotifier -> reacton

**Provider:**

```dart
class CounterModel extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void decrement() {
    _count--;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}

// Setup:
ChangeNotifierProvider(
  create: (_) => CounterModel(),
  child: MyApp(),
)

// Read:
final count = Provider.of<CounterModel>(context).count;
// or:
final count = context.watch<CounterModel>().count;

// Modify:
context.read<CounterModel>().increment();
```

**Reacton:**

```dart
final counterReacton = reacton(0, name: 'counter');

// Setup:
ReactonScope(child: MyApp())

// Read:
final count = context.watch(counterReacton);

// Modify:
context.update(counterReacton, (c) => c + 1);  // increment
context.update(counterReacton, (c) => c - 1);  // decrement
context.set(counterReacton, 0);                 // reset
```

::: tip
With Reacton, you never call `notifyListeners()`. State changes propagate automatically when you call `set()` or `update()`. There is no mutable state and no manual notification.
:::

### Complex ChangeNotifier -> Multiple Reactons

**Provider:**

```dart
class TodoModel extends ChangeNotifier {
  List<Todo> _todos = [];
  TodoFilter _filter = TodoFilter.all;

  List<Todo> get todos => _todos;
  TodoFilter get filter => _filter;

  List<Todo> get filteredTodos {
    return switch (_filter) {
      TodoFilter.all => _todos,
      TodoFilter.active => _todos.where((t) => !t.done).toList(),
      TodoFilter.done => _todos.where((t) => t.done).toList(),
    };
  }

  int get activeCount => _todos.where((t) => !t.done).length;

  void addTodo(Todo todo) {
    _todos = [..._todos, todo];
    notifyListeners();
  }

  void toggleTodo(String id) {
    _todos = _todos.map((t) {
      if (t.id == id) return t.copyWith(done: !t.done);
      return t;
    }).toList();
    notifyListeners();
  }

  void setFilter(TodoFilter filter) {
    _filter = filter;
    notifyListeners();
  }
}
```

**Reacton:**

```dart
// Separate reactons for each piece of state
final todosReacton = reacton<List<Todo>>([], name: 'todos');
final filterReacton = reacton(TodoFilter.all, name: 'filter');

// Computed reactons for derived state
final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(filterReacton);
  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.done).toList(),
    TodoFilter.done => todos.where((t) => t.done).toList(),
  };
}, name: 'filteredTodos');

final activeCountReacton = computed(
  (read) => read(todosReacton).where((t) => !t.done).length,
  name: 'activeCount',
);

// Usage:
// Add:
context.update(todosReacton, (todos) => [...todos, newTodo]);
// Toggle:
context.update(todosReacton, (todos) => todos.map((t) {
  if (t.id == id) return t.copyWith(done: !t.done);
  return t;
}).toList());
// Filter:
context.set(filterReacton, TodoFilter.active);
```

### Provider.of -> context.watch / context.read

**Provider:**

```dart
// Reactive read (rebuilds):
final counter = Provider.of<CounterModel>(context);
// or
final counter = context.watch<CounterModel>();

// One-time read (no rebuild):
final counter = Provider.of<CounterModel>(context, listen: false);
// or
final counter = context.read<CounterModel>();
```

**Reacton:**

```dart
// Reactive read (rebuilds):
final count = context.watch(counterReacton);

// One-time read (no rebuild):
final count = context.read(counterReacton);
```

### Consumer -> ReactonConsumer

**Provider:**

```dart
Consumer<CounterModel>(
  builder: (context, counter, child) {
    return Text('${counter.count}');
  },
)
```

**Reacton:**

```dart
ReactonConsumer(
  builder: (context, ref) {
    final count = ref.watch(counterReacton);
    return Text('$count');
  },
)
```

`ReactonConsumer` is more flexible than Provider's `Consumer` because you can watch any number of reactons in the same builder without nesting multiple `Consumer` widgets.

### Selector -> ReactonSelector

**Provider:**

```dart
Selector<UserModel, String>(
  selector: (_, model) => model.name,
  builder: (_, name, __) => Text(name),
)
```

**Reacton:**

```dart
// Option 1: ReactonSelector widget
ReactonSelector<User, String>(
  reacton: userReacton,
  selector: (user) => user.name,
  builder: (context, name) => Text(name),
)

// Option 2: selector reacton (reusable)
final userNameReacton = selector(userReacton, (user) => user.name);
// Then in widget:
final name = context.watch(userNameReacton);
```

### MultiProvider -> ReactonScope

**Provider:**

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CounterModel()),
    ChangeNotifierProvider(create: (_) => TodoModel()),
    ChangeNotifierProvider(create: (_) => ThemeModel()),
    Provider(create: (_) => ApiService()),
  ],
  child: MyApp(),
)
```

**Reacton:**

```dart
// All reactons are automatically available through one scope
ReactonScope(child: MyApp())
```

In Reacton, there is no registration step. Top-level reacton declarations are lazily initialized when first accessed. A single `ReactonScope` provides access to all of them.

### ProxyProvider -> computed

**Provider:**

```dart
ProxyProvider<ApiService, UserRepository>(
  update: (_, api, __) => UserRepository(api),
)

ProxyProvider2<UserRepository, AuthService, UserBloc>(
  update: (_, userRepo, auth, __) => UserBloc(userRepo, auth),
)
```

**Reacton:**

```dart
// ProxyProvider is simply a computed reacton
final userRepoReacton = computed((read) {
  final api = read(apiServiceReacton);
  return UserRepository(api);
}, name: 'userRepo');

final userBlocReacton = computed((read) {
  final userRepo = read(userRepoReacton);
  final auth = read(authServiceReacton);
  return UserBloc(userRepo, auth);
}, name: 'userBloc');
```

### FutureProvider -> asyncReacton

**Provider:**

```dart
FutureProvider<List<User>>(
  create: (_) => api.fetchUsers(),
  initialData: [],
)
```

**Reacton:**

```dart
final usersReacton = asyncReacton<List<User>>(
  (read) => api.fetchUsers(),
  name: 'users',
);

// In widget:
final users = context.watch(usersReacton);
users.when(
  loading: () => CircularProgressIndicator(),
  data: (list) => UserList(users: list),
  error: (e, _) => Text('Error: $e'),
);
```

## Key Differences

### No Mutable State

Provider relies on mutable `ChangeNotifier` objects with manual `notifyListeners()` calls. Reacton uses immutable values with automatic propagation.

### No Class Hierarchies

Provider requires extending `ChangeNotifier` (or `StateNotifier` with Riverpod). Reacton uses plain top-level declarations. Business logic lives in standalone functions or the widget layer.

### Automatic Dependency Tracking

Provider's `ProxyProvider` requires manually specifying dependencies. Reacton's `computed()` automatically detects which reactons are read and tracks them as dependencies.

### Fine-Grained Reactivity

With Provider, a `ChangeNotifier` notification rebuilds all widgets watching that notifier, regardless of which field changed. With Reacton, each piece of state is a separate reacton, so widgets only rebuild when the specific value they watch changes.

## Testing Migration

**Provider:**

```dart
test('counter increments', () {
  final model = CounterModel();
  expect(model.count, 0);
  model.increment();
  expect(model.count, 1);
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

- [ ] Replace `MultiProvider` / `ChangeNotifierProvider` with `ReactonScope`
- [ ] Replace `ChangeNotifier` classes with `reacton()` declarations
- [ ] Replace derived getters with `computed()` reactons
- [ ] Replace `Provider.of<T>(context)` with `context.watch(reacton)`
- [ ] Replace `Provider.of<T>(context, listen: false)` with `context.read(reacton)`
- [ ] Replace `notifyListeners()` calls -- they are no longer needed
- [ ] Replace `Consumer<T>` with `ReactonConsumer`
- [ ] Replace `Selector<T, S>` with `ReactonSelector` or `selector()`
- [ ] Replace `ProxyProvider` with `computed()`
- [ ] Replace `FutureProvider` with `asyncReacton()`
- [ ] Update tests to use `TestReactonStore` instead of instantiating model classes

## What's Next

- [From Riverpod](./from-riverpod) -- Migration guide from Riverpod
- [From BLoC](./from-bloc) -- Migration guide from BLoC
