# Authentication

A state machine pattern for authentication flow: LoggedOut, Authenticating, Authenticated, and Error states. Demonstrates `stateMachine()` with typed states, events, async transitions, guard functions, and transition effects.

## State Machine Definition

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- States and Events ---

enum AuthState { loggedOut, authenticating, authenticated, error }
enum AuthEvent { login, logout, tokenExpired, retry }

// --- Auth Data ---

class AuthUser {
  final String id;
  final String email;
  final String displayName;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });
}

// --- Reactons ---

/// Holds the currently authenticated user (null when logged out).
final authUserReacton = reacton<AuthUser?>(null, name: 'authUser');

/// Holds the last authentication error message.
final authErrorReacton = reacton<String?>(null, name: 'authError');

/// The authentication state machine.
final authMachine = stateMachine<AuthState, AuthEvent>(
  initial: AuthState.loggedOut,
  transitions: {
    AuthState.loggedOut: {
      AuthEvent.login: (ctx) async {
        // Transition to authenticating state happens immediately
        // The async work determines the final state
        return AuthState.authenticating;
      },
    },
    AuthState.authenticating: {
      // No events handled while authenticating
      // The login flow completes asynchronously
    },
    AuthState.authenticated: {
      AuthEvent.logout: (ctx) => AuthState.loggedOut,
      AuthEvent.tokenExpired: (ctx) => AuthState.loggedOut,
    },
    AuthState.error: {
      AuthEvent.retry: (ctx) => AuthState.authenticating,
      AuthEvent.logout: (ctx) => AuthState.loggedOut,
    },
  },
  onTransition: (previousState, newState) {
    // Side effect: log transitions for debugging
    debugPrint('Auth: $previousState -> $newState');
  },
  name: 'auth',
);

/// Derived: whether the user is currently logged in.
final isLoggedInReacton = computed(
  (read) => read(authUserReacton) != null,
  name: 'isLoggedIn',
);
```

## Authentication Service

```dart
/// Simulates an authentication API.
class AuthService {
  /// Attempt to log in. Returns a user on success, throws on failure.
  static Future<AuthUser> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'test@example.com' && password == 'password') {
      return AuthUser(
        id: 'user-1',
        email: email,
        displayName: 'Test User',
      );
    }

    throw Exception('Invalid email or password');
  }
}
```

## Login Flow with Effects

```dart
/// Performs the actual login and updates the state machine + user reacton.
Future<void> performLogin(
  ReactonStore store,
  String email,
  String password,
) async {
  // Set machine to authenticating
  store.set(authMachine.stateReacton, AuthState.authenticating);
  store.set(authErrorReacton, null);

  try {
    final user = await AuthService.login(email, password);

    // Success: set user and transition to authenticated
    store.set(authUserReacton, user);
    store.set(authMachine.stateReacton, AuthState.authenticated);
  } catch (e) {
    // Failure: clear user and transition to error
    store.set(authUserReacton, null);
    store.set(authErrorReacton, e.toString());
    store.set(authMachine.stateReacton, AuthState.error);
  }
}

/// Log out: clear user data and transition to logged out.
void performLogout(ReactonStore store) {
  store.batch(() {
    store.set(authUserReacton, null);
    store.set(authErrorReacton, null);
    store.set(authMachine.stateReacton, AuthState.loggedOut);
  });
}
```

## UI Implementation

```dart
void main() => runApp(ReactonScope(child: const AuthApp()));

class AuthApp extends StatelessWidget {
  const AuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

/// Routes to the correct page based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch(authMachine.stateReacton);

    return switch (authState) {
      AuthState.loggedOut => const LoginPage(),
      AuthState.authenticating => const LoadingPage(),
      AuthState.authenticated => const HomePage(),
      AuthState.error => const ErrorPage(),
    };
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                performLogin(
                  context.reactonStore,
                  _emailController.text,
                  _passwordController.text,
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch(authUserReacton);

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.displayName ?? "User"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => performLogout(context.reactonStore),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('Logged in as ${user?.email}'),
          ],
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final error = context.watch(authErrorReacton);

    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error ?? 'An error occurred'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => performLogout(context.reactonStore),
                  child: const Text('Back to Login'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () {
                    // Retry would need the credentials again
                    performLogout(context.reactonStore);
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Key Concepts

### State Machine Pattern

The `stateMachine()` function creates a state machine with typed states and events. Each state defines which events it can handle and what the resulting state should be:

```dart
transitions: {
  AuthState.loggedOut: {
    AuthEvent.login: (ctx) async => AuthState.authenticating,
  },
  AuthState.authenticated: {
    AuthEvent.logout: (ctx) => AuthState.loggedOut,
    AuthEvent.tokenExpired: (ctx) => AuthState.loggedOut,
  },
}
```

### Transition Effects

The `onTransition` callback runs after every state change, useful for logging, analytics, or triggering additional side effects:

```dart
onTransition: (previousState, newState) {
  debugPrint('Auth: $previousState -> $newState');
},
```

### Exhaustive Pattern Matching

Dart's `switch` expression with `enum` ensures every state is handled in the UI:

```dart
return switch (authState) {
  AuthState.loggedOut => const LoginPage(),
  AuthState.authenticating => const LoadingPage(),
  AuthState.authenticated => const HomePage(),
  AuthState.error => const ErrorPage(),
};
```

If you add a new state to the enum, the compiler forces you to handle it.

### Batch Updates

Use `store.batch()` to update multiple reactons atomically. During logout, we clear the user and error at the same time:

```dart
store.batch(() {
  store.set(authUserReacton, null);
  store.set(authErrorReacton, null);
  store.set(authMachine.stateReacton, AuthState.loggedOut);
});
```

## What's Next

- [Form Validation](./form-validation) -- Build a complex login form with per-field validation
- [Todo App](./todo-app) -- CRUD operations and filtering
- [Offline-First](./offline-first) -- Persistence and optimistic updates
