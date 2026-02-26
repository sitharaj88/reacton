import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  // =========================================================================
  // OptimisticUpdate
  // =========================================================================
  group('OptimisticUpdate', () {
    test('applies optimistic value immediately', () async {
      final counter = reacton(0, name: 'opt_immediate');
      final store = ReactonStore();

      final update = OptimisticUpdate<int>(store, counter);

      // Start the mutation but don't await yet
      final future = update.apply(
        optimisticValue: 42,
        mutation: () async {
          // At this point the optimistic value should already be set
          expect(store.get(counter), 42);
          return 100;
        },
      );

      // The optimistic value should be applied synchronously
      expect(store.get(counter), 42);

      await future;
    });

    test('successful mutation keeps the final value', () async {
      final counter = reacton(0, name: 'opt_success');
      final store = ReactonStore();

      final result = await store.optimistic(
        reacton: counter,
        optimisticValue: 42,
        mutation: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 100;
        },
      );

      expect(result, 100);
      expect(store.get(counter), 100);
    });

    test('failed mutation rolls back to original value', () async {
      final counter = reacton(5, name: 'opt_rollback');
      final store = ReactonStore();

      try {
        await store.optimistic(
          reacton: counter,
          optimisticValue: 42,
          mutation: () async {
            throw Exception('Network error');
          },
        );
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      // Should be rolled back to the original value
      expect(store.get(counter), 5);
    });

    test('onRollback callback invoked on failure', () async {
      final counter = reacton(10, name: 'opt_onRollback');
      final store = ReactonStore();
      Object? capturedError;

      try {
        await store.optimistic(
          reacton: counter,
          optimisticValue: 99,
          mutation: () async {
            throw StateError('server down');
          },
          onRollback: (error) {
            capturedError = error;
          },
        );
        fail('Should have thrown');
      } catch (_) {
        // Expected
      }

      expect(capturedError, isA<StateError>());
      expect((capturedError as StateError).message, 'server down');
      expect(store.get(counter), 10);
    });

    test('onRollback not called on success', () async {
      final counter = reacton(0, name: 'opt_no_rollback');
      final store = ReactonStore();
      var rollbackCalled = false;

      await store.optimistic(
        reacton: counter,
        optimisticValue: 42,
        mutation: () async => 100,
        onRollback: (_) => rollbackCalled = true,
      );

      expect(rollbackCalled, isFalse);
      expect(store.get(counter), 100);
    });

    test('error is rethrown after rollback', () async {
      final counter = reacton(0, name: 'opt_rethrow');
      final store = ReactonStore();

      expect(
        () => store.optimistic(
          reacton: counter,
          optimisticValue: 42,
          mutation: () async {
            throw ArgumentError('bad input');
          },
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('subscribers observe optimistic value during mutation', () async {
      final counter = reacton(0, name: 'opt_subscriber');
      final store = ReactonStore();
      final observedValues = <int>[];

      store.subscribe(counter, (value) {
        observedValues.add(value);
      });

      await store.optimistic(
        reacton: counter,
        optimisticValue: 42,
        mutation: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 100;
        },
      );

      // Should observe: optimistic (42), then final (100)
      expect(observedValues, contains(42));
      expect(observedValues, contains(100));
      expect(store.get(counter), 100);
    });

    test('subscribers observe rollback value on failure', () async {
      final counter = reacton(5, name: 'opt_sub_rollback');
      final store = ReactonStore();
      final observedValues = <int>[];

      store.subscribe(counter, (value) {
        observedValues.add(value);
      });

      try {
        await store.optimistic(
          reacton: counter,
          optimisticValue: 42,
          mutation: () async {
            throw Exception('fail');
          },
        );
      } catch (_) {
        // Expected
      }

      // Should observe: optimistic (42), then rollback (5)
      expect(observedValues, contains(42));
      expect(observedValues, contains(5));
      expect(store.get(counter), 5);
    });

    test('works with non-primitive types', () async {
      final items = reacton(<String>['a', 'b'], name: 'opt_list');
      final store = ReactonStore();

      final result = await store.optimistic(
        reacton: items,
        optimisticValue: ['a', 'b', 'c'],
        mutation: () async {
          return ['a', 'b', 'c', 'd'];
        },
      );

      expect(result, ['a', 'b', 'c', 'd']);
      expect(store.get(items), ['a', 'b', 'c', 'd']);
    });

    test('rollback with non-primitive types', () async {
      final items = reacton(<String>['a', 'b'], name: 'opt_list_rollback');
      final store = ReactonStore();

      try {
        await store.optimistic(
          reacton: items,
          optimisticValue: ['a', 'b', 'c'],
          mutation: () async {
            throw Exception('fail');
          },
        );
      } catch (_) {
        // Expected
      }

      expect(store.get(items), ['a', 'b']);
    });

    test('sequential optimistic updates work correctly', () async {
      final counter = reacton(0, name: 'opt_sequential');
      final store = ReactonStore();

      // First optimistic update succeeds
      await store.optimistic(
        reacton: counter,
        optimisticValue: 10,
        mutation: () async => 10,
      );
      expect(store.get(counter), 10);

      // Second optimistic update succeeds
      await store.optimistic(
        reacton: counter,
        optimisticValue: 20,
        mutation: () async => 25,
      );
      expect(store.get(counter), 25);
    });

    test('optimistic update with null onRollback does not throw on failure', () async {
      final counter = reacton(0, name: 'opt_null_rollback');
      final store = ReactonStore();

      try {
        await store.optimistic(
          reacton: counter,
          optimisticValue: 42,
          mutation: () async {
            throw Exception('error');
          },
          // onRollback is null by default
        );
      } catch (_) {
        // Expected to rethrow
      }

      // Should still roll back without calling onRollback
      expect(store.get(counter), 0);
    });

    test('mutation receives no arguments and returns the final value', () async {
      final counter = reacton(0, name: 'opt_return_val');
      final store = ReactonStore();

      final result = await store.optimistic(
        reacton: counter,
        optimisticValue: 50,
        mutation: () async {
          // Simulate API call
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return 75;
        },
      );

      expect(result, 75);
      expect(store.get(counter), 75);
    });
  });

  // =========================================================================
  // ReactonStoreOptimistic extension
  // =========================================================================
  group('ReactonStoreOptimistic extension', () {
    test('store.optimistic() is available as extension method', () async {
      final counter = reacton(0, name: 'ext_optimistic');
      final store = ReactonStore();

      final result = await store.optimistic(
        reacton: counter,
        optimisticValue: 10,
        mutation: () async => 20,
      );

      expect(result, 20);
      expect(store.get(counter), 20);
    });
  });
}
