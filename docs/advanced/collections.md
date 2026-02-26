# Observable Collections

Reacton provides specialized reactive collection types -- `reactonList<T>()` and `reactonMap<K, V>()` -- that support granular operations and fine-grained change events. Instead of replacing the entire collection on every change, you can use targeted operations like add, remove, and update that emit precise `CollectionChange` or `MapChange` events.

## Reactive Lists

### Creating a List Reacton

```dart
final todosReacton = reactonList<Todo>([], name: 'todos');
```

### Factory Signature

```dart
ListReacton<T> reactonList<T>(
  List<T> initialValue, {
  String? name,
  ReactonOptions<List<T>>? options,
});
```

### List Operations

All list operations are extensions on `ReactonStore`:

```dart
// Add
store.listAdd(todosReacton, Todo('Buy milk'));

// Insert at index
store.listInsert(todosReacton, 0, Todo('First item'));

// Remove by index
final removed = store.listRemoveAt(todosReacton, 0);

// Remove by value
final wasRemoved = store.listRemove(todosReacton, someTodo);

// Update at index with a function
store.listUpdate(todosReacton, 0, (todo) => todo.copyWith(done: true));

// Replace at index
store.listSet(todosReacton, 0, newTodo);

// Add multiple items
store.listAddAll(todosReacton, [todo1, todo2, todo3]);

// Remove items matching a predicate
store.listRemoveWhere(todosReacton, (todo) => todo.done);

// Sort
store.listSort(todosReacton, (a, b) => a.title.compareTo(b.title));

// Clear
store.listClear(todosReacton);

// Get length
final count = store.listLength(todosReacton);
```

### Full API Reference

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `listAdd` | `void listAdd<T>(ListReacton<T>, T)` | `void` | Add an item to the end. |
| `listInsert` | `void listInsert<T>(ListReacton<T>, int, T)` | `void` | Insert at a specific index. |
| `listRemoveAt` | `T listRemoveAt<T>(ListReacton<T>, int)` | `T` | Remove and return item at index. |
| `listRemove` | `bool listRemove<T>(ListReacton<T>, T)` | `bool` | Remove first occurrence. Returns `true` if found. |
| `listUpdate` | `void listUpdate<T>(ListReacton<T>, int, T Function(T))` | `void` | Update item at index with a function. |
| `listSet` | `void listSet<T>(ListReacton<T>, int, T)` | `void` | Replace item at index. |
| `listAddAll` | `void listAddAll<T>(ListReacton<T>, Iterable<T>)` | `void` | Add all items to the end. |
| `listRemoveWhere` | `void listRemoveWhere<T>(ListReacton<T>, bool Function(T))` | `void` | Remove all items matching predicate. |
| `listSort` | `void listSort<T>(ListReacton<T>, [Comparator<T>?])` | `void` | Sort the list in-place. |
| `listClear` | `void listClear<T>(ListReacton<T>)` | `void` | Remove all items. |
| `listLength` | `int listLength<T>(ListReacton<T>)` | `int` | Get the current length. |

## Collection Change Events

Every list operation emits a `CollectionChange<T>` event that describes exactly what changed. Subscribe to these events for fine-grained reactions.

### CollectionChange&lt;T&gt; Sealed Class

| Event | Fields | Emitted By |
|-------|--------|------------|
| `ItemAdded<T>` | `int index`, `T item` | `listAdd`, `listInsert`, `listAddAll` |
| `ItemRemoved<T>` | `int index`, `T item` | `listRemoveAt`, `listRemove`, `listRemoveWhere` |
| `ItemUpdated<T>` | `int index`, `T oldItem`, `T newItem` | `listUpdate`, `listSet` |
| `CollectionCleared<T>` | `List<T> previousItems` | `listClear` |
| `ItemsMoved<T>` | `int from`, `int to` | (reserved for reorder operations) |

### Subscribing to Change Events

```dart
final unsubscribe = todosReacton.onChangeEvent((change) {
  switch (change) {
    case ItemAdded(:final index, :final item):
      print('Added "${item.title}" at index $index');
    case ItemRemoved(:final index, :final item):
      print('Removed "${item.title}" from index $index');
    case ItemUpdated(:final index, :final oldItem, :final newItem):
      print('Updated index $index: "${oldItem.title}" -> "${newItem.title}"');
    case CollectionCleared(:final previousItems):
      print('Cleared ${previousItems.length} items');
    case ItemsMoved(:final from, :final to):
      print('Moved item from $from to $to');
  }
});

// Later: unsubscribe
unsubscribe();
```

## Reactive Maps

### Creating a Map Reacton

```dart
final usersReacton = reactonMap<String, User>({}, name: 'users');
```

### Factory Signature

```dart
MapReacton<K, V> reactonMap<K, V>(
  Map<K, V> initialValue, {
  String? name,
  ReactonOptions<Map<K, V>>? options,
});
```

### Map Operations

