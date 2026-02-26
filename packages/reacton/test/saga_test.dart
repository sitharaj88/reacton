import 'dart:async';

import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

// ---------------------------------------------------------------------------
// Event hierarchy for testing
// ---------------------------------------------------------------------------

abstract class TestEvent {}

class IncrementEvent extends TestEvent {
  final int amount;
  IncrementEvent([this.amount = 1]);
}

class DecrementEvent extends TestEvent {
  final int amount;
  DecrementEvent([this.amount = 1]);
}

class ResetEvent extends TestEvent {}

class SlowEvent extends TestEvent {
  final Duration delay;
  SlowEvent(this.delay);
}

class PingEvent extends TestEvent {}

class PongEvent extends TestEvent {}

void main() {
  group('Saga', () {
    late ReactonStore store;
    late WritableReacton<int> counter;

    setUp(() {
      store = ReactonStore();
      counter = reacton(0, name: 'counter');
      // Initialize the reacton in the store.
      store.get(counter);
    });

    tearDown(() {
      store.cancelAllSagas();
      store.dispose();
    });

    // -----------------------------------------------------------------------
    // Saga creation with builder
    // -----------------------------------------------------------------------

    group('creation', () {
      test('saga() factory returns a Saga with correct name', () {
        final s = saga<TestEvent>(
          name: 'testSaga',
          builder: (on) {},
        );
        expect(s.name, 'testSaga');
        expect(s.toString(), contains('testSaga'));
      });

      test('saga() without name auto-generates from type parameter', () {
        final s = saga<TestEvent>(builder: (on) {});
        expect(s.name, 'saga<TestEvent>');
      });

      test('registrations are lazily built and cached', () {
        var buildCount = 0;
        final s = saga<TestEvent>(
          name: 'lazy',
          builder: (on) {
            buildCount++;
            on.onEvery<IncrementEvent>((ctx, event) async {});
          },
        );
        expect(buildCount, 0);
        final regs = s.registrations;
        expect(buildCount, 1);
        expect(regs.length, 1);
        // Second access should not rebuild.
        final regs2 = s.registrations;
        expect(buildCount, 1);
        expect(identical(regs, regs2), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // runSaga starts the saga
    // -----------------------------------------------------------------------

    group('runSaga', () {
      test('returns a running SagaTask', () {
        final s = saga<TestEvent>(
          name: 'run',
          builder: (on) {},
        );
        final task = store.runSaga(s);
        expect(task.isRunning, isTrue);
        expect(task.name, 'run');
      });

      test('throws StateError if saga is already running', () {
        final s = saga<TestEvent>(
          name: 'dup',
          builder: (on) {},
        );
        store.runSaga(s);
        expect(
          () => store.runSaga(s),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already running'),
          )),
        );
      });
    });

    // -----------------------------------------------------------------------
    // dispatch sends events
    // -----------------------------------------------------------------------

    group('dispatch', () {
      test('throws StateError if saga is not running', () {
        final s = saga<TestEvent>(
          name: 'notRunning',
          builder: (on) {},
        );
        expect(
          () => store.dispatch(s, IncrementEvent()),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not running'),
          )),
        );
      });

      test('sends events to running saga handlers', () async {
        final received = <TestEvent>[];
        final s = saga<TestEvent>(
          name: 'dispatch',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              received.add(event);
            });
          },
        );
        store.runSaga(s);
        store.dispatch(s, IncrementEvent(5));
        // Allow the async handler to complete.
        await Future<void>.delayed(Duration.zero);
        expect(received.length, 1);
        expect((received[0] as IncrementEvent).amount, 5);
      });
    });

    // -----------------------------------------------------------------------
    // on() handler receives events (takeOnce)
    // -----------------------------------------------------------------------

    group('on() handler (takeOnce)', () {
      test('handles only the first matching event then stops', () async {
        final values = <int>[];
        final s = saga<TestEvent>(
          name: 'once',
          builder: (on) {
            on.on<IncrementEvent>((ctx, event) async {
              values.add(event.amount);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(1));
        await Future<void>.delayed(Duration.zero);
        store.dispatch(s, IncrementEvent(2));
        await Future<void>.delayed(Duration.zero);
        store.dispatch(s, IncrementEvent(3));
        await Future<void>.delayed(Duration.zero);

        expect(values, [1]);
      });
    });

    // -----------------------------------------------------------------------
    // onEvery() handles all events concurrently
    // -----------------------------------------------------------------------

    group('onEvery() handler (takeEvery)', () {
      test('handles every occurrence concurrently', () async {
        final values = <int>[];
        final s = saga<TestEvent>(
          name: 'every',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              values.add(event.amount);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(1));
        store.dispatch(s, IncrementEvent(2));
        store.dispatch(s, IncrementEvent(3));
        await Future<void>.delayed(Duration.zero);

        expect(values, [1, 2, 3]);
      });

      test('concurrent handlers run in parallel', () async {
        final log = <String>[];
        final completer1 = Completer<void>();
        final completer2 = Completer<void>();
        final s = saga<TestEvent>(
          name: 'parallel',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              log.add('start-${event.amount}');
              if (event.amount == 1) {
                await completer1.future;
              } else {
                await completer2.future;
              }
              log.add('end-${event.amount}');
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(1));
        store.dispatch(s, IncrementEvent(2));
        await Future<void>.delayed(Duration.zero);

        // Both handlers should have started.
        expect(log, contains('start-1'));
        expect(log, contains('start-2'));

        // Complete second before first -- proves parallel execution.
        completer2.complete();
        await Future<void>.delayed(Duration.zero);
        expect(log, contains('end-2'));
        expect(log, isNot(contains('end-1')));

        completer1.complete();
        await Future<void>.delayed(Duration.zero);
        expect(log, contains('end-1'));
      });
    });

    // -----------------------------------------------------------------------
    // onLatest() cancels previous, runs latest
    // -----------------------------------------------------------------------

    group('onLatest() handler (takeLatest)', () {
      test('cancels previous handler when new event arrives', () async {
        final values = <int>[];
        final s = saga<TestEvent>(
          name: 'latest',
          builder: (on) {
            on.onLatest<IncrementEvent>((ctx, event) async {
              await ctx.delay(const Duration(milliseconds: 50));
              values.add(event.amount);
            });
          },
        );
        store.runSaga(s);

        // Dispatch two events in rapid succession.
        store.dispatch(s, IncrementEvent(1));
        await Future<void>.delayed(Duration.zero);
        store.dispatch(s, IncrementEvent(2));

        // Wait for the latest handler to complete.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Only the latest event should have succeeded.
        expect(values, [2]);
      });
    });

    // -----------------------------------------------------------------------
    // onLeading() ignores new while running
    // -----------------------------------------------------------------------

    group('onLeading() handler (takeLeading)', () {
      test('ignores new events while a handler is running', () async {
        final values = <int>[];
        final completer = Completer<void>();
        final s = saga<TestEvent>(
          name: 'leading',
          builder: (on) {
            on.onLeading<IncrementEvent>((ctx, event) async {
              values.add(event.amount);
              await completer.future;
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(1));
        await Future<void>.delayed(Duration.zero);
        store.dispatch(s, IncrementEvent(2));
        await Future<void>.delayed(Duration.zero);
        store.dispatch(s, IncrementEvent(3));
        await Future<void>.delayed(Duration.zero);

        // Only the first event should have been handled.
        expect(values, [1]);

        completer.complete();
        await Future<void>.delayed(Duration.zero);
        // Still only one -- the others were dropped.
        expect(values, [1]);
      });

      test('accepts new events after handler completes', () async {
        final values = <int>[];
        var handlerCount = 0;
        final s = saga<TestEvent>(
          name: 'leadingResume',
          builder: (on) {
            on.onLeading<IncrementEvent>((ctx, event) async {
              handlerCount++;
              values.add(event.amount);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(1));
        await Future<void>.delayed(Duration.zero);
        // After first handler completes, dispatch another.
        store.dispatch(s, IncrementEvent(2));
        await Future<void>.delayed(Duration.zero);

        expect(handlerCount, 2);
        expect(values, [1, 2]);
      });
    });

    // -----------------------------------------------------------------------
    // SagaContext.put() writes to store
    // -----------------------------------------------------------------------

    group('SagaContext.put()', () {
      test('writes a value to a store reacton', () async {
        final s = saga<TestEvent>(
          name: 'put',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              final current = ctx.select(counter);
              ctx.put(counter, current + event.amount);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(5));
        await Future<void>.delayed(Duration.zero);

        expect(store.get(counter), 5);
      });
    });

    // -----------------------------------------------------------------------
    // SagaContext.select() reads from store
    // -----------------------------------------------------------------------

    group('SagaContext.select()', () {
      test('reads the current value of a reacton from the store', () async {
        store.set(counter, 42);
        int? selectedValue;

        final s = saga<TestEvent>(
          name: 'select',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              selectedValue = ctx.select(counter);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(Duration.zero);

        expect(selectedValue, 42);
      });
    });

    // -----------------------------------------------------------------------
    // SagaContext.call() executes async function
    // -----------------------------------------------------------------------

    group('SagaContext.call()', () {
      test('executes an async function and returns its result', () async {
        final s = saga<TestEvent>(
          name: 'call',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              final result = await ctx.call(() async {
                return event.amount * 10;
              });
              ctx.put(counter, result);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(3));
        await Future<void>.delayed(Duration.zero);

        expect(store.get(counter), 30);
      });

      test('propagates errors from async function', () async {
        Object? caughtError;
        final s = saga<TestEvent>(
          name: 'callError',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              try {
                await ctx.call(() async {
                  throw StateError('call failed');
                });
              } catch (e) {
                caughtError = e;
              }
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(Duration.zero);

        expect(caughtError, isA<StateError>());
      });
    });

    // -----------------------------------------------------------------------
    // SagaContext.delay() waits
    // -----------------------------------------------------------------------

    group('SagaContext.delay()', () {
      test('suspends the saga for the given duration', () async {
        final timestamps = <int>[];
        final s = saga<TestEvent>(
          name: 'delay',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              timestamps.add(DateTime.now().millisecondsSinceEpoch);
              await ctx.delay(const Duration(milliseconds: 50));
              timestamps.add(DateTime.now().millisecondsSinceEpoch);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(timestamps.length, 2);
        final elapsed = timestamps[1] - timestamps[0];
        expect(elapsed, greaterThanOrEqualTo(40));
      });
    });

    // -----------------------------------------------------------------------
    // SagaContext.fork() creates child task
    // -----------------------------------------------------------------------

    group('SagaContext.fork()', () {
      test('creates a child task that runs concurrently', () async {
        final log = <String>[];
        final s = saga<TestEvent>(
          name: 'fork',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              log.add('parent-start');

              final childTask = ctx.fork((childCtx, [_]) async {
                log.add('child-start');
                await childCtx.delay(const Duration(milliseconds: 10));
                log.add('child-end');
              }, name: 'childTask');

              log.add('parent-after-fork');
              expect(childTask.isRunning, isTrue);
              expect(childTask.name, 'childTask');
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(log, contains('parent-start'));
        expect(log, contains('parent-after-fork'));
        expect(log, contains('child-start'));
        expect(log, contains('child-end'));

        // Parent should have finished before child.
        final parentAfterForkIdx = log.indexOf('parent-after-fork');
        final childEndIdx = log.indexOf('child-end');
        expect(parentAfterForkIdx, lessThan(childEndIdx));
      });
    });

    // -----------------------------------------------------------------------
    // SagaContext.race() first wins
    // -----------------------------------------------------------------------

    group('SagaContext.race()', () {
      test('returns the result of the first completing future', () async {
        Map<String, int>? raceResult;
        final s = saga<TestEvent>(
          name: 'race',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              raceResult = await ctx.race<int>({
                'fast': () => Future.delayed(
                      const Duration(milliseconds: 10),
                      () => 1,
                    ),
                'slow': () => Future.delayed(
                      const Duration(milliseconds: 100),
                      () => 2,
                    ),
              });
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(raceResult, isNotNull);
        expect(raceResult!.keys.single, 'fast');
        expect(raceResult!['fast'], 1);
      });
    });

    // -----------------------------------------------------------------------
    // SagaContext.all() waits for all
    // -----------------------------------------------------------------------

    group('SagaContext.all()', () {
      test('waits for all futures to complete and returns results', () async {
        List<int>? allResult;
        final s = saga<TestEvent>(
          name: 'all',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              allResult = await ctx.all<int>([
                () => Future.delayed(
                      const Duration(milliseconds: 10),
                      () => 1,
                    ),
                () => Future.delayed(
                      const Duration(milliseconds: 20),
                      () => 2,
                    ),
                () => Future.delayed(
                      const Duration(milliseconds: 5),
                      () => 3,
                    ),
              ]);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(allResult, [1, 2, 3]);
      });

      test('returns empty list for empty effects', () async {
        List<int>? allResult;
        final s = saga<TestEvent>(
          name: 'allEmpty',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              allResult = await ctx.all<int>([]);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(Duration.zero);

        expect(allResult, <int>[]);
      });

      test('fails when any future throws', () async {
        Object? caughtError;
        final s = saga<TestEvent>(
          name: 'allFail',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              try {
                await ctx.all<int>([
                  () async => 1,
                  () async => throw StateError('boom'),
                  () async => 3,
                ]);
              } catch (e) {
                caughtError = e;
              }
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, PingEvent());
        await Future<void>.delayed(Duration.zero);

        expect(caughtError, isA<StateError>());
      });
    });

    // -----------------------------------------------------------------------
    // Task cancellation cascades to children
    // -----------------------------------------------------------------------

    group('Task cancellation', () {
      test('cancelling parent cascades to all children', () {
        final parent = SagaTask(name: 'parent');
        final child1 = SagaTask(name: 'child1');
        final child2 = SagaTask(name: 'child2');
        final grandchild = SagaTask(name: 'grandchild');

        parent.addChild(child1);
        parent.addChild(child2);
        child1.addChild(grandchild);

        parent.cancel();

        expect(parent.isCancelled, isTrue);
        expect(child1.isCancelled, isTrue);
        expect(child2.isCancelled, isTrue);
        expect(grandchild.isCancelled, isTrue);
      });

      test('cancelling already cancelled task is a no-op', () {
        final task = SagaTask(name: 'idempotent');
        task.cancel();
        expect(task.isCancelled, isTrue);
        // Should not throw.
        task.cancel();
        expect(task.isCancelled, isTrue);
      });

      test('cancelling a completed task is a no-op', () {
        final task = SagaTask(name: 'completed');
        task.complete();
        expect(task.isCompleted, isTrue);
        task.cancel();
        expect(task.isCompleted, isTrue);
        expect(task.isCancelled, isFalse);
      });

      test('task.result future completes on cancel', () async {
        final task = SagaTask(name: 'resultOnCancel');
        var completed = false;
        task.result.then((_) => completed = true);
        task.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(completed, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // cancelSaga() stops a running saga
    // -----------------------------------------------------------------------

    group('cancelSaga()', () {
      test('cancels the root task and stops event handling', () async {
        final values = <int>[];
        final s = saga<TestEvent>(
          name: 'cancelMe',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              values.add(event.amount);
            });
          },
        );
        final task = store.runSaga(s);

        store.dispatch(s, IncrementEvent(1));
        await Future<void>.delayed(Duration.zero);
        expect(values, [1]);

        store.cancelSaga(s);
        expect(task.isCancelled, isTrue);

        // After cancellation, re-running should work.
        store.runSaga(s);
        store.dispatch(s, IncrementEvent(2));
        await Future<void>.delayed(Duration.zero);
        expect(values, [1, 2]);
      });

      test('cancelSaga on non-running saga is safe', () {
        final s = saga<TestEvent>(
          name: 'notRunning',
          builder: (on) {},
        );
        // Should not throw.
        store.cancelSaga(s);
      });
    });

    // -----------------------------------------------------------------------
    // cancelAllSagas() stops everything
    // -----------------------------------------------------------------------

    group('cancelAllSagas()', () {
      test('cancels all running sagas on the store', () async {
        final s1 = saga<TestEvent>(
          name: 'saga1',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {});
          },
        );
        final s2 = saga<TestEvent>(
          name: 'saga2',
          builder: (on) {
            on.onEvery<DecrementEvent>((ctx, event) async {});
          },
        );

        final task1 = store.runSaga(s1);
        final task2 = store.runSaga(s2);

        store.cancelAllSagas();

        expect(task1.isCancelled, isTrue);
        expect(task2.isCancelled, isTrue);
      });

      test('calling cancelAllSagas with no sagas is safe', () {
        // Should not throw.
        store.cancelAllSagas();
      });
    });

    // -----------------------------------------------------------------------
    // SagaCancelledException on cancelled tasks
    // -----------------------------------------------------------------------

    group('SagaCancelledException', () {
      test('has correct default message', () {
        const ex = SagaCancelledException();
        expect(ex.message, 'Saga was cancelled');
        expect(ex.toString(), contains('SagaCancelledException'));
      });

      test('accepts custom message', () {
        const ex = SagaCancelledException('custom');
        expect(ex.message, 'custom');
      });

      test('thrown when put() is called on cancelled task', () async {
        bool putReached = false;
        final s = saga<TestEvent>(
          name: 'cancelledPut',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              // Wait a bit, then the parent cancels this saga.
              await ctx.delay(const Duration(milliseconds: 50));
              putReached = true;
              ctx.put(counter, 99);
            });
          },
        );
        store.runSaga(s);
        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        store.cancelSaga(s);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        // The delay should have thrown SagaCancelledException.
        // The handler should not have reached put().
        expect(putReached, isFalse);
        expect(store.get(counter), 0);
      });

      test('thrown when select() is called on cancelled task', () async {
        bool selectReached = false;
        final s = saga<TestEvent>(
          name: 'cancelledSelect',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              await ctx.delay(const Duration(milliseconds: 50));
              selectReached = true;
              ctx.select(counter);
            });
          },
        );
        store.runSaga(s);
        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        store.cancelSaga(s);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        // The delay threw, so select was never reached.
        expect(selectReached, isFalse);
      });

      test('thrown when delay() is called on cancelled task', () async {
        bool delayCancelled = false;
        final s = saga<TestEvent>(
          name: 'cancelledDelay',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              try {
                await ctx.delay(const Duration(seconds: 10));
              } on SagaCancelledException {
                delayCancelled = true;
              }
            });
          },
        );
        store.runSaga(s);
        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        store.cancelSaga(s);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(delayCancelled, isTrue);
      });

      test('thrown when call() is pending and task is cancelled', () async {
        bool callCancelled = false;
        final s = saga<TestEvent>(
          name: 'cancelledCall',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              try {
                await ctx.call(() => Future.delayed(
                      const Duration(seconds: 10),
                      () => 42,
                    ));
              } on SagaCancelledException {
                callCancelled = true;
              }
            });
          },
        );
        store.runSaga(s);
        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        store.cancelSaga(s);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(callCancelled, isTrue);
      });

      test('thrown when race() is pending and task is cancelled', () async {
        bool raceCancelled = false;
        final s = saga<TestEvent>(
          name: 'cancelledRace',
          builder: (on) {
            on.onEvery<PingEvent>((ctx, event) async {
              try {
                await ctx.race<int>({
                  'a': () => Future.delayed(
                        const Duration(seconds: 10),
                        () => 1,
                      ),
                });
              } on SagaCancelledException {
                raceCancelled = true;
              }
            });
          },
        );
        store.runSaga(s);
        store.dispatch(s, PingEvent());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        store.cancelSaga(s);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(raceCancelled, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Error handling in saga handlers
    // -----------------------------------------------------------------------

    group('error handling', () {
      test('handler error marks task as completed with error', () async {
        // Run inside a custom zone to capture the uncaught error from the
        // handler child task's completer.
        final caughtErrors = <Object>[];
        await runZonedGuarded(() async {
          final s = saga<TestEvent>(
            name: 'errorHandler',
            builder: (on) {
              on.onEvery<PingEvent>((ctx, event) async {
                throw StateError('handler error');
              });
            },
          );
          final rootTask = store.runSaga(s);
          store.dispatch(s, PingEvent());

          // Allow the handler to execute and error out.
          await Future<void>.delayed(Duration.zero);

          // The root task should still be running; only the handler child
          // task failed.
          expect(rootTask.isRunning, isTrue);
        }, (error, stack) {
          caughtErrors.add(error);
        });

        // The handler's StateError should have been caught by the zone.
        expect(caughtErrors, hasLength(1));
        expect(caughtErrors.first, isA<StateError>());
      });

      test('store operations in handler work correctly', () async {
        final s = saga<TestEvent>(
          name: 'integration',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              final val = ctx.select(counter);
              final result = await ctx.call(() async => val + event.amount);
              ctx.put(counter, result);
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(5));
        await Future<void>.delayed(Duration.zero);
        expect(store.get(counter), 5);

        store.dispatch(s, IncrementEvent(3));
        await Future<void>.delayed(Duration.zero);
        expect(store.get(counter), 8);
      });
    });

    // -----------------------------------------------------------------------
    // SagaTask properties
    // -----------------------------------------------------------------------

    group('SagaTask', () {
      test('has unique auto-incrementing id', () {
        final t1 = SagaTask();
        final t2 = SagaTask();
        expect(t1.id, isNot(t2.id));
        expect(t2.id, greaterThan(t1.id));
      });

      test('toString includes name and status', () {
        final task = SagaTask(name: 'myTask');
        expect(task.toString(), contains('myTask'));
        expect(task.toString(), contains('running'));
      });

      test('completeError marks task as completed', () async {
        final task = SagaTask(name: 'errorTask');
        task.completeError(StateError('fail'));
        expect(task.isCompleted, isTrue);
        expect(task.isRunning, isFalse);

        // The result future should complete with an error.
        await expectLater(task.result, throwsA(isA<StateError>()));
      });

      test('complete on already completed task is no-op', () {
        final task = SagaTask();
        task.complete();
        expect(task.isCompleted, isTrue);
        // Should not throw.
        task.complete();
        expect(task.isCompleted, isTrue);
      });

      test('completeError on already completed task is no-op', () {
        final task = SagaTask();
        task.complete();
        // Should not throw.
        task.completeError(StateError('late'));
        expect(task.isCompleted, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Multiple event types in a single saga
    // -----------------------------------------------------------------------

    group('multiple event types', () {
      test('routes different event types to correct handlers', () async {
        final log = <String>[];
        final s = saga<TestEvent>(
          name: 'multi',
          builder: (on) {
            on.onEvery<IncrementEvent>((ctx, event) async {
              log.add('inc:${event.amount}');
            });
            on.onEvery<DecrementEvent>((ctx, event) async {
              log.add('dec:${event.amount}');
            });
            on.on<ResetEvent>((ctx, event) async {
              log.add('reset');
            });
          },
        );
        store.runSaga(s);

        store.dispatch(s, IncrementEvent(1));
        store.dispatch(s, DecrementEvent(2));
        store.dispatch(s, ResetEvent());
        store.dispatch(s, IncrementEvent(3));
        await Future<void>.delayed(Duration.zero);

        expect(log, contains('inc:1'));
        expect(log, contains('dec:2'));
        expect(log, contains('reset'));
        expect(log, contains('inc:3'));
      });
    });
  });
}
