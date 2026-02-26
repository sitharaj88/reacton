import 'dart:async';

import '../store/store.dart';
import 'state_machine_reacton.dart';

/// Extension on [ReactonStore] for state machine operations.
extension ReactonStoreStateMachine on ReactonStore {
  /// Send an event to a state machine reacton, triggering a transition.
  ///
  /// Returns the new state after the transition completes.
  /// Throws [StateError] if no transition is defined for the current state + event.
  /// Throws [StateError] if a guard blocks the transition.
  /// Throws [StateError] if an async transition is already in progress.
  ///
  /// ```dart
  /// final newState = await store.send(authMachine, AuthEvent.login);
  /// ```
  Future<S> send<S, E>(StateMachineReacton<S, E> machine, E event) async {
    final currentState = get(machine.stateReacton);

    // Check if transition exists
    final stateTransitions = machine.transitions[currentState];
    if (stateTransitions == null || !stateTransitions.containsKey(event)) {
      throw StateError(
        'No transition defined for state "$currentState" + event "$event" '
        'in state machine "${machine.ref}"',
      );
    }

    // Check guard
    final guard = machine.guards?[event];
    if (guard != null && !guard(currentState)) {
      throw StateError(
        'Guard blocked transition for event "$event" '
        'in state "$currentState" of machine "${machine.ref}"',
      );
    }

    // Check for concurrent transitions
    if (machine.isTransitioning) {
      throw StateError(
        'State machine "${machine.ref}" is already transitioning. '
        'Await the previous transition before sending another event.',
      );
    }

    final handler = stateTransitions[event]!;
    final context = TransitionContext<S>(currentState);

    machine.isTransitioning = true;
    try {
      final result = handler(context);
      final S newState;
      if (result is Future<S>) {
        newState = await result;
      } else {
        newState = result;
      }

      set(machine.stateReacton, newState);
      machine.onTransition?.call(currentState, newState);

      return newState;
    } finally {
      machine.isTransitioning = false;
    }
  }

  /// Read the current state of a state machine.
  S machineState<S, E>(StateMachineReacton<S, E> machine) {
    return get(machine.stateReacton);
  }

  /// Check if a state machine can handle an event in its current state.
  bool canSend<S, E>(StateMachineReacton<S, E> machine, E event) {
    final currentState = get(machine.stateReacton);
    return machine.canHandle(currentState, event);
  }
}
