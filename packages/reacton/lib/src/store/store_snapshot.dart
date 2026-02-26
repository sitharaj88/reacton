import '../core/reacton_base.dart';

/// An immutable snapshot of all reacton values at a point in time.
///
/// Used for time-travel debugging, state comparison, and restoration.
class StoreSnapshot {
  /// The reacton values captured in this snapshot.
  final Map<ReactonRef, dynamic> values;

  /// When this snapshot was taken.
  final DateTime timestamp;

  StoreSnapshot(this.values) : timestamp = DateTime.now();

  StoreSnapshot._withTimestamp(this.values, this.timestamp);

  /// Get a value from this snapshot.
  T? get<T>(ReactonBase<T> reacton) {
    return values[reacton.ref] as T?;
  }

  /// Whether this snapshot contains a value for the given reacton.
  bool contains(ReactonBase reacton) => values.containsKey(reacton.ref);

  /// Number of reactons in this snapshot.
  int get size => values.length;

  /// Compare this snapshot with another and return the differences.
  SnapshotDiff diff(StoreSnapshot other) {
    final added = <ReactonRef, dynamic>{};
    final removed = <ReactonRef, dynamic>{};
    final changed = <ReactonRef, (dynamic, dynamic)>{};

    for (final entry in other.values.entries) {
      if (!values.containsKey(entry.key)) {
        added[entry.key] = entry.value;
      } else if (values[entry.key] != entry.value) {
        changed[entry.key] = (values[entry.key], entry.value);
      }
    }

    for (final entry in values.entries) {
      if (!other.values.containsKey(entry.key)) {
        removed[entry.key] = entry.value;
      }
    }

    return SnapshotDiff(added: added, removed: removed, changed: changed);
  }

  /// Create a copy of this snapshot.
  StoreSnapshot copy() {
    return StoreSnapshot._withTimestamp(Map.of(values), timestamp);
  }
}

/// The differences between two snapshots.
class SnapshotDiff {
  final Map<ReactonRef, dynamic> added;
  final Map<ReactonRef, dynamic> removed;
  final Map<ReactonRef, (dynamic, dynamic)> changed;

  const SnapshotDiff({
    required this.added,
    required this.removed,
    required this.changed,
  });

  /// Whether there are any differences.
  bool get isEmpty => added.isEmpty && removed.isEmpty && changed.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
