import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  group('EffectNode', () {
    test('creates with default debug name', () {
      final effect = EffectNode((_) => null);
      expect(effect.ref.debugName, 'effect');
    });

    test('creates with custom name', () {
      final effect = EffectNode((_) => null, name: 'myEffect');
      expect(effect.ref.debugName, 'myEffect');
    });

    test('each EffectNode has a unique ref', () {
      final e1 = EffectNode((_) => null);
      final e2 = EffectNode((_) => null);
      expect(e1.ref, isNot(equals(e2.ref)));
    });

    test('run() invokes the effect function', () {
      var invoked = false;
      final effect = EffectNode((read) {
        invoked = true;
        return null;
      });

      final store = ReactonStore();
      final reader = _makeReader(store);
      effect.run(reader);

      expect(invoked, isTrue);
    });

    test('run() returns cleanup function', () {
      var cleanedUp = false;
      final effect = EffectNode((read) {
        return () => cleanedUp = true;
      });

      final store = ReactonStore();
      final reader = _makeReader(store);
      final cleanup = effect.run(reader);

      expect(cleanup, isNotNull);
      cleanup!();
      expect(cleanedUp, isTrue);
    });

    test('run() returns null when no cleanup is returned', () {
      final effect = EffectNode((read) => null);

      final store = ReactonStore();
      final reader = _makeReader(store);
      final cleanup = effect.run(reader);

      expect(cleanup, isNull);
    });

    test('cleanup field starts as null', () {
      final effect = EffectNode((_) => null);
      expect(effect.cleanup, isNull);
    });

    test('cleanup field can be set and called', () {
      var cleanedUp = false;
      final effect = EffectNode((_) => null);
      effect.cleanup = () => cleanedUp = true;

      effect.cleanup!();
      expect(cleanedUp, isTrue);
    });
  });

  group('createEffect()', () {
    test('returns an EffectNode', () {
      final e = createEffect((read) => null);
      expect(e, isA<EffectNode>());
    });

    test('creates with default name', () {
      final e = createEffect((read) => null);
      expect(e.ref.debugName, 'effect');
    });

    test('creates with custom name', () {
      final e = createEffect((read) => null, name: 'logger');
      expect(e.ref.debugName, 'logger');
    });
  });

  group('Effect registration with ReactonStore', () {
    test('effect runs on registration', () {
      final store = ReactonStore();
      var runCount = 0;

      final e = createEffect((read) {
        runCount++;
        return null;
      });

      store.registerEffect(e);
      expect(runCount, 1);
    });

    test('effect tracks dependencies via reader', () {
      final counter = reacton(0, name: 'effect_dep_counter');
      final store = ReactonStore();
      final values = <int>[];

      final e = createEffect((read) {
        values.add(read(counter));
        return null;
      });

      store.registerEffect(e);
      expect(values, [0]);

      store.set(counter, 5);
      expect(values, [0, 5]);
    });

    test('effect re-runs when dependencies change', () {
      final counter = reacton(0, name: 'effect_rerun_counter');
      final store = ReactonStore();
      var runCount = 0;

      final e = createEffect((read) {
        read(counter);
        runCount++;
        return null;
      });

      store.registerEffect(e);
      expect(runCount, 1);

      store.set(counter, 1);
      expect(runCount, 2);

      store.set(counter, 2);
      expect(runCount, 3);
    });

    test('effect cleanup called before re-run', () {
      final counter = reacton(0, name: 'effect_cleanup_counter');
      final store = ReactonStore();
      final events = <String>[];

      final e = createEffect((read) {
        final val = read(counter);
        events.add('run:$val');
        return () => events.add('cleanup:$val');
      });

      store.registerEffect(e);
      expect(events, ['run:0']);

      store.set(counter, 1);
      expect(events, ['run:0', 'cleanup:0', 'run:1']);

      store.set(counter, 2);
      expect(events, ['run:0', 'cleanup:0', 'run:1', 'cleanup:1', 'run:2']);
    });

    test('effect cleanup called on unsubscribe (dispose)', () {
      final counter = reacton(0, name: 'effect_unsub_counter');
      final store = ReactonStore();
      var cleanedUp = false;

      final e = createEffect((read) {
        read(counter);
        return () => cleanedUp = true;
      });

      final unsubscribe = store.registerEffect(e);
      expect(cleanedUp, isFalse);

      unsubscribe();
      expect(cleanedUp, isTrue);
    });

    test('effect with no dependencies does not re-run', () {
      final store = ReactonStore();
      var runCount = 0;

      final e = createEffect((read) {
        runCount++;
        return null;
      });

      store.registerEffect(e);
      expect(runCount, 1);

      // Even if other reactons change, this effect should not re-run
      final unrelated = reacton(0, name: 'effect_unrelated');
      store.set(unrelated, 42);
      expect(runCount, 1);
    });

    test('effect with multiple dependencies re-runs on any change', () {
      final a = reacton(1, name: 'effect_multi_a');
      final b = reacton(10, name: 'effect_multi_b');
      final store = ReactonStore();
      final sums = <int>[];

      final e = createEffect((read) {
        sums.add(read(a) + read(b));
        return null;
      });

      store.registerEffect(e);
      expect(sums, [11]);

      store.set(a, 2);
      expect(sums, [11, 12]);

      store.set(b, 20);
      expect(sums, [11, 12, 22]);
    });

    test('effect can read state without error', () {
      final source = reacton(5, name: 'effect_src');
      final store = ReactonStore();
      final readValues = <int>[];

      final e = createEffect((read) {
        readValues.add(read(source));
        return null;
      });

      store.registerEffect(e);
      expect(readValues, [5]);

      store.set(source, 10);
      expect(readValues, [5, 10]);
    });

    test('effect does not re-run after unsubscribe', () {
      final counter = reacton(0, name: 'effect_no_rerun');
      final store = ReactonStore();
      var runCount = 0;

      final e = createEffect((read) {
        read(counter);
        runCount++;
        return null;
      });

      final unsub = store.registerEffect(e);
      expect(runCount, 1);

      unsub();

      store.set(counter, 1);
      // Should not re-run after unsubscribe
      expect(runCount, 1);
    });

    test('effect cleanup called on store dispose', () {
      final counter = reacton(0, name: 'effect_store_dispose');
      final store = ReactonStore();
      var cleanedUp = false;

      final e = createEffect((read) {
        read(counter);
        return () => cleanedUp = true;
      });

      store.registerEffect(e);
      expect(cleanedUp, isFalse);

      store.dispose();
      expect(cleanedUp, isTrue);
    });

    test('multiple effects on the same reacton all fire', () {
      final counter = reacton(0, name: 'multi_effect_counter');
      final store = ReactonStore();
      var runs1 = 0;
      var runs2 = 0;

      final e1 = createEffect((read) {
        read(counter);
        runs1++;
        return null;
      });

      final e2 = createEffect((read) {
        read(counter);
        runs2++;
        return null;
      });

      store.registerEffect(e1);
      store.registerEffect(e2);
      expect(runs1, 1);
      expect(runs2, 1);

      store.set(counter, 1);
      expect(runs1, 2);
      expect(runs2, 2);
    });

    test('effect with computed dependency', () {
      final counter = reacton(0, name: 'effect_comp_counter');
      final doubled = computed((read) => read(counter) * 2, name: 'effect_comp_doubled');
      final store = ReactonStore();
      final observedValues = <int>[];

      final e = createEffect((read) {
        observedValues.add(read(doubled));
        return null;
      });

      store.registerEffect(e);
      expect(observedValues, [0]);

      store.set(counter, 3);
      expect(observedValues, [0, 6]);
    });
  });
}

/// Helper to create a simple reader from a store.
ReactonReader _makeReader(ReactonStore store) {
  return <T>(ReactonBase<T> r) => store.get(r);
}
