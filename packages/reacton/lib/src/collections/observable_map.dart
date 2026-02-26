import '../core/reacton_base.dart';
import '../core/writable_reacton.dart';
import '../store/store.dart';

/// Change event for observable maps.
sealed class MapChange<K, V> {
  const MapChange();
}

class MapEntryAdded<K, V> extends MapChange<K, V> {
  final K key;
  final V value;
  const MapEntryAdded(this.key, this.value);
}

class MapEntryRemoved<K, V> extends MapChange<K, V> {
  final K key;
  final V value;
  const MapEntryRemoved(this.key, this.value);
}

class MapEntryUpdated<K, V> extends MapChange<K, V> {
  final K key;
  final V oldValue;
  final V newValue;
  const MapEntryUpdated(this.key, this.oldValue, this.newValue);
}

class MapCleared<K, V> extends MapChange<K, V> {
  final Map<K, V> previousEntries;
  const MapCleared(this.previousEntries);
}

/// A writable reacton that holds a `Map<K, V>` with granular operations.
///
/// ```dart
/// final usersReacton = reactonMap<String, User>({}, name: 'users');
///
/// store.mapPut(usersReacton, 'id1', User('Alice'));
/// store.mapRemove(usersReacton, 'id1');
/// store.mapUpdate(usersReacton, 'id1', (u) => u.copyWith(name: 'Bob'));
/// ```
class MapReacton<K, V> extends WritableReacton<Map<K, V>> {
  final List<void Function(MapChange<K, V>)> _changeListeners = [];

  MapReacton(
    super.initialValue, {
    super.name,
    super.options,
  });

  void Function() onChangeEvent(void Function(MapChange<K, V>) listener) {
    _changeListeners.add(listener);
    return () => _changeListeners.remove(listener);
  }

  void notifyChange(MapChange<K, V> change) {
    for (final listener in List.of(_changeListeners)) {
      listener(change);
    }
  }
}

/// Create a reactive map reacton.
MapReacton<K, V> reactonMap<K, V>(Map<K, V> initialValue, {String? name, ReactonOptions<Map<K, V>>? options}) {
  return MapReacton<K, V>(Map<K, V>.of(initialValue), name: name, options: options);
}

/// Extension on [ReactonStore] for map operations.
extension ReactonStoreMap on ReactonStore {
  /// Put a key-value pair into the map.
  void mapPut<K, V>(MapReacton<K, V> mapReacton, K key, V value) {
    final current = Map<K, V>.of(get(mapReacton));
    final hadKey = current.containsKey(key);
    final oldValue = current[key];
    current[key] = value;
    set(mapReacton, current);
    if (hadKey) {
      mapReacton.notifyChange(MapEntryUpdated(key, oldValue as V, value));
    } else {
      mapReacton.notifyChange(MapEntryAdded(key, value));
    }
  }

  /// Put all entries into the map.
  void mapPutAll<K, V>(MapReacton<K, V> mapReacton, Map<K, V> entries) {
    final current = Map<K, V>.of(get(mapReacton));
    for (final entry in entries.entries) {
      final hadKey = current.containsKey(entry.key);
      final oldValue = current[entry.key];
      current[entry.key] = entry.value;
      if (hadKey) {
        mapReacton.notifyChange(MapEntryUpdated(entry.key, oldValue as V, entry.value));
      } else {
        mapReacton.notifyChange(MapEntryAdded(entry.key, entry.value));
      }
    }
    set(mapReacton, current);
  }

  /// Remove a key from the map. Returns the removed value or null.
  V? mapRemove<K, V>(MapReacton<K, V> mapReacton, K key) {
    final current = Map<K, V>.of(get(mapReacton));
    if (!current.containsKey(key)) return null;
    final removed = current.remove(key);
    set(mapReacton, current);
    if (removed != null) {
      mapReacton.notifyChange(MapEntryRemoved(key, removed));
    }
    return removed;
  }

  /// Update a value for a given key using an updater function.
  void mapUpdate<K, V>(MapReacton<K, V> mapReacton, K key, V Function(V current) updater) {
    final current = Map<K, V>.of(get(mapReacton));
    if (!current.containsKey(key)) {
      throw StateError('Key "$key" not found in map reacton "${mapReacton.ref}"');
    }
    final oldValue = current[key] as V;
    final newValue = updater(oldValue);
    current[key] = newValue;
    set(mapReacton, current);
    mapReacton.notifyChange(MapEntryUpdated(key, oldValue, newValue));
  }

  /// Clear all entries from the map.
  void mapClear<K, V>(MapReacton<K, V> mapReacton) {
    final current = get(mapReacton);
    final previous = Map<K, V>.of(current);
    set(mapReacton, <K, V>{});
    mapReacton.notifyChange(MapCleared(previous));
  }

  /// Check if the map contains a key.
  bool mapContainsKey<K, V>(MapReacton<K, V> mapReacton, K key) {
    return get(mapReacton).containsKey(key);
  }

  /// Get the number of entries in the map.
  int mapLength<K, V>(MapReacton<K, V> mapReacton) {
    return get(mapReacton).length;
  }

  /// Remove entries that match a predicate.
  void mapRemoveWhere<K, V>(MapReacton<K, V> mapReacton, bool Function(K key, V value) test) {
    final current = Map<K, V>.of(get(mapReacton));
    final toRemove = <K, V>{};
    current.forEach((key, value) {
      if (test(key, value)) toRemove[key] = value;
    });
    if (toRemove.isEmpty) return;
    toRemove.forEach((key, value) {
      current.remove(key);
      mapReacton.notifyChange(MapEntryRemoved(key, value));
    });
    set(mapReacton, current);
  }
}