```dart
// Put (add or update)
store.mapPut(usersReacton, 'id1', User('Alice'));

// Put all
store.mapPutAll(usersReacton, {'id2': User('Bob'), 'id3': User('Carol')});

// Remove
final removed = store.mapRemove(usersReacton, 'id1');

// Update with a function
store.mapUpdate(usersReacton, 'id2', (user) => user.copyWith(name: 'Bobby'));

// Remove matching entries
store.mapRemoveWhere(usersReacton, (key, user) => user.isInactive);

// Clear
store.mapClear(usersReacton);

// Check existence
final exists = store.mapContainsKey(usersReacton, 'id1');

// Get size
final count = store.mapLength(usersReacton);
```

### Full API Reference

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `mapPut` | `void mapPut<K,V>(MapReacton<K,V>, K, V)` | `void` | Add or update an entry. |
| `mapPutAll` | `void mapPutAll<K,V>(MapReacton<K,V>, Map<K,V>)` | `void` | Add or update multiple entries. |
| `mapRemove` | `V? mapRemove<K,V>(MapReacton<K,V>, K)` | `V?` | Remove entry by key. Returns removed value or `null`. |
| `mapUpdate` | `void mapUpdate<K,V>(MapReacton<K,V>, K, V Function(V))` | `void` | Update value for a key. Throws if key not found. |
| `mapRemoveWhere` | `void mapRemoveWhere<K,V>(MapReacton<K,V>, bool Function(K,V))` | `void` | Remove entries matching predicate. |
| `mapClear` | `void mapClear<K,V>(MapReacton<K,V>)` | `void` | Remove all entries. |
| `mapContainsKey` | `bool mapContainsKey<K,V>(MapReacton<K,V>, K)` | `bool` | Check if key exists. |
| `mapLength` | `int mapLength<K,V>(MapReacton<K,V>)` | `int` | Get the number of entries. |

::: warning
`mapUpdate()` throws a `StateError` if the key does not exist. Use `mapPut()` to add-or-update, or check with `mapContainsKey()` first.
:::

## Map Change Events

### MapChange&lt;K, V&gt; Sealed Class

| Event | Fields | Emitted By |
|-------|--------|------------|
| `MapEntryAdded<K,V>` | `K key`, `V value` | `mapPut` (new key), `mapPutAll` (new keys) |
| `MapEntryRemoved<K,V>` | `K key`, `V value` | `mapRemove`, `mapRemoveWhere` |
| `MapEntryUpdated<K,V>` | `K key`, `V oldValue`, `V newValue` | `mapPut` (existing key), `mapPutAll` (existing keys), `mapUpdate` |
| `MapCleared<K,V>` | `Map<K,V> previousEntries` | `mapClear` |

### Subscribing to Map Changes

```dart
final unsubscribe = usersReacton.onChangeEvent((change) {
  switch (change) {
    case MapEntryAdded(:final key, :final value):
      print('User added: $key -> ${value.name}');
    case MapEntryRemoved(:final key, :final value):
      print('User removed: $key (was ${value.name})');
    case MapEntryUpdated(:final key, :final oldValue, :final newValue):
      print('User updated: $key: ${oldValue.name} -> ${newValue.name}');
    case MapCleared(:final previousEntries):
      print('All ${previousEntries.length} users cleared');
  }
});
```

## Why Not Just Use set()?

You can always replace a list or map entirely with `store.set()`:

```dart
final todos = store.get(todosReacton);
store.set(todosReacton, [...todos, newTodo]);
```

Observable collections offer two advantages:

1. **Granular change events** -- Listeners know exactly what changed (which item was added, removed, or updated) rather than receiving the entire new collection.
2. **Cleaner API** -- Operations like `listUpdate(reacton, index, updater)` are more readable and less error-prone than manual list manipulation.

## Complete Example: Todo List

```dart
// Define
final todosReacton = reactonList<Todo>([], name: 'todos');

final completedCount = computed(
  (read) => read(todosReacton).where((t) => t.done).length,
  name: 'completedCount',
);

final pendingCount = computed(
  (read) => read(todosReacton).where((t) => !t.done).length,
  name: 'pendingCount',
);

// Widget
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final todos = context.watch(todosReacton);
    final completed = context.watch(completedCount);
    final pending = context.watch(pendingCount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Todos ($pending pending, $completed done)'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              context.store.listRemoveWhere(todosReacton, (t) => t.done);
            },
            tooltip: 'Clear completed',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (_, index) {
          final todo = todos[index];
          return CheckboxListTile(
            title: Text(todo.title),
            value: todo.done,
            onChanged: (done) {
              context.store.listUpdate(
                todosReacton,
                index,
                (t) => t.copyWith(done: done ?? false),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.store.listAdd(todosReacton, Todo(title: 'New Todo'));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## What's Next

- [Multi-Isolate](/advanced/isolates) -- Share state across Dart isolates
- [Modules](/advanced/modules) -- Group related reactons into feature modules
- [Middleware](/advanced/middleware) -- Intercept collection changes with middleware
