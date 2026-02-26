import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reacton/flutter_reacton.dart';
import 'package:reacton_test/reacton_test.dart';

void main() {
  // =========================================================================
  // TestReactonStore
  // =========================================================================
  group('TestReactonStore', () {
    test('creates an isolated store', () {
      final store = TestReactonStore();
      expect(store, isA<ReactonStore>());
    });

    test('default storage adapter is MemoryStorage', () {
      final store = TestReactonStore();
      expect(store.storageAdapter, isA<MemoryStorage>());
    });

    test('accepts a custom storage adapter', () {
      final customStorage = MemoryStorage();
      final store = TestReactonStore(storageAdapter: customStorage);
      expect(store.storageAdapter, same(customStorage));
    });

    test('applies overrides on construction', () {
      final counter = reacton<int>(0, name: 'counter');
      final store = TestReactonStore(
        overrides: [ReactonTestOverride(counter, 42)],
      );
      expect(store.get(counter), equals(42));
    });

    test('applies multiple overrides on construction', () {
      final counter = reacton<int>(0, name: 'counter');
      final greeting = reacton<String>('hello', name: 'greeting');
      final store = TestReactonStore(
        overrides: [
          ReactonTestOverride(counter, 99),
          ReactonTestOverride(greeting, 'world'),
        ],
      );
      expect(store.get(counter), equals(99));
      expect(store.get(greeting), equals('world'));
    });

    test('works without overrides', () {
      final store = TestReactonStore();
      final counter = reacton<int>(5, name: 'counter');
      expect(store.get(counter), equals(5));
    });

    test('works with empty overrides list', () {
      final store = TestReactonStore(overrides: []);
      final counter = reacton<int>(7, name: 'counter');
      expect(store.get(counter), equals(7));
    });

    test('forceSet values are readable via get', () {
      final store = TestReactonStore();
      final counter = reacton<int>(0, name: 'counter');
      store.forceSet(counter, 100);
      expect(store.get(counter), equals(100));
    });

    test('set and get work correctly on test store', () {
      final store = TestReactonStore();
      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 10);
      expect(store.get(counter), equals(10));
    });

    test('overrides take precedence over initial value', () {
      final counter = reacton<int>(0, name: 'counter');
      final store = TestReactonStore(
        overrides: [ReactonTestOverride(counter, 50)],
      );
      // The override sets the value to 50, not the initial 0
      expect(store.get(counter), equals(50));
    });
  });

  // =========================================================================
  // ReactonTestOverride
  // =========================================================================
  group('ReactonTestOverride', () {
    test('overrides a writable reacton value', () {
      final counter = reacton<int>(0, name: 'counter');
      final override = ReactonTestOverride(counter, 42);
      final store = TestReactonStore();
      override.apply(store);
      expect(store.get(counter), equals(42));
    });

    test('override is applied via forceSet (bypasses middleware)', () {
      final counter = reacton<int>(0, name: 'counter');
      final store = TestReactonStore();
      final override = ReactonTestOverride(counter, 99);
      override.apply(store);
      expect(store.get(counter), equals(99));
    });

    test('works with int type', () {
      final counter = reacton<int>(0, name: 'counter');
      final override = ReactonTestOverride<int>(counter, 123);
      final store = TestReactonStore();
      override.apply(store);
      expect(store.get(counter), equals(123));
    });

    test('works with String type', () {
      final name = reacton<String>('', name: 'name');
      final override = ReactonTestOverride<String>(name, 'test-value');
      final store = TestReactonStore();
      override.apply(store);
      expect(store.get(name), equals('test-value'));
    });

    test('works with bool type', () {
      final flag = reacton<bool>(false, name: 'flag');
      final override = ReactonTestOverride<bool>(flag, true);
      final store = TestReactonStore();
      override.apply(store);
      expect(store.get(flag), isTrue);
    });

    test('works with List type', () {
      final items = reacton<List<int>>([], name: 'items');
      final override = ReactonTestOverride<List<int>>(items, [1, 2, 3]);
      final store = TestReactonStore();
      override.apply(store);
      expect(store.get(items), equals([1, 2, 3]));
    });

    test('stores the reacton reference', () {
      final counter = reacton<int>(0, name: 'counter');
      final override = ReactonTestOverride(counter, 42);
      expect(override.reacton, same(counter));
    });

    test('stores the override value', () {
      final counter = reacton<int>(0, name: 'counter');
      final override = ReactonTestOverride(counter, 42);
      expect(override.value, equals(42));
    });
  });

  // =========================================================================
  // AsyncReactonTestOverride
  // =========================================================================
  group('AsyncReactonTestOverride', () {
    test('.data() creates an AsyncData override', () {
      final asyncR =
          reacton<AsyncValue<String>>(const AsyncLoading(), name: 'async');
      final override =
          AsyncReactonTestOverride.data(asyncR, 'hello');
      expect(override.value, isA<AsyncData<String>>());
      expect(override.value.valueOrNull, equals('hello'));
    });

    test('.loading() creates an AsyncLoading override', () {
      final asyncR =
          reacton<AsyncValue<String>>(const AsyncLoading(), name: 'async');
      final override = AsyncReactonTestOverride<String>.loading(asyncR);
      expect(override.value, isA<AsyncLoading<String>>());
      expect(override.value.isLoading, isTrue);
    });

    test('.error() creates an AsyncError override', () {
      final asyncR =
          reacton<AsyncValue<String>>(const AsyncLoading(), name: 'async');
      final override = AsyncReactonTestOverride.error(
        asyncR,
        Exception('test error'),
      );
      expect(override.value, isA<AsyncError<String>>());
      expect(override.value.hasError, isTrue);
    });

    test('.error() with stackTrace preserves the stackTrace', () {
      final asyncR =
          reacton<AsyncValue<String>>(const AsyncLoading(), name: 'async');
      final trace = StackTrace.current;
      final override = AsyncReactonTestOverride.error(
        asyncR,
        Exception('test error'),
        trace,
      );
      final errorValue = override.value as AsyncError<String>;
      expect(errorValue.stackTrace, same(trace));
    });

    test('.error() without stackTrace has null stackTrace', () {
      final asyncR =
          reacton<AsyncValue<int>>(const AsyncLoading(), name: 'async');
      final override = AsyncReactonTestOverride.error(
        asyncR,
        'some error',
      );
      final errorValue = override.value as AsyncError<int>;
      expect(errorValue.stackTrace, isNull);
    });

    test('.data() override applies to store correctly', () {
      final asyncR =
          reacton<AsyncValue<int>>(const AsyncLoading(), name: 'async');
      final store = TestReactonStore(
        overrides: [AsyncReactonTestOverride.data(asyncR, 42)],
      );
      final value = store.get(asyncR);
      expect(value.hasData, isTrue);
      expect(value.valueOrNull, equals(42));
    });

    test('.loading() override applies to store correctly', () {
      final asyncR =
          reacton<AsyncValue<int>>(const AsyncData(10), name: 'async');
      final store = TestReactonStore(
        overrides: [AsyncReactonTestOverride<int>.loading(asyncR)],
      );
      final value = store.get(asyncR);
      expect(value.isLoading, isTrue);
    });

    test('.error() override applies to store correctly', () {
      final asyncR =
          reacton<AsyncValue<int>>(const AsyncLoading(), name: 'async');
      final store = TestReactonStore(
        overrides: [
          AsyncReactonTestOverride.error(asyncR, 'failure'),
        ],
      );
      final value = store.get(asyncR);
      expect(value.hasError, isTrue);
    });

    test('stores the reacton reference', () {
      final asyncR =
          reacton<AsyncValue<String>>(const AsyncLoading(), name: 'async');
      final override = AsyncReactonTestOverride.data(asyncR, 'val');
      expect(override.reacton, same(asyncR));
    });
  });

  // =========================================================================
  // MockReacton
  // =========================================================================
  group('MockReacton', () {
    test('initial readCount is 0', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      expect(mock.readCount, equals(0));
    });

    test('initial writeCount is 0', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      expect(mock.writeCount, equals(0));
    });

    test('initial valueHistory contains only initialValue', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 5);
      expect(mock.valueHistory, equals([5]));
    });

    test('lastValue returns initialValue when no writes', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 10);
      expect(mock.lastValue, equals(10));
    });

    test('recordRead increments readCount', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordRead();
      expect(mock.readCount, equals(1));
      mock.recordRead();
      expect(mock.readCount, equals(2));
    });

    test('recordRead does not affect writeCount', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordRead();
      mock.recordRead();
      mock.recordRead();
      expect(mock.writeCount, equals(0));
    });

    test('recordWrite increments writeCount', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordWrite(1);
      expect(mock.writeCount, equals(1));
      mock.recordWrite(2);
      expect(mock.writeCount, equals(2));
    });

    test('recordWrite adds value to valueHistory', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordWrite(10);
      expect(mock.valueHistory, equals([0, 10]));
    });

    test('multiple writes are tracked in order', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordWrite(1);
      mock.recordWrite(2);
      mock.recordWrite(3);
      expect(mock.valueHistory, equals([0, 1, 2, 3]));
      expect(mock.lastValue, equals(3));
      expect(mock.writeCount, equals(3));
    });

    test('reset clears readCount', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordRead();
      mock.recordRead();
      mock.reset();
      expect(mock.readCount, equals(0));
    });

    test('reset clears writeCount', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordWrite(1);
      mock.recordWrite(2);
      mock.reset();
      expect(mock.writeCount, equals(0));
    });

    test('reset restores initial value in history', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 5);
      mock.recordWrite(10);
      mock.recordWrite(20);
      mock.reset();
      expect(mock.valueHistory, equals([5]));
      expect(mock.lastValue, equals(5));
    });

    test('valueHistory returns an unmodifiable list', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      final history = mock.valueHistory;
      expect(() => history.add(999), throwsUnsupportedError);
    });

    test('stores the reacton reference', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      expect(mock.reacton, same(counter));
    });

    test('stores the initialValue', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 42);
      expect(mock.initialValue, equals(42));
    });

    test('works with String type', () {
      final name = reacton<String>('', name: 'name');
      final mock = MockReacton<String>(name, initialValue: 'initial');
      mock.recordWrite('updated');
      expect(mock.valueHistory, equals(['initial', 'updated']));
      expect(mock.lastValue, equals('updated'));
    });

    test('recordRead does not affect valueHistory', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      mock.recordRead();
      mock.recordRead();
      expect(mock.valueHistory, equals([0]));
    });
  });

  // =========================================================================
  // EffectTracker
  // =========================================================================
  group('EffectTracker', () {
    test('initially has empty invocations', () {
      final tracker = EffectTracker();
      expect(tracker.invocations, isEmpty);
    });

    test('wasAnyCalled is false initially', () {
      final tracker = EffectTracker();
      expect(tracker.wasAnyCalled, isFalse);
    });

    test('totalCallCount is 0 initially', () {
      final tracker = EffectTracker();
      expect(tracker.totalCallCount, equals(0));
    });

    test('record() adds an invocation', () {
      final tracker = EffectTracker();
      tracker.record('myEffect');
      expect(tracker.invocations, hasLength(1));
      expect(tracker.invocations.first.name, equals('myEffect'));
    });

    test('totalCallCount is incremented after record()', () {
      final tracker = EffectTracker();
      tracker.record('effect1');
      tracker.record('effect2');
      expect(tracker.totalCallCount, equals(2));
    });

    test('callCount returns count for a specific effect name', () {
      final tracker = EffectTracker();
      tracker.record('effectA');
      tracker.record('effectB');
      tracker.record('effectA');
      expect(tracker.callCount('effectA'), equals(2));
      expect(tracker.callCount('effectB'), equals(1));
    });

    test('wasCalled returns true after record()', () {
      final tracker = EffectTracker();
      tracker.record('myEffect');
      expect(tracker.wasCalled('myEffect'), isTrue);
    });

    test('wasCalled returns false for unknown effect', () {
      final tracker = EffectTracker();
      tracker.record('effectA');
      expect(tracker.wasCalled('effectB'), isFalse);
    });

    test('wasAnyCalled returns true after any record', () {
      final tracker = EffectTracker();
      tracker.record('someEffect');
      expect(tracker.wasAnyCalled, isTrue);
    });

    test('invocationsOf returns filtered list for given name', () {
      final tracker = EffectTracker();
      tracker.record('effectA');
      tracker.record('effectB');
      tracker.record('effectA');
      tracker.record('effectC');
      final filtered = tracker.invocationsOf('effectA');
      expect(filtered, hasLength(2));
      expect(filtered.every((i) => i.name == 'effectA'), isTrue);
    });

    test('invocationsOf returns empty list for unknown name', () {
      final tracker = EffectTracker();
      tracker.record('effectA');
      expect(tracker.invocationsOf('effectB'), isEmpty);
    });

    test('multiple effects are tracked independently', () {
      final tracker = EffectTracker();
      tracker.record('fetch');
      tracker.record('save');
      tracker.record('fetch');
      tracker.record('delete');
      tracker.record('fetch');
      expect(tracker.callCount('fetch'), equals(3));
      expect(tracker.callCount('save'), equals(1));
      expect(tracker.callCount('delete'), equals(1));
      expect(tracker.totalCallCount, equals(5));
    });

    test('reset clears all invocations', () {
      final tracker = EffectTracker();
      tracker.record('effectA');
      tracker.record('effectB');
      tracker.reset();
      expect(tracker.invocations, isEmpty);
      expect(tracker.totalCallCount, equals(0));
      expect(tracker.wasAnyCalled, isFalse);
      expect(tracker.wasCalled('effectA'), isFalse);
    });

    test('metadata is captured in invocation', () {
      final tracker = EffectTracker();
      tracker.record('myEffect', {'key': 'value', 'count': 42});
      final invocation = tracker.invocations.first;
      expect(invocation.metadata, isNotNull);
      expect(invocation.metadata!['key'], equals('value'));
      expect(invocation.metadata!['count'], equals(42));
    });

    test('metadata is null when not provided', () {
      final tracker = EffectTracker();
      tracker.record('myEffect');
      expect(tracker.invocations.first.metadata, isNull);
    });

    test('timestamp is captured in invocation', () {
      final before = DateTime.now();
      final tracker = EffectTracker();
      tracker.record('myEffect');
      final after = DateTime.now();
      final timestamp = tracker.invocations.first.timestamp;
      expect(
        timestamp.isAfter(before) || timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('invocations list is unmodifiable', () {
      final tracker = EffectTracker();
      tracker.record('effectA');
      final list = tracker.invocations;
      expect(
        () => list.add(EffectInvocation(
          name: 'bogus',
          timestamp: DateTime.now(),
        )),
        throwsUnsupportedError,
      );
    });

    test('invocations preserve order', () {
      final tracker = EffectTracker();
      tracker.record('first');
      tracker.record('second');
      tracker.record('third');
      expect(tracker.invocations[0].name, equals('first'));
      expect(tracker.invocations[1].name, equals('second'));
      expect(tracker.invocations[2].name, equals('third'));
    });
  });

  // =========================================================================
  // EffectInvocation
  // =========================================================================
  group('EffectInvocation', () {
    test('toString includes name and timestamp', () {
      final now = DateTime.now();
      final invocation = EffectInvocation(name: 'test', timestamp: now);
      expect(invocation.toString(), contains('test'));
      expect(invocation.toString(), contains(now.toString()));
    });

    test('stores all properties correctly', () {
      final now = DateTime.now();
      final meta = {'key': 'val'};
      final invocation =
          EffectInvocation(name: 'myEffect', timestamp: now, metadata: meta);
      expect(invocation.name, equals('myEffect'));
      expect(invocation.timestamp, same(now));
      expect(invocation.metadata, same(meta));
    });
  });

  // =========================================================================
  // Graph Assertions (ReactonStoreTestExtensions)
  // =========================================================================
  group('Graph Assertions', () {
    group('expectReacton', () {
      test('passes for correct value', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.set(counter, 10);
        // Should not throw
        store.expectReacton(counter, 10);
      });

      test('fails for wrong value', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.set(counter, 10);
        expect(
          () => store.expectReacton(counter, 99),
          throwsA(isA<TestFailure>()),
        );
      });

      test('works with initial value (no set)', () {
        final counter = reacton<int>(7, name: 'counter');
        final store = TestReactonStore();
        store.expectReacton(counter, 7);
      });

      test('works with String type', () {
        final name = reacton<String>('hello', name: 'name');
        final store = TestReactonStore();
        store.expectReacton(name, 'hello');
      });
    });

    group('expectLoading', () {
      test('passes when reacton is in loading state', () {
        final asyncR =
            reacton<AsyncValue<int>>(const AsyncLoading(), name: 'async');
        final store = TestReactonStore();
        store.expectLoading<int>(asyncR);
      });

      test('fails when reacton is in data state', () {
        final asyncR = reacton<AsyncValue<int>>(
          const AsyncData(42),
          name: 'async',
        );
        final store = TestReactonStore();
        expect(
          () => store.expectLoading<int>(asyncR),
          throwsA(isA<TestFailure>()),
        );
      });
    });

    group('expectData', () {
      test('passes for correct data value', () {
        final asyncR = reacton<AsyncValue<String>>(
          const AsyncData('hello'),
          name: 'async',
        );
        final store = TestReactonStore();
        store.expectData<String>(asyncR, 'hello');
      });

      test('fails when reacton is in loading state', () {
        final asyncR =
            reacton<AsyncValue<int>>(const AsyncLoading(), name: 'async');
        final store = TestReactonStore();
        expect(
          () => store.expectData<int>(asyncR, 0),
          throwsA(isA<TestFailure>()),
        );
      });

      test('fails for wrong data value', () {
        final asyncR = reacton<AsyncValue<int>>(
          const AsyncData(10),
          name: 'async',
        );
        final store = TestReactonStore();
        expect(
          () => store.expectData<int>(asyncR, 99),
          throwsA(isA<TestFailure>()),
        );
      });
    });

    group('expectError', () {
      test('passes when reacton is in error state', () {
        final asyncR = reacton<AsyncValue<int>>(
          AsyncError<int>(Exception('fail')),
          name: 'async',
        );
        final store = TestReactonStore();
        store.expectError<int>(asyncR);
      });

      test('fails when reacton is in data state', () {
        final asyncR = reacton<AsyncValue<int>>(
          const AsyncData(42),
          name: 'async',
        );
        final store = TestReactonStore();
        expect(
          () => store.expectError<int>(asyncR),
          throwsA(isA<TestFailure>()),
        );
      });

      test('fails when reacton is in loading state', () {
        final asyncR =
            reacton<AsyncValue<int>>(const AsyncLoading(), name: 'async');
        final store = TestReactonStore();
        expect(
          () => store.expectError<int>(asyncR),
          throwsA(isA<TestFailure>()),
        );
      });
    });

    group('collectValues', () {
      test('collects emissions during action', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        // Initialize the reacton first
        store.get(counter);
        final values = store.collectValues<int>(counter, () {
          store.set(counter, 1);
          store.set(counter, 2);
          store.set(counter, 3);
        });
        expect(values, equals([1, 2, 3]));
      });

      test('returns empty list when no changes occur', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        final values = store.collectValues<int>(counter, () {
          // no-op
        });
        expect(values, isEmpty);
      });

      test('does not collect values after action completes', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        final values = store.collectValues<int>(counter, () {
          store.set(counter, 1);
        });
        // Set after collection should not be captured
        store.set(counter, 99);
        expect(values, equals([1]));
      });
    });

    group('expectEmissions', () {
      test('passes for correct emission sequence', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        store.expectEmissions<int>(
          counter,
          () {
            store.set(counter, 1);
            store.set(counter, 2);
          },
          [1, 2],
        );
      });

      test('fails for wrong emission sequence', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        expect(
          () => store.expectEmissions<int>(
            counter,
            () {
              store.set(counter, 1);
              store.set(counter, 2);
            },
            [2, 1], // wrong order
          ),
          throwsA(isA<TestFailure>()),
        );
      });

      test('passes for empty emissions when no changes', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        store.expectEmissions<int>(counter, () {}, []);
      });
    });

    group('expectEmissionCount', () {
      test('passes for correct count', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        store.expectEmissionCount<int>(
          counter,
          () {
            store.set(counter, 1);
            store.set(counter, 2);
            store.set(counter, 3);
          },
          3,
        );
      });

      test('fails for wrong count', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        expect(
          () => store.expectEmissionCount<int>(
            counter,
            () {
              store.set(counter, 1);
            },
            5,
          ),
          throwsA(isA<TestFailure>()),
        );
      });

      test('passes for zero emissions when no changes', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        store.expectEmissionCount<int>(counter, () {}, 0);
      });

      test('does not count duplicate values as emissions', () {
        final counter = reacton<int>(0, name: 'counter');
        final store = TestReactonStore();
        store.get(counter);
        // Setting the same value should be skipped by equality check
        store.expectEmissionCount<int>(
          counter,
          () {
            store.set(counter, 1);
            store.set(counter, 1); // duplicate, should be skipped
          },
          1,
        );
      });
    });
  });

  // =========================================================================
  // Widget Pump Helpers (ReactonWidgetTester)
  // =========================================================================
  group('Widget Pump Helpers', () {
    testWidgets('pumpReacton wraps widget in ReactonScope', (tester) async {
      final counter = reacton<int>(0, name: 'counter');
      await tester.pumpReacton(
        ReactonBuilder<int>(
          reacton: counter,
          builder: (context, value) => Text(
            'Count: $value',
            textDirection: TextDirection.ltr,
          ),
        ),
      );
      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.byType(ReactonScope), findsOneWidget);
    });

    testWidgets('pumpReacton with overrides applies them', (tester) async {
      final counter = reacton<int>(0, name: 'counter');
      await tester.pumpReacton(
        ReactonBuilder<int>(
          reacton: counter,
          builder: (context, value) => Text(
            'Count: $value',
            textDirection: TextDirection.ltr,
          ),
        ),
        overrides: [ReactonTestOverride(counter, 42)],
      );
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('reactonStore getter retrieves the store', (tester) async {
      final counter = reacton<int>(0, name: 'counter');
      await tester.pumpReacton(
        ReactonBuilder<int>(
          reacton: counter,
          builder: (context, value) => Text(
            'Count: $value',
            textDirection: TextDirection.ltr,
          ),
        ),
      );
      final store = tester.reactonStore;
      expect(store, isA<ReactonStore>());
      expect(store.get(counter), equals(0));
    });

    testWidgets('setReactonAndPump updates the value and rebuilds',
        (tester) async {
      final counter = reacton<int>(0, name: 'counter');
      await tester.pumpReacton(
        ReactonBuilder<int>(
          reacton: counter,
          builder: (context, value) => Text(
            'Count: $value',
            textDirection: TextDirection.ltr,
          ),
        ),
      );
      expect(find.text('Count: 0'), findsOneWidget);
      await tester.setReactonAndPump(counter, 10);
      expect(find.text('Count: 10'), findsOneWidget);
    });

    testWidgets('updateReactonAndPump updates via updater function',
        (tester) async {
      final counter = reacton<int>(5, name: 'counter');
      await tester.pumpReacton(
        ReactonBuilder<int>(
          reacton: counter,
          builder: (context, value) => Text(
            'Count: $value',
            textDirection: TextDirection.ltr,
          ),
        ),
      );
      expect(find.text('Count: 5'), findsOneWidget);
      await tester.updateReactonAndPump(counter, (v) => v + 10);
      expect(find.text('Count: 15'), findsOneWidget);
    });

    testWidgets('pumpReacton with custom store uses the provided store',
        (tester) async {
      final counter = reacton<int>(0, name: 'counter');
      final customStore = TestReactonStore();
      customStore.set(counter, 77);

      await tester.pumpReacton(
        ReactonBuilder<int>(
          reacton: counter,
          builder: (context, value) => Text(
            'Count: $value',
            textDirection: TextDirection.ltr,
          ),
        ),
        store: customStore,
      );
      expect(find.text('Count: 77'), findsOneWidget);
    });

    testWidgets('multiple setReactonAndPump calls update correctly',
        (tester) async {
      final counter = reacton<int>(0, name: 'counter');
      await tester.pumpReacton(
        ReactonBuilder<int>(
          reacton: counter,
          builder: (context, value) => Text(
            'Count: $value',
            textDirection: TextDirection.ltr,
          ),
        ),
      );
      await tester.setReactonAndPump(counter, 1);
      expect(find.text('Count: 1'), findsOneWidget);
      await tester.setReactonAndPump(counter, 2);
      expect(find.text('Count: 2'), findsOneWidget);
      await tester.setReactonAndPump(counter, 3);
      expect(find.text('Count: 3'), findsOneWidget);
    });
  });

  // =========================================================================
  // Integration tests combining multiple utilities
  // =========================================================================
  group('Integration', () {
    test('MockReacton tracks writes made through TestReactonStore', () {
      final counter = reacton<int>(0, name: 'counter');
      final mock = MockReacton<int>(counter, initialValue: 0);
      final store = TestReactonStore();

      // Subscribe to the store and record writes in the mock
      store.subscribe(counter, (value) {
        mock.recordWrite(value);
      });

      store.set(counter, 10);
      store.set(counter, 20);

      expect(mock.writeCount, equals(2));
      expect(mock.valueHistory, equals([0, 10, 20]));
    });

    test('EffectTracker works with store registerEffect', () {
      final counter = reacton<int>(0, name: 'counter');
      final tracker = EffectTracker();
      final store = TestReactonStore();

      final dispose = store.registerEffect(createEffect((read) {
        tracker.record('counterEffect');
        read(counter);
        return null;
      }));

      // Initial run on registration
      expect(tracker.wasCalled('counterEffect'), isTrue);
      expect(tracker.callCount('counterEffect'), equals(1));

      store.set(counter, 5);
      expect(tracker.callCount('counterEffect'), equals(2));

      dispose();
    });

    test('overrides with graph assertions', () {
      final asyncR =
          reacton<AsyncValue<String>>(const AsyncLoading(), name: 'async');
      final store = TestReactonStore(
        overrides: [AsyncReactonTestOverride.data(asyncR, 'overridden')],
      );
      store.expectData<String>(asyncR, 'overridden');
    });

    test('collectValues works with computed reactons', () {
      final counter = reacton<int>(0, name: 'counter');
      final doubled = computed<int>(
        (read) => read(counter) * 2,
        name: 'doubled',
      );
      final store = TestReactonStore();

      // Initialize both
      store.get(doubled);

      final values = store.collectValues<int>(doubled, () {
        store.set(counter, 1);
        store.set(counter, 2);
        store.set(counter, 3);
      });
      expect(values, equals([2, 4, 6]));
    });
  });
}
