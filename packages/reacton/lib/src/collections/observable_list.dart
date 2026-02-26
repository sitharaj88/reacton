import '../core/reacton_base.dart';
import '../core/writable_reacton.dart';
import '../store/store.dart';

/// Change event for observable collections.
sealed class CollectionChange<T> {
  const CollectionChange();
}

class ItemAdded<T> extends CollectionChange<T> {
  final int index;
  final T item;
  const ItemAdded(this.index, this.item);
}

class ItemRemoved<T> extends CollectionChange<T> {
  final int index;
  final T item;
  const ItemRemoved(this.index, this.item);
}

class ItemUpdated<T> extends CollectionChange<T> {
  final int index;
  final T oldItem;
  final T newItem;
  const ItemUpdated(this.index, this.oldItem, this.newItem);
}

class CollectionCleared<T> extends CollectionChange<T> {
  final List<T> previousItems;
  const CollectionCleared(this.previousItems);
}

class ItemsMoved<T> extends CollectionChange<T> {
  final int from;
  final int to;
  const ItemsMoved(this.from, this.to);
}

/// A writable reacton that holds a `List<T>` with granular collection operations.
///
/// Instead of replacing the entire list on every change, you can use
/// targeted operations like add, remove, update, insert that emit
/// fine-grained [CollectionChange] events.
///
/// ```dart
/// final todosReacton = reactonList<Todo>([], name: 'todos');
///
/// store.listAdd(todosReacton, Todo('Buy milk'));
/// store.listRemoveAt(todosReacton, 0);
/// store.listUpdate(todosReacton, 0, (t) => t.copyWith(done: true));
/// ```
class ListReacton<T> extends WritableReacton<List<T>> {
  /// Stream of granular change events.
  final List<void Function(CollectionChange<T>)> _changeListeners = [];

  ListReacton(
    super.initialValue, {
    super.name,
    super.options,
  });

  /// Subscribe to granular collection change events.
  void Function() onChangeEvent(void Function(CollectionChange<T>) listener) {
    _changeListeners.add(listener);
    return () => _changeListeners.remove(listener);
  }

  /// Notify all change listeners.
  void notifyChange(CollectionChange<T> change) {
    for (final listener in List.of(_changeListeners)) {
      listener(change);
    }
  }
}

/// Create a reactive list reacton.
///
/// ```dart
/// final todosReacton = reactonList<Todo>([], name: 'todos');
/// ```
ListReacton<T> reactonList<T>(List<T> initialValue, {String? name, ReactonOptions<List<T>>? options}) {
  return ListReacton<T>(List<T>.of(initialValue), name: name, options: options);
}

/// Extension on [ReactonStore] for list operations.
extension ReactonStoreList on ReactonStore {
  /// Add an item to the end of a list reacton.
  void listAdd<T>(ListReacton<T> listReacton, T item) {
    final current = List<T>.of(get(listReacton));
    current.add(item);
    set(listReacton, current);
    listReacton.notifyChange(ItemAdded(current.length - 1, item));
  }

  /// Insert an item at a specific index.
  void listInsert<T>(ListReacton<T> listReacton, int index, T item) {
    final current = List<T>.of(get(listReacton));
    current.insert(index, item);
    set(listReacton, current);
    listReacton.notifyChange(ItemAdded(index, item));
  }

  /// Remove an item at a specific index.
  T listRemoveAt<T>(ListReacton<T> listReacton, int index) {
    final current = List<T>.of(get(listReacton));
    final removed = current.removeAt(index);
    set(listReacton, current);
    listReacton.notifyChange(ItemRemoved(index, removed));
    return removed;
  }

  /// Remove the first occurrence of an item.
  bool listRemove<T>(ListReacton<T> listReacton, T item) {
    final current = List<T>.of(get(listReacton));
    final index = current.indexOf(item);
    if (index == -1) return false;
    current.removeAt(index);
    set(listReacton, current);
    listReacton.notifyChange(ItemRemoved(index, item));
    return true;
  }

  /// Update an item at a specific index using an updater function.
  void listUpdate<T>(ListReacton<T> listReacton, int index, T Function(T current) updater) {
    final current = List<T>.of(get(listReacton));
    final oldItem = current[index];
    final newItem = updater(oldItem);
    current[index] = newItem;
    set(listReacton, current);
    listReacton.notifyChange(ItemUpdated(index, oldItem, newItem));
  }

  /// Replace an item at a specific index.
  void listSet<T>(ListReacton<T> listReacton, int index, T item) {
    final current = List<T>.of(get(listReacton));
    final oldItem = current[index];
    current[index] = item;
    set(listReacton, current);
    listReacton.notifyChange(ItemUpdated(index, oldItem, item));
  }

  /// Clear all items from the list.
  void listClear<T>(ListReacton<T> listReacton) {
    final current = get(listReacton);
    final previous = List<T>.of(current);
    set(listReacton, <T>[]);
    listReacton.notifyChange(CollectionCleared(previous));
  }

  /// Add all items to the end of the list.
  void listAddAll<T>(ListReacton<T> listReacton, Iterable<T> items) {
    final current = List<T>.of(get(listReacton));
    final startIndex = current.length;
    current.addAll(items);
    set(listReacton, current);
    var i = startIndex;
    for (final item in items) {
      listReacton.notifyChange(ItemAdded(i++, item));
    }
  }

  /// Remove items that match a predicate.
  void listRemoveWhere<T>(ListReacton<T> listReacton, bool Function(T) test) {
    final current = List<T>.of(get(listReacton));
    final removed = <MapEntry<int, T>>[];
    for (var i = current.length - 1; i >= 0; i--) {
      if (test(current[i])) {
        removed.add(MapEntry(i, current[i]));
        current.removeAt(i);
      }
    }
    if (removed.isEmpty) return;
    set(listReacton, current);
    for (final entry in removed.reversed) {
      listReacton.notifyChange(ItemRemoved(entry.key, entry.value));
    }
  }

  /// Sort the list in-place.
  void listSort<T>(ListReacton<T> listReacton, [int Function(T a, T b)? compare]) {
    final current = List<T>.of(get(listReacton));
    current.sort(compare);
    set(listReacton, current);
  }

  /// Get the length of a list reacton.
  int listLength<T>(ListReacton<T> listReacton) {
    return get(listReacton).length;
  }
}
