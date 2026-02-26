import 'dart:async';

import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

// ---------------------------------------------------------------------------
// Test enums
// ---------------------------------------------------------------------------

enum TrafficLight { red, yellow, green }

enum TrafficEvent { next, reset }

enum AuthState { loggedOut, loading, authenticated, error }

enum AuthEvent { login, logout, tokenExpired }

enum DoorState { locked, closed, open }

enum DoorEvent { unlock, lock, openDoor, closeDoor }

void main() {
  // =========================================================================
  // StateMachineReacton unit tests (no store)
  // =========================================================================
  group('StateMachineReacton (unit)', () {
    test('creates with initial state and transitions map', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {
          TrafficLight.red: {
            TrafficEvent.next: (ctx) => TrafficLight.green,
          },
          TrafficLight.green: {
            TrafficEvent.next: (ctx) => TrafficLight.yellow,
          },
          TrafficLight.yellow: {
            TrafficEvent.next: (ctx) => TrafficLight.red,
          },
        },
        name: 'traffic',
      );

      expect(machine.initial, TrafficLight.red);
      expect(machine.ref.debugName, 'traffic');
      expect(machine.transitions, hasLength(3));
    });

    test('stateReacton exposes the underlying writable reacton', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {},
        name: 'traffic',
      );

      expect(machine.stateReacton, isA<WritableReacton<TrafficLight>>());
      expect(machine.stateReacton.initialValue, TrafficLight.red);
      expect(machine.stateReacton.ref.debugName, 'traffic_state');
    });

    test('stateReacton name is null when machine name is null', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {},
      );

      expect(machine.stateReacton.ref.debugName, isNull);
    });

    test('validEvents returns correct events for a state', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {
          TrafficLight.red: {
            TrafficEvent.next: (ctx) => TrafficLight.green,
            TrafficEvent.reset: (ctx) => TrafficLight.red,
          },
          TrafficLight.green: {
            TrafficEvent.next: (ctx) => TrafficLight.yellow,
          },
        },
      );

      expect(
        machine.validEvents(TrafficLight.red),
        equals({TrafficEvent.next, TrafficEvent.reset}),
      );
      expect(
        machine.validEvents(TrafficLight.green),
        equals({TrafficEvent.next}),
      );
    });

    test('validEvents returns empty set for state with no transitions', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {
          TrafficLight.red: {
            TrafficEvent.next: (ctx) => TrafficLight.green,
          },
        },
      );

      expect(machine.validEvents(TrafficLight.yellow), isEmpty);
    });

    test('canHandle returns true for defined transitions', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {
          TrafficLight.red: {
            TrafficEvent.next: (ctx) => TrafficLight.green,
          },
        },
      );

      expect(machine.canHandle(TrafficLight.red, TrafficEvent.next), isTrue);
    });

    test('canHandle returns false for undefined transitions', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {
          TrafficLight.red: {
            TrafficEvent.next: (ctx) => TrafficLight.green,
          },
        },
      );

      expect(machine.canHandle(TrafficLight.red, TrafficEvent.reset), isFalse);
      expect(
          machine.canHandle(TrafficLight.green, TrafficEvent.next), isFalse);
    });

    test('isTransitioning is initially false', () {
      final machine = stateMachine<TrafficLight, TrafficEvent>(
        initial: TrafficLight.red,
        transitions: {},
      );

      expect(machine.isTransitioning, isFalse);
    });
  });

  // =========================================================================
  // StateMachineReacton + ReactonStore integration tests
  // =========================================================================
  group('StateMachine with ReactonStore', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    tearDown(() {
      store.dispose();
    });

    // -----------------------------------------------------------------------
    // Basic transitions
    // -----------------------------------------------------------------------
    group('send()', () {
      test('triggers correct synchronous transitions', () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
            TrafficLight.green: {
              TrafficEvent.next: (ctx) => TrafficLight.yellow,
            },
            TrafficLight.yellow: {
              TrafficEvent.next: (ctx) => TrafficLight.red,
            },
          },
          name: 'traffic',
        );

        // Initial state
        expect(store.machineState(machine), TrafficLight.red);

        // red -> green
        final s1 = await store.send(machine, TrafficEvent.next);
        expect(s1, TrafficLight.green);
        expect(store.machineState(machine), TrafficLight.green);

        // green -> yellow
        final s2 = await store.send(machine, TrafficEvent.next);
        expect(s2, TrafficLight.yellow);
        expect(store.machineState(machine), TrafficLight.yellow);

        // yellow -> red
        final s3 = await store.send(machine, TrafficEvent.next);
        expect(s3, TrafficLight.red);
        expect(store.machineState(machine), TrafficLight.red);
      });

      test('triggers correct async transitions', () async {
        final machine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {
            AuthState.loggedOut: {
              AuthEvent.login: (ctx) async {
                await Future.delayed(const Duration(milliseconds: 10));
                return AuthState.authenticated;
              },
            },
            AuthState.authenticated: {
              AuthEvent.logout: (ctx) => AuthState.loggedOut,
            },
          },
          name: 'auth',
        );

        expect(store.machineState(machine), AuthState.loggedOut);

        final result = await store.send(machine, AuthEvent.login);
        expect(result, AuthState.authenticated);
        expect(store.machineState(machine), AuthState.authenticated);
      });

      test('passes current state in TransitionContext', () async {
        TransitionContext<TrafficLight>? capturedContext;

        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) {
                capturedContext = ctx;
                return TrafficLight.green;
              },
            },
          },
        );

        await store.send(machine, TrafficEvent.next);

        expect(capturedContext, isNotNull);
        expect(capturedContext!.currentState, TrafficLight.red);
      });

      test('returns the new state from send()', () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
        );

        final newState = await store.send(machine, TrafficEvent.next);
        expect(newState, TrafficLight.green);
      });
    });

    // -----------------------------------------------------------------------
    // Invalid events
    // -----------------------------------------------------------------------
    group('invalid event handling', () {
      test('throws StateError when no transition defined for state+event',
          () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
          name: 'traffic',
        );

        expect(
          () => store.send(machine, TrafficEvent.reset),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('No transition defined'),
          )),
        );
      });

      test('throws StateError when current state has no transitions at all',
          () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.yellow,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
          name: 'orphan',
        );

        expect(
          () => store.send(machine, TrafficEvent.next),
          throwsA(isA<StateError>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Guards
    // -----------------------------------------------------------------------
    group('guards', () {
      test('guard returning true allows transition', () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
          guards: {
            TrafficEvent.next: (state) => true,
          },
        );

        final result = await store.send(machine, TrafficEvent.next);
        expect(result, TrafficLight.green);
      });

      test('guard returning false blocks transition with StateError',
          () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
          guards: {
            TrafficEvent.next: (state) => false,
          },
          name: 'guarded',
        );

        expect(
          () => store.send(machine, TrafficEvent.next),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('Guard blocked'), contains('guarded')),
          )),
        );

        // State should not have changed
        expect(store.machineState(machine), TrafficLight.red);
      });

      test('guard receives current state for evaluation', () async {
        TrafficLight? guardReceivedState;

        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
          guards: {
            TrafficEvent.next: (state) {
              guardReceivedState = state;
              return true;
            },
          },
        );

        await store.send(machine, TrafficEvent.next);
        expect(guardReceivedState, TrafficLight.red);
      });

      test('guard for a different event does not interfere', () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
              TrafficEvent.reset: (ctx) => TrafficLight.red,
            },
          },
          guards: {
            // Only guard reset, not next
            TrafficEvent.reset: (state) => false,
          },
        );

        // next should succeed (no guard for it)
        final result = await store.send(machine, TrafficEvent.next);
        expect(result, TrafficLight.green);
      });
    });

    // -----------------------------------------------------------------------
    // onTransition callback
    // -----------------------------------------------------------------------
    group('onTransition callback', () {
      test('invoked after successful transition with old and new state',
          () async {
        final transitionLog = <List<TrafficLight>>[];

        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
            TrafficLight.green: {
              TrafficEvent.next: (ctx) => TrafficLight.yellow,
            },
          },
          onTransition: (prev, next) {
            transitionLog.add([prev, next]);
          },
        );

        await store.send(machine, TrafficEvent.next);
        await store.send(machine, TrafficEvent.next);

        expect(transitionLog, hasLength(2));
        expect(transitionLog[0], [TrafficLight.red, TrafficLight.green]);
        expect(transitionLog[1], [TrafficLight.green, TrafficLight.yellow]);
      });

      test('not invoked when guard blocks transition', () async {
        var transitionCalled = false;

        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
          guards: {
            TrafficEvent.next: (state) => false,
          },
          onTransition: (prev, next) {
            transitionCalled = true;
          },
        );

        expect(
          () => store.send(machine, TrafficEvent.next),
          throwsA(isA<StateError>()),
        );
        expect(transitionCalled, isFalse);
      });

      test('not invoked when transition is undefined', () async {
        var transitionCalled = false;

        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {},
          onTransition: (prev, next) {
            transitionCalled = true;
          },
        );

        expect(
          () => store.send(machine, TrafficEvent.next),
          throwsA(isA<StateError>()),
        );
        expect(transitionCalled, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // machineState()
    // -----------------------------------------------------------------------
    group('machineState()', () {
      test('returns the initial state before any transitions', () {
        final machine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {},
        );

        expect(store.machineState(machine), AuthState.loggedOut);
      });

      test('returns the updated state after a transition', () async {
        final machine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {
            AuthState.loggedOut: {
              AuthEvent.login: (ctx) => AuthState.authenticated,
            },
          },
        );

        await store.send(machine, AuthEvent.login);
        expect(store.machineState(machine), AuthState.authenticated);
      });
    });

    // -----------------------------------------------------------------------
    // canSend()
    // -----------------------------------------------------------------------
    group('canSend()', () {
      test('returns true for valid event in current state', () {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
        );

        // Initialize state
        store.machineState(machine);
        expect(store.canSend(machine, TrafficEvent.next), isTrue);
      });

      test('returns false for invalid event in current state', () {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
        );

        store.machineState(machine);
        expect(store.canSend(machine, TrafficEvent.reset), isFalse);
      });

      test('reflects state changes after transitions', () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
            TrafficLight.green: {
              TrafficEvent.reset: (ctx) => TrafficLight.red,
            },
          },
        );

        expect(store.canSend(machine, TrafficEvent.next), isTrue);
        expect(store.canSend(machine, TrafficEvent.reset), isFalse);

        await store.send(machine, TrafficEvent.next);

        expect(store.canSend(machine, TrafficEvent.next), isFalse);
        expect(store.canSend(machine, TrafficEvent.reset), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // isTransitioning flag during async transitions
    // -----------------------------------------------------------------------
    group('isTransitioning', () {
      test('is true during an async transition and false after', () async {
        final completer = Completer<AuthState>();
        final isTransitioningDuringHandler = <bool>[];

        final machine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {
            AuthState.loggedOut: {
              AuthEvent.login: (ctx) async {
                isTransitioningDuringHandler.add(true); // We know it's set
                return completer.future;
              },
            },
          },
        );

        store.machineState(machine); // initialize

        final future = store.send(machine, AuthEvent.login);

        // During async handler execution, isTransitioning should be true
        expect(machine.isTransitioning, isTrue);

        completer.complete(AuthState.authenticated);
        await future;

        // After completion, isTransitioning should be false
        expect(machine.isTransitioning, isFalse);
      });

      test('is false for synchronous transitions', () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
        );

        await store.send(machine, TrafficEvent.next);
        expect(machine.isTransitioning, isFalse);
      });

      test('is reset to false even if handler throws', () async {
        final machine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {
            AuthState.loggedOut: {
              AuthEvent.login: (ctx) async {
                throw Exception('login failed');
              },
            },
          },
        );

        store.machineState(machine);

        try {
          await store.send(machine, AuthEvent.login);
        } catch (_) {
          // expected
        }

        expect(machine.isTransitioning, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Concurrent transitions
    // -----------------------------------------------------------------------
    group('concurrent transition attempts', () {
      test('throws StateError when sending during an active async transition',
          () async {
        final completer = Completer<AuthState>();

        final machine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {
            AuthState.loggedOut: {
              AuthEvent.login: (ctx) => completer.future,
            },
          },
          name: 'auth',
        );

        store.machineState(machine);

        // Start first transition (it will hang on the completer)
        final firstTransition = store.send(machine, AuthEvent.login);

        // Try to send another event while transitioning
        expect(
          () => store.send(machine, AuthEvent.login),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already transitioning'),
          )),
        );

        // Clean up: complete the first transition
        completer.complete(AuthState.authenticated);
        await firstTransition;
      });

      test('can send after a previous async transition completes', () async {
        final machine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {
            AuthState.loggedOut: {
              AuthEvent.login: (ctx) async {
                await Future.delayed(const Duration(milliseconds: 5));
                return AuthState.authenticated;
              },
            },
            AuthState.authenticated: {
              AuthEvent.logout: (ctx) => AuthState.loggedOut,
            },
          },
        );

        await store.send(machine, AuthEvent.login);
        expect(store.machineState(machine), AuthState.authenticated);

        final result = await store.send(machine, AuthEvent.logout);
        expect(result, AuthState.loggedOut);
      });
    });

    // -----------------------------------------------------------------------
    // Multiple state machines in the same store
    // -----------------------------------------------------------------------
    group('multiple state machines in same store', () {
      test('operate independently', () async {
        final trafficMachine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
          name: 'traffic',
        );

        final authMachine = stateMachine<AuthState, AuthEvent>(
          initial: AuthState.loggedOut,
          transitions: {
            AuthState.loggedOut: {
              AuthEvent.login: (ctx) => AuthState.authenticated,
            },
          },
          name: 'auth',
        );

        // Both machines have independent initial states
        expect(store.machineState(trafficMachine), TrafficLight.red);
        expect(store.machineState(authMachine), AuthState.loggedOut);

        // Transition one machine
        await store.send(trafficMachine, TrafficEvent.next);
        expect(store.machineState(trafficMachine), TrafficLight.green);
        expect(store.machineState(authMachine), AuthState.loggedOut);

        // Transition the other
        await store.send(authMachine, AuthEvent.login);
        expect(store.machineState(trafficMachine), TrafficLight.green);
        expect(store.machineState(authMachine), AuthState.authenticated);
      });
    });

    // -----------------------------------------------------------------------
    // State updates are observable through the store
    // -----------------------------------------------------------------------
    group('store subscription integration', () {
      test('store subscribers are notified of state machine transitions',
          () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.next: (ctx) => TrafficLight.green,
            },
          },
        );

        final notifications = <TrafficLight>[];
        store.subscribe(machine.stateReacton, (state) {
          notifications.add(state);
        });

        // Initialize the state reacton in the store
        store.machineState(machine);

        await store.send(machine, TrafficEvent.next);

        expect(notifications, contains(TrafficLight.green));
      });
    });

    // -----------------------------------------------------------------------
    // Complex multi-step workflow
    // -----------------------------------------------------------------------
    group('complex workflow', () {
      test('door state machine with multiple states and events', () async {
        final machine = stateMachine<DoorState, DoorEvent>(
          initial: DoorState.locked,
          transitions: {
            DoorState.locked: {
              DoorEvent.unlock: (ctx) => DoorState.closed,
            },
            DoorState.closed: {
              DoorEvent.lock: (ctx) => DoorState.locked,
              DoorEvent.openDoor: (ctx) => DoorState.open,
            },
            DoorState.open: {
              DoorEvent.closeDoor: (ctx) => DoorState.closed,
            },
          },
          name: 'door',
        );

        expect(store.machineState(machine), DoorState.locked);

        // Cannot open a locked door
        expect(store.canSend(machine, DoorEvent.openDoor), isFalse);

        // Unlock -> closed
        await store.send(machine, DoorEvent.unlock);
        expect(store.machineState(machine), DoorState.closed);

        // Now can open
        expect(store.canSend(machine, DoorEvent.openDoor), isTrue);
        await store.send(machine, DoorEvent.openDoor);
        expect(store.machineState(machine), DoorState.open);

        // Cannot lock an open door
        expect(store.canSend(machine, DoorEvent.lock), isFalse);

        // Close -> closed
        await store.send(machine, DoorEvent.closeDoor);
        expect(store.machineState(machine), DoorState.closed);

        // Lock -> locked
        await store.send(machine, DoorEvent.lock);
        expect(store.machineState(machine), DoorState.locked);
      });
    });

    // -----------------------------------------------------------------------
    // Transition to same state
    // -----------------------------------------------------------------------
    group('self-transitions', () {
      test('transitioning to the same state works', () async {
        final machine = stateMachine<TrafficLight, TrafficEvent>(
          initial: TrafficLight.red,
          transitions: {
            TrafficLight.red: {
              TrafficEvent.reset: (ctx) => TrafficLight.red,
            },
          },
        );

        final result = await store.send(machine, TrafficEvent.reset);
        expect(result, TrafficLight.red);
        expect(store.machineState(machine), TrafficLight.red);
      });
    });
  });
}
