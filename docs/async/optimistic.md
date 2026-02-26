# Optimistic Updates

Optimistic updates apply state changes instantly, before the server confirms them. If the mutation succeeds, the UI already shows the correct state. If it fails, the previous state is automatically restored (rolled back). This pattern makes your app feel instant, even over slow networks.

## How It Works

```
User taps "Like"
      │
      ├──> Immediately: set likes = likes + 1  (optimistic)
      │
      └──> In background: POST /api/like
                │
                ├── Success: set likes = server value (confirm)
                │
                └── Failure: set likes = original value (rollback)
                             call onRollback callback
```

## store.optimistic()

The `optimistic()` extension method on `ReactonStore` handles the full optimistic update lifecycle.

```dart
await store.optimistic(
  reacton: todosReacton,
  optimisticValue: [...currentTodos, newTodo],
  mutation: () => api.addTodo(newTodo),
  onRollback: (error) => showSnackBar('Failed to add todo: $error'),
);
```

### Signature

```dart
Future<T> optimistic<T>({
  required WritableReacton<T> reacton,
  required T optimisticValue,
  required Future<T> Function() mutation,
  void Function(Object error)? onRollback,
});
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `WritableReacton<T>` | The writable reacton to update. |
| `optimisticValue` | `T` | The value to set immediately, before the mutation completes. |
| `mutation` | `Future<T> Function()` | The async operation (API call). Should return the server-confirmed value. |
| `onRollback` | `void Function(Object)?` | Optional callback invoked when the mutation fails and the value is rolled back. |

### Return Value

- On **success**: Returns the value returned by `mutation()` (the server-confirmed value).
- On **failure**: Rolls back to the previous value, calls `onRollback`, and **rethrows** the error.

## OptimisticUpdate Class

For more control, you can use the `OptimisticUpdate<T>` class directly:

```dart
final updater = OptimisticUpdate<List<Todo>>(store, todosReacton);

try {
  final result = await updater.apply(
    optimisticValue: [...currentTodos, newTodo],
    mutation: () => api.addTodo(newTodo),
    onRollback: (error) => print('Rolled back: $error'),
  );
  print('Server confirmed: $result');
} catch (e) {
  // Error is rethrown after rollback
  print('Mutation failed: $e');
}
```

## Examples

### Adding an Item to a List

```dart
final todosReacton = reacton<List<Todo>>([], name: 'todos');

Future<void> addTodo(ReactonStore store, Todo newTodo) async {
  final currentTodos = store.get(todosReacton);

  await store.optimistic(
    reacton: todosReacton,
    optimisticValue: [...currentTodos, newTodo],
    mutation: () async {
      final created = await api.createTodo(newTodo);
      // Return the full list with the server-assigned ID
      return [...currentTodos, created];
    },
    onRollback: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add todo')),
      );
    },
  );
}
```

### Toggling a Boolean

```dart
final likedReacton = reacton(false, name: 'liked');

Future<void> toggleLike(ReactonStore store, String postId) async {
  final currentlyLiked = store.get(likedReacton);

  await store.optimistic(
    reacton: likedReacton,
    optimisticValue: !currentlyLiked,
    mutation: () async {
      await api.setLike(postId, !currentlyLiked);
      return !currentlyLiked;
    },
    onRollback: (_) {
      // The value is already rolled back; just notify the user
      print('Like toggle failed, reverted');
    },
  );
}
```

### Updating a Counter

```dart
final likeCountReacton = reacton(42, name: 'likeCount');

Future<void> incrementLikes(ReactonStore store) async {
  final current = store.get(likeCountReacton);

  await store.optimistic(
    reacton: likeCountReacton,
    optimisticValue: current + 1,
    mutation: () async {
      final response = await api.like();
      return response.newLikeCount; // server-authoritative count
    },
  );
}
```

### In a Widget

```dart
class TodoListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final todos = context.watch(todosReacton);

    return Scaffold(
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (_, i) => TodoTile(todos[i]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTodo = Todo(title: 'New Task', done: false);
          try {
            await context.store.optimistic(
              reacton: todosReacton,
              optimisticValue: [...todos, newTodo],
              mutation: () async {
                final created = await api.createTodo(newTodo);
                return [...todos, created];
              },
              onRollback: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $error')),
                );
              },
            );
          } catch (_) {
            // Already handled by onRollback
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

::: tip
Always wrap `store.optimistic()` in a try-catch if you call it directly, because the error is rethrown after rollback. If you only need the side effect (snackbar, log), handle it in `onRollback`.
:::

::: warning
Optimistic updates work with `WritableReacton<T>` only. If your async state is managed by an `asyncReacton` or `reactonQuery`, use `setQueryData()` for manual cache updates instead.
:::

## What's Next

- [Async Reacton](/async/async-reacton) -- Core async data fetching with dependency tracking
- [Query Reacton](/async/query-reacton) -- Smart caching with `setQueryData()` for manual updates
- [Middleware](/advanced/middleware) -- Intercept writes for logging, validation, and more
