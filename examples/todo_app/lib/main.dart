import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// ============================================================================
// LEVEL 2 API EXAMPLE: Todo App
//
// Demonstrates intermediate Reacton features:
//   - computed() for derived state
//   - Multiple reactons composing together
//   - ReactonConsumer for multi-atom watching
//   - ReactonSelector for fine-grained rebuilds
//   - ReactonListener for side effects
// ============================================================================

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
    result = result.where((t) => t.title.toLowerCase().contains(query)).toList();
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
                if (t.id == todo.id) return t.copyWith(completed: !t.completed);
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
