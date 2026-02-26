import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  // =========================================================================
  // StoreSnapshot
  // =========================================================================
  group('StoreSnapshot', () {
    test('captures all values from a store', () {
      final counter = reacton(42, name: 'snap_counter');
      final name = reacton('Alice', name: 'snap_name');
      final store = ReactonStore();

      // Initialize by reading
      store.get(counter);
      store.get(name);

      final snap = store.snapshot();

      expect(snap.get(counter), 42);
      expect(snap.get(name), 'Alice');
    });

    test('snapshot reflects current values at time of capture', () {
      final counter = reacton(0, name: 'snap_current');
      final store = ReactonStore();

      store.set(counter, 10);
      final snap = store.snapshot();

      expect(snap.get(counter), 10);

      // Changing the store after snapshot should not affect snapshot
      store.set(counter, 20);
      expect(snap.get(counter), 10);
      expect(store.get(counter), 20);
    });

    test('snapshot values map is immutable', () {
      final counter = reacton(0, name: 'snap_immutable');
      final store = ReactonStore();
      store.get(counter);

      final snap = store.snapshot();

      // Attempting to modify the values map should throw
      expect(
        () => (snap.values as Map)[ReactonRef(debugName: 'hack')] = 'bad',
        throwsA(anything),
      );
    });

    test('get() returns correct typed value', () {
      final intReacton = reacton(42, name: 'snap_int');
      final strReacton = reacton('hello', name: 'snap_str');
      final boolReacton = reacton(true, name: 'snap_bool');
      final store = ReactonStore();

      store.get(intReacton);
      store.get(strReacton);
      store.get(boolReacton);

      final snap = store.snapshot();

      expect(snap.get(intReacton), isA<int>());
      expect(snap.get(intReacton), 42);
      expect(snap.get(strReacton), isA<String>());
      expect(snap.get(strReacton), 'hello');
      expect(snap.get(boolReacton), isA<bool>());
      expect(snap.get(boolReacton), isTrue);
    });

    test('get() returns null for reacton not in snapshot', () {
      final counter = reacton(0, name: 'snap_missing');
      final store = ReactonStore();

      // Take snapshot without initializing counter
      final snap = store.snapshot();

      expect(snap.get(counter), isNull);
    });

    test('contains() returns true for captured reacton', () {
      final counter = reacton(0, name: 'snap_contains');
      final store = ReactonStore();
      store.get(counter);

      final snap = store.snapshot();
      expect(snap.contains(counter), isTrue);
    });

    test('contains() returns false for missing reacton', () {
      final counter = reacton(0, name: 'snap_not_contains');
      final store = ReactonStore();

      final snap = store.snapshot();
      expect(snap.contains(counter), isFalse);
    });

    test('size returns number of captured reactons', () {
      final a = reacton(1, name: 'snap_size_a');
      final b = reacton(2, name: 'snap_size_b');
      final c = reacton(3, name: 'snap_size_c');
      final store = ReactonStore();

      store.get(a);
      store.get(b);
      store.get(c);

      final snap = store.snapshot();
      expect(snap.size, 3);
    });

    test('size is 0 for empty store snapshot', () {
      final store = ReactonStore();
      final snap = store.snapshot();
      expect(snap.size, 0);
    });

    test('timestamp is recorded at creation time', () {
      final before = DateTime.now();
      final snap = StoreSnapshot({});
      final after = DateTime.now();

      expect(snap.timestamp.isAfter(before) || snap.timestamp == before, isTrue);
      expect(snap.timestamp.isBefore(after) || snap.timestamp == after, isTrue);
    });

    test('copy() creates an independent snapshot', () {
      final ref = ReactonRef(debugName: 'copy_test');
      final snap = StoreSnapshot({ref: 42});

      final copy = snap.copy();

      expect(copy.values[ref], 42);
      expect(copy.timestamp, snap.timestamp);

      // They should be independent instances
      expect(identical(snap, copy), isFalse);
      expect(identical(snap.values, copy.values), isFalse);
    });

    test('copy() preserves timestamp', () {
      final snap = StoreSnapshot({});
      final copy = snap.copy();

      expect(copy.timestamp, snap.timestamp);
    });

    test('copy() values are independent from original', () {
      final ref = ReactonRef(debugName: 'copy_independent');
      final original = StoreSnapshot({ref: 'original'});
      final copy = original.copy();

      // The copy's values map is a new map
      expect(copy.values[ref], 'original');

      // They use different map instances
      expect(identical(original.values, copy.values), isFalse);
    });
  });

  // =========================================================================
  // SnapshotDiff
  // =========================================================================
  group('SnapshotDiff', () {
    test('diff finds added reactons', () {
      final refA = ReactonRef(debugName: 'diff_a');
      final refB = ReactonRef(debugName: 'diff_b');

      final snap1 = StoreSnapshot({refA: 1});
      final snap2 = StoreSnapshot({refA: 1, refB: 2});

      final diff = snap1.diff(snap2);

      expect(diff.added, {refB: 2});
      expect(diff.removed, isEmpty);
      expect(diff.changed, isEmpty);
    });

    test('diff finds removed reactons', () {
      final refA = ReactonRef(debugName: 'diff_rem_a');
      final refB = ReactonRef(debugName: 'diff_rem_b');

      final snap1 = StoreSnapshot({refA: 1, refB: 2});
      final snap2 = StoreSnapshot({refA: 1});

      final diff = snap1.diff(snap2);

      expect(diff.added, isEmpty);
      expect(diff.removed, {refB: 2});
      expect(diff.changed, isEmpty);
    });

    test('diff finds changed values', () {
      final refA = ReactonRef(debugName: 'diff_chg_a');

      final snap1 = StoreSnapshot({refA: 1});
      final snap2 = StoreSnapshot({refA: 99});

      final diff = snap1.diff(snap2);

      expect(diff.added, isEmpty);
      expect(diff.removed, isEmpty);
      expect(diff.changed.length, 1);
      expect(diff.changed[refA], (1, 99));
    });

    test('diff detects all three types simultaneously', () {
      final refA = ReactonRef(debugName: 'diff_all_a');
      final refB = ReactonRef(debugName: 'diff_all_b');
      final refC = ReactonRef(debugName: 'diff_all_c');

      final snap1 = StoreSnapshot({refA: 'old', refB: 'removed'});
      final snap2 = StoreSnapshot({refA: 'new', refC: 'added'});

      final diff = snap1.diff(snap2);

      expect(diff.added, {refC: 'added'});
      expect(diff.removed, {refB: 'removed'});
      expect(diff.changed[refA], ('old', 'new'));
    });

    test('isEmpty when snapshots are identical', () {
      final refA = ReactonRef(debugName: 'diff_same_a');
      final refB = ReactonRef(debugName: 'diff_same_b');

      final snap1 = StoreSnapshot({refA: 1, refB: 'two'});
      final snap2 = StoreSnapshot({refA: 1, refB: 'two'});

      final diff = snap1.diff(snap2);

      expect(diff.isEmpty, isTrue);
      expect(diff.isNotEmpty, isFalse);
    });

    test('isEmpty when both snapshots are empty', () {
      final snap1 = StoreSnapshot({});
      final snap2 = StoreSnapshot({});

      final diff = snap1.diff(snap2);
      expect(diff.isEmpty, isTrue);
    });

    test('isNotEmpty when there are differences', () {
      final refA = ReactonRef(debugName: 'diff_notempty');

      final snap1 = StoreSnapshot({});
      final snap2 = StoreSnapshot({refA: 42});

      final diff = snap1.diff(snap2);

      expect(diff.isNotEmpty, isTrue);
      expect(diff.isEmpty, isFalse);
    });

    test('diff with only additions', () {
      final refA = ReactonRef(debugName: 'diff_only_add_a');
      final refB = ReactonRef(debugName: 'diff_only_add_b');

      final snap1 = StoreSnapshot({});
      final snap2 = StoreSnapshot({refA: 1, refB: 2});

      final diff = snap1.diff(snap2);

      expect(diff.added.length, 2);
      expect(diff.removed, isEmpty);
      expect(diff.changed, isEmpty);
    });

    test('diff with only removals', () {
      final refA = ReactonRef(debugName: 'diff_only_rem_a');
      final refB = ReactonRef(debugName: 'diff_only_rem_b');

      final snap1 = StoreSnapshot({refA: 1, refB: 2});
      final snap2 = StoreSnapshot({});

      final diff = snap1.diff(snap2);

      expect(diff.added, isEmpty);
      expect(diff.removed.length, 2);
      expect(diff.changed, isEmpty);
    });

    test('changed tuple contains (oldValue, newValue)', () {
      final refA = ReactonRef(debugName: 'diff_tuple');

      final snap1 = StoreSnapshot({refA: 'before'});
      final snap2 = StoreSnapshot({refA: 'after'});

      final diff = snap1.diff(snap2);
      final (oldVal, newVal) = diff.changed[refA]!;

      expect(oldVal, 'before');
      expect(newVal, 'after');
    });
  });

  // =========================================================================
  // Store snapshot/restore integration
  // =========================================================================
  group('Store snapshot/restore integration', () {
    test('restore applies snapshot values to the store', () {
      final counter = reacton(0, name: 'restore_counter');
      final store = ReactonStore();

      store.set(counter, 42);
      final snap = store.snapshot();

      store.set(counter, 0);
      expect(store.get(counter), 0);

      store.restore(snap);
      expect(store.get(counter), 42);
    });

    test('restore notifies subscribers', () {
      final counter = reacton(0, name: 'restore_notify');
      final store = ReactonStore();
      final observed = <int>[];

      store.subscribe(counter, (value) {
        observed.add(value);
      });

      store.set(counter, 10);
      final snap = store.snapshot();

      store.set(counter, 20);

      store.restore(snap);

      expect(observed, contains(10));
      expect(observed, contains(20));
      // The last observed value should be the restored one
      expect(observed.last, 10);
    });
  });
}
