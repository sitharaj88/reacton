import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import '../../shared/state.dart';

// ============================================================================
// Auth Page
//
// Demonstrates:
//   - stateMachine<S, E>()   typed state + event machine
//   - store.send()           dispatch events to trigger transitions
//   - store.canSend()        check if an event is valid in current state
//   - store.machineState()   read the current machine state
//   - ReactonListener        run side effects (snackbar) on state change
//   - Async transitions      login simulates network delay
// ============================================================================

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        centerTitle: false,
      ),
      // ReactonListener fires side effects without rebuilding.
      // Here we show a SnackBar whenever the auth state changes.
      body: ReactonListener<AuthState>(
        reacton: authMachine.stateReacton,
        listener: (context, state) {
          final message = switch (state) {
            AuthState.authenticated => 'Successfully logged in!',
            AuthState.loggedOut => 'Logged out.',
            AuthState.error => 'Session expired. Please log in again.',
            AuthState.loading => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Text(
                'State Machine',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'stateMachine() defines typed states and events with explicit '
                'transitions. Only valid events can be sent in each state, '
                'making complex flows predictable.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // --- State visualisation ---
              ReactonBuilder<AuthState>(
                reacton: authMachine.stateReacton,
                builder: (context, state) {
                  return Column(
                    children: [
                      // Current state card
                      _StateCard(state: state),
                      const SizedBox(height: 24),

                      // Transition diagram
                      _TransitionDiagram(currentState: state),
                      const SizedBox(height: 24),

                      // Action buttons
                      _ActionButtons(currentState: state),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current state display
// ---------------------------------------------------------------------------

class _StateCard extends StatelessWidget {
  final AuthState state;
  const _StateCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = switch (state) {
      AuthState.loggedOut => (Icons.lock_outline, Colors.grey, 'Logged Out'),
      AuthState.loading => (Icons.hourglass_top, Colors.amber, 'Loading...'),
      AuthState.authenticated => (Icons.verified_user, Colors.green, 'Authenticated'),
      AuthState.error => (Icons.error_outline, Colors.red, 'Error'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current State',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transition diagram
// ---------------------------------------------------------------------------

class _TransitionDiagram extends StatelessWidget {
  final AuthState currentState;
  const _TransitionDiagram({required this.currentState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'State Transitions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final state in AuthState.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state == currentState
                            ? colors.primary
                            : colors.outlineVariant,
                        border: Border.all(
                          color: state == currentState
                              ? colors.primary
                              : colors.outlineVariant,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      state.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: state == currentState
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: state == currentState
                            ? colors.primary
                            : colors.onSurface,
                      ),
                    ),
                    if (state == currentState) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_back, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'current',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons -- uses canSend() to enable/disable
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  final AuthState currentState;
  const _ActionButtons({required this.currentState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.reactonStore;

    final canLogin = store.canSend(authMachine, AuthEvent.login);
    final canLogout = store.canSend(authMachine, AuthEvent.logout);
    final canExpire = store.canSend(authMachine, AuthEvent.tokenExpired);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'canSend() checks whether an event is valid in the current state. '
              'Disabled buttons indicate invalid transitions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: canLogin ? () => _sendLogin(context) : null,
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
                FilledButton.tonalIcon(
                  onPressed: canLogout ? () => _sendLogout(context) : null,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
                OutlinedButton.icon(
                  onPressed: canExpire ? () => _sendTokenExpired(context) : null,
                  icon: const Icon(Icons.timer_off),
                  label: const Text('Expire Token'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendLogin(BuildContext context) async {
    final store = context.reactonStore;
    try {
      // First send transitions loggedOut -> loading
      await store.send(authMachine, AuthEvent.login);
      // Second send transitions loading -> authenticated (with async delay)
      await store.send(authMachine, AuthEvent.login);
    } catch (e) {
      // Transition error -- the machine is already in a valid state,
      // so we can safely ignore or log this.
    }
  }

  Future<void> _sendLogout(BuildContext context) async {
    final store = context.reactonStore;
    try {
      await store.send(authMachine, AuthEvent.logout);
    } catch (_) {}
  }

  Future<void> _sendTokenExpired(BuildContext context) async {
    final store = context.reactonStore;
    try {
      await store.send(authMachine, AuthEvent.tokenExpired);
    } catch (_) {}
  }
}
