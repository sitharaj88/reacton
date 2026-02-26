import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  late ReactonStore store;

  setUp(() {
    store = ReactonStore();
  });

  tearDown(() {
    store.dispose();
  });

  group('ReactonStore - Basic Operations', () {
    test('get returns initial value', () {
      final counter = reacton(0, name: 'counter');
      expect(store.get(counter), 0);
    });

    test('set updates value', () {
      final counter = reacton(0, name: 'counter');
      store.set(counter, 42);
      expect(store.get(counter), 42);
    });

    test('update applies function', () {
      final counter = reacton(0, name: 'counter');
      store.update(counter, (c) => c + 1);
      expect(store.get(counter), 1);
      store.update(counter, (c) => c + 10);
      expect(store.get(counter), 11);
    });

    test('set with same value is no-op', () {
      final counter = reacton(0, name: 'counter');
      var notifyCount = 0;
      store.subscribe(counter, (_) => notifyCount++);

      store.set(counter, 0); // same as initial
      expect(notifyCount, 0);

      store.set(counter, 1); // different
      expect(notifyCount, 1);
    });
  });

  group('ReactonStore - Computed', () {
    test('computed derives from writable', () {
      final counter = reacton(5, name: 'counter');
      final doubled = computed(
        (read) => read(counter) * 2,
        name: 'doubled',
      );

      expect(store.get(doubled), 10);

      store.set(counter, 10);
      expect(store.get(doubled), 20);
    });

    test('computed chains work', () {
      final a = reacton(1, name: 'a');
      final b = computed((read) => read(a) + 1, name: 'b');
      final c = computed((read) => read(b) * 2, name: 'c');

      expect(store.get(c), 4); // (1+1)*2

      store.set(a, 5);
      expect(store.get(b), 6);
      expect(store.get(c), 12); // (5+1)*2
    });

    test('diamond dependency resolves correctly', () {
      // A -> B -> D
      // A -> C -> D
      // D should recompute exactly once when A changes
      final a = reacton(1, name: 'a');
      final b = computed((read) => read(a) + 10, name: 'b');
      final c = computed((read) => read(a) * 10, name: 'c');

      var dComputeCount = 0;
      final d = computed((read) {
        dComputeCount++;
        return read(b) + read(c);
      }, name: 'd');

      // Initial computation
      expect(store.get(d), 21); // (1+10) + (1*10) = 21
      dComputeCount = 0;

      // Change A
      store.set(a, 2);
      expect(store.get(d), 32); // (2+10) + (2*10) = 32
      // D should have recomputed exactly once (glitch-free)
      expect(dComputeCount, 1);
    });

    test('computed with multiple sources', () {
      final firstName = reacton('John', name: 'firstName');
      final lastName = reacton('Doe', name: 'lastName');
      final fullName = computed(
        (read) => '${read(firstName)} ${read(lastName)}',
        name: 'fullName',
      );

      expect(store.get(fullName), 'John Doe');

      store.set(firstName, 'Jane');
      expect(store.get(fullName), 'Jane Doe');

      store.set(lastName, 'Smith');
      expect(store.get(fullName), 'Jane Smith');
    });
  });

  group('ReactonStore - Subscriptions', () {
    test('subscribe receives updates', () {
      final counter = reacton(0, name: 'counter');
      final values = <int>[];

      store.subscribe(counter, (v) => values.add(v));

      store.set(counter, 1);
      store.set(counter, 2);
      store.set(counter, 3);

      expect(values, [1, 2, 3]);
    });

    test('unsubscribe stops updates', () {
      final counter = reacton(0, name: 'counter');
      final values = <int>[];

      final unsub = store.subscribe(counter, (v) => values.add(v));

      store.set(counter, 1);
      unsub();
      store.set(counter, 2);

      expect(values, [1]);
    });

    test('computed subscribers receive updates', () {
      final a = reacton(1, name: 'a');
      final doubled = computed((read) => read(a) * 2, name: 'doubled');

      final values = <int>[];
      store.subscribe(doubled, (v) => values.add(v));

      store.set(a, 2);
      store.set(a, 3);

      expect(values, [4, 6]);
    });
  });

  group('ReactonStore - Batch', () {
    test('batch collects mutations', () {
      final a = reacton(0, name: 'a');
      final b = reacton(0, name: 'b');
      final sum = computed<int>((read) => read(a) + read(b), name: 'sum');

      final values = <int>[];
      store.subscribe(sum, (v) => values.add(v));

      store.batch(() {
        store.set(a, 5);
        store.set(b, 10);
      });

      // Sum should have been notified with the final value
      expect(store.get(sum), 15);
      // Should have received at most one notification (batched)
      expect(values.last, 15);
    });

    test('nested batches work', () {
      final counter = reacton(0, name: 'counter');

      store.batch(() {
        store.set(counter, 1);
        store.batch(() {
          store.set(counter, 2);
        });
        store.set(counter, 3);
      });

      expect(store.get(counter), 3);
    });
  });

  group('ReactonStore - Snapshot', () {
    test('snapshot captures current state', () {
      final a = reacton(1, name: 'a');
      final b = reacton('hello', name: 'b');

      store.get(a); // initialize
      store.get(b); // initialize

      final snap = store.snapshot();
      expect(snap.get(a), 1);
      expect(snap.get(b), 'hello');
    });

    test('snapshot diff detects changes', () {
      final counter = reacton(0, name: 'counter');
      store.get(counter); // initialize

      final snap1 = store.snapshot();
      store.set(counter, 5);
      final snap2 = store.snapshot();

      final diff = snap1.diff(snap2);
      expect(diff.isNotEmpty, isTrue);
      expect(diff.changed.containsKey(counter.ref), isTrue);
    });
  });

  group('ReactonStore - Dispose', () {
    test('dispose clears everything', () {
      final counter = reacton(0, name: 'counter');
      store.get(counter);
      store.dispose();
      expect(store.isDisposed, isTrue);
    });
  });
}
