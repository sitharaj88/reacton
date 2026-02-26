# Todo App

A todo application with CRUD operations, filtering, search, and computed statistics. Demonstrates intermediate Reacton features including multiple composing reactons, `ReactonConsumer`, and `context.update()` for list mutations.

## Full Source

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- Models ---

class Todo {
  final String id;
  final String title;
  final bool completed;

  const Todo({required this.id, required this.title, this.completed = false});

  Todo copyWith({String? title, bool? completed}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

enum TodoFilter { all, active, completed }

// --- Reactons ---

final todosReacton = reacton<List<Todo>>([], name: 'todos');
final filterReacton = reacton(TodoFilter.all, name: 'filter');
final searchQueryReacton = reacton('', name: 'searchQuery');

// --- Computed Reactons ---

final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(filterReacton);
  final query = read(searchQueryReacton).toLowerCase();

  var result = switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.completed).toList(),
    TodoFilter.completed => todos.where((t) => t.completed).toList(),
  };

  if (query.isNotEmpty) {
    result = result
        .where((t) => t.title.toLowerCase().contains(query))
        .toList();
  }

  return result;
}, name: 'filteredTodos');

final statsReacton = computed((read) {
  final todos = read(todosReacton);
  return (
    total: todos.length,
    active: todos.where((t) => !t.completed).length,
    completed: todos.where((t) => t.completed).length,
  );
}, name: 'stats');

// --- App ---

void main() => runApp(ReactonScope(child: const TodoApp()));

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Todo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonConsumer(
      builder: (context, ref) {
        final todos = ref.watch(filteredTodosReacton);
        final stats = ref.watch(statsReacton);
        final filter = ref.watch(filterReacton);

        return Scaffold(
          appBar: AppBar(
            title: Text('Todos (${stats.active} remaining)'),
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search todos...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (q) => context.set(searchQueryReacton, q),
                ),
              ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: TodoFilter.values.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(f.name),
                        selected: filter == f,
                        onSelected: (_) => context.set(filterReacton, f),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Todo list
              Expanded(
                child: todos.isEmpty
                    ? const Center(child: Text('No todos yet'))
                    : ListView.builder(
                        itemCount: todos.length,
                        itemBuilder: (ctx, i) => _TodoTile(todo: todos[i]),
                      ),
              ),

              // Stats bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Total: ${stats.total}'),
                    Text('Active: ${stats.active}'),
                    Text('Done: ${stats.completed}'),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addTodo(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _addTodo(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Todo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter todo title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.update(todosReacton, (todos) => [
                      ...todos,
                      Todo(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: controller.text,
                      ),
                    ]);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  const _TodoTile({required this.todo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        onChanged: (_) {
          context.update(todosReacton, (todos) => todos.map((t) {
                if (t.id == todo.id) {
                  return t.copyWith(completed: !t.completed);
                }
                return t;
              }).toList());
        },
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          context.update(
            todosReacton,
            (todos) => todos.where((t) => t.id != todo.id).toList(),
          );
        },
      ),
    );
  }
}
```

## Walkthrough

### Data Model

The `Todo` class is a plain immutable Dart class with a `copyWith` method for producing modified copies. The `TodoFilter` enum defines three filter states.

### Source Reactons

Three writable reactons hold the application state:

```dart
final todosReacton = reacton<List<Todo>>([], name: 'todos');
final filterReacton = reacton(TodoFilter.all, name: 'filter');
final searchQueryReacton = reacton('', name: 'searchQuery');
```

These are independent pieces of state. The `todosReacton` holds the full list, `filterReacton` holds the current filter, and `searchQueryReacton` holds the search text.

### Computed Reactons

Two computed reactons derive state from the sources:

**`filteredTodosReacton`** -- Combines all three source reactons to produce the filtered, searched list. It reads `todosReacton`, `filterReacton`, and `searchQueryReacton` through the `read` function. Whenever any of these change, the computed value recomputes automatically.

**`statsReacton`** -- Produces a Dart record with `total`, `active`, and `completed` counts. It only depends on `todosReacton`, so it does not recompute when the filter or search changes.

### ReactonConsumer

```dart
ReactonConsumer(
  builder: (context, ref) {
    final todos = ref.watch(filteredTodosReacton);
    final stats = ref.watch(statsReacton);
    final filter = ref.watch(filterReacton);
    // ...
  },
)
```

`ReactonConsumer` provides a `ref` object for watching multiple reactons in a single builder. This is an alternative to using `context.watch()` multiple times. Both approaches work; `ReactonConsumer` is useful when you want to make the watched dependencies explicit in a single scope.

### CRUD Operations

**Create** -- Add a new todo using `context.update()` with a spread operator:

```dart
context.update(todosReacton, (todos) => [
  ...todos,
  Todo(id: '...', title: controller.text),
]);
```

**Read** -- Watch the filtered list to display in the UI.

**Update** -- Toggle completion by mapping over the list:

```dart
context.update(todosReacton, (todos) => todos.map((t) {
  if (t.id == todo.id) return t.copyWith(completed: !t.completed);
  return t;
}).toList());
```

**Delete** -- Filter out the todo:

```dart
context.update(todosReacton,
  (todos) => todos.where((t) => t.id != todo.id).toList(),
);
```

### Filter and Search

Both are simple `context.set()` calls that update the source reacton. The computed `filteredTodosReacton` handles the actual filtering logic.

```dart
onChanged: (q) => context.set(searchQueryReacton, q),
onSelected: (_) => context.set(filterReacton, f),
```

## Key Takeaways

1. **Computed reactons compose naturally** -- `filteredTodosReacton` reads from three sources; `statsReacton` reads from one. Each recomputes only when its specific dependencies change.
2. **Immutable updates with `context.update()`** -- List mutations use functional patterns (spread, map, where) to produce new lists.
3. **ReactonConsumer vs context.watch()** -- Both work. Use whichever style you prefer.
4. **No controller classes** -- All logic is expressed through reacton declarations and widget event handlers.

## What's Next

- [Authentication](./authentication) -- State machine patterns for complex workflows
- [Form Validation](./form-validation) -- Per-field validation with async support
- [Pagination](./pagination) -- Infinite scroll with QueryReacton
