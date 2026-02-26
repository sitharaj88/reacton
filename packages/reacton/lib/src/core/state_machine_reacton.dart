import 'dart:async';

import 'reacton_base.dart';
import 'writable_reacton.dart';

/// Context available during state machine transitions.
class TransitionContext<S> {
  final S currentState;
  final ReactonReader? read; // optional, for reading other reactons

  const TransitionContext(this.currentState, {this.read});
}

/// A transition handler returns the next state (sync or async).
typedef TransitionHandler<S> = FutureOr<S> Function(TransitionContext<S> context);

/// Guard function that determines if a transition should be allowed.
typedef TransitionGuard<S> = bool Function(S currentState);

/// Side effect to run after a transition completes.
typedef TransitionEffect<S> = void Function(S previousState, S newState);

/// A state machine reacton manages typed state transitions.
///
/// Unlike a simple writable reacton, a state machine enforces that
/// state changes only happen through defined transitions, making
/// complex workflows predictable and debuggable.
///
/// ```dart
/// enum AuthState { loggedOut, loading, authenticated, error }
/// enum AuthEvent { login, logout, tokenExpired }
///
/// final authMachine = stateMachine<AuthState, AuthEvent>(
///   initial: AuthState.loggedOut,
///   transitions: {
///     AuthState.loggedOut: {
///       AuthEvent.login: (ctx) async {
///         return AuthState.authenticated;
///       },
///     },
///     AuthState.authenticated: {
///       AuthEvent.logout: (ctx) => AuthState.loggedOut,
///       AuthEvent.tokenExpired: (ctx) => AuthState.loggedOut,
///     },
///   },
///   name: 'auth',
/// );
/// ```
// ignore: must_be_immutable
class StateMachineReacton<S, E> extends ReactonBase<S> {
  final S initial;
  final Map<S, Map<E, TransitionHandler<S>>> transitions;
  final Map<E, TransitionGuard<S>>? guards;
  final TransitionEffect<S>? onTransition;

  // Internal writable reacton that holds the actual state value
  late final WritableReacton<S> _stateReacton;

  /// Whether an async transition is currently in progress.
  bool isTransitioning = false;

  StateMachineReacton({
    required this.initial,
    required this.transitions,
    this.guards,
    this.onTransition,
    String? name,
    ReactonOptions<S>? options,
  }) : super(name: name, options: options) {
    _stateReacton = WritableReacton<S>(
      initial,
      name: name != null ? '${name}_state' : null,
      options: options,
    );
  }

  /// The underlying writable reacton (for store registration).
  WritableReacton<S> get stateReacton => _stateReacton;

  /// Get all valid events for a given state.
  Set<E> validEvents(S state) {
    return transitions[state]?.keys.toSet() ?? {};
  }

  /// Check if an event is valid for a given state.
  bool canHandle(S state, E event) {
    return transitions[state]?.containsKey(event) ?? false;
  }
}

/// Create a state machine reacton with typed states and events.
///
/// ```dart
/// final authMachine = stateMachine<AuthState, AuthEvent>(
///   initial: AuthState.loggedOut,
///   transitions: {
///     AuthState.loggedOut: {
///       AuthEvent.login: (ctx) async => AuthState.authenticated,
///     },
///     AuthState.authenticated: {
///       AuthEvent.logout: (ctx) => AuthState.loggedOut,
///     },
///   },
///   name: 'auth',
/// );
/// ```
StateMachineReacton<S, E> stateMachine<S, E>({
  required S initial,
  required Map<S, Map<E, TransitionHandler<S>>> transitions,
  Map<E, TransitionGuard<S>>? guards,
  TransitionEffect<S>? onTransition,
  String? name,
  ReactonOptions<S>? options,
}) {
  return StateMachineReacton<S, E>(
    initial: initial,
    transitions: transitions,
    guards: guards,
    onTransition: onTransition,
    name: name,
    options: options,
  );
}
