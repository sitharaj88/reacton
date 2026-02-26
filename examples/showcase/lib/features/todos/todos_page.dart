import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import '../../shared/state.dart';
import 'todo_model.dart';

// ============================================================================
// Todos Page
//
// Demonstrates:
//   - reactonList<T>()       observable list with granular operations
//   - listAdd / listRemoveAt / listUpdate   collection mutations
//   - computed()             filtered views and counts
//   - ReactonConsumer        multi-reacton watching via ref.watch()
//   - lens()                 bidirectional focus into nested state
// ============================================================================

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // --- Stats bar (uses ReactonConsumer to watch multiple reactons) ---
          ReactonConsumer(
            builder: (context, ref) {
              final total = ref.watch(todoCountReacton);
              final completed = ref.watch(completedCountReacton);
              final remaining = ref.watch(remainingCountReacton);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                color: colors.surfaceContainerLow,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'Total', value: '$total', color: colors.primary),
                    _StatChip(label: 'Completed', value: '$completed', color: Colors.green),
                    _StatChip(label: 'Remaining', value: '$remaining', color: Colors.orange),
                  ],
                ),
              );
            },
          ),

          // --- Filter chips ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ReactonBuilder<TodoFilter>(
              reacton: todoFilterReacton,
              builder: (context, currentFilter) {
                return Row(
                  children: [
                    Text('Filter:', style: theme.textTheme.labelLarge),
                    const SizedBox(width: 12),
                    for (final filter in TodoFilter.values) ...[
                      FilterChip(
                        label: Text(filter.name[0].toUpperCase() + filter.name.substring(1)),
                        selected: currentFilter == filter,
                        onSelected: (_) => context.set(todoFilterReacton, filter),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                );
              },
            ),
          ),

          // --- Todo list ---
          Expanded(
            child: ReactonBuilder<List<Todo>>(
              reacton: filteredTodosReacton,
              builder: (context, todos) {
                if (todos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: colors.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No todos match this filter',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: todos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return _TodoTile(todo: todo);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // --- Add new todo ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Todo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'What needs to be done?',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addTodo(context, dialogContext, controller),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _addTodo(context, dialogContext, controller),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTodo(
    BuildContext storeContext,
    BuildContext dialogContext,
    TextEditingController controller,
  ) {
    final title = controller.text.trim();
    if (title.isEmpty) return;

    final store = storeContext.reactonStore;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    store.listAdd(todosReacton, Todo(id: id, title: title));

    Navigator.of(dialogContext).pop();
  }
}

// ---------------------------------------------------------------------------
// Todo tile -- demonstrates lens-style editing via listUpdate
// ---------------------------------------------------------------------------

class _TodoTile extends StatelessWidget {
  final Todo todo;
  const _TodoTile({required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: todo.completed
          ? colors.surfaceContainerLow
          : colors.surfaceContainerHigh,
      child: ListTile(
        leading: Checkbox(
          value: todo.completed,
          onChanged: (value) => _toggleCompleted(context, value ?? false),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? colors.onSurfaceVariant : colors.onSurface,
          ),
        ),
        subtitle: Text(
          'ID: ${todo.id}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.outline,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colors.error),
          onPressed: () => _removeTodo(context),
          tooltip: 'Delete',
        ),
      ),
    );
  }

  /// Uses listUpdate to surgically toggle the completed flag of a single
  /// todo without replacing the entire list.
  void _toggleCompleted(BuildContext context, bool completed) {
    final store = context.reactonStore;
    final todos = store.get(todosReacton);
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      // listUpdate applies a transformation to a single item by index
      store.listUpdate(todosReacton, index, (t) => t.copyWith(completed: completed));
    }
  }

  void _removeTodo(BuildContext context) {
    final store = context.reactonStore;
    final todos = store.get(todosReacton);
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      store.listRemoveAt(todosReacton, index);
    }
  }
}

// ---------------------------------------------------------------------------
// Stat chip
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
