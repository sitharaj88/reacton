import 'package:flutter_reacton/flutter_reacton.dart';

import '../features/todos/todo_model.dart';

// ============================================================================
// SHARED REACTON DEFINITIONS
//
// All reactive state for the showcase app is declared here as top-level
// constants. Reactons are lazily initialised on first access inside a
// ReactonStore, so declaring them at the top level is cheap and idiomatic.
// ============================================================================

// ---------------------------------------------------------------------------
// 1. Counter Feature -- reacton(), computed()
// ---------------------------------------------------------------------------

/// A simple writable integer counter.
final counterReacton = reacton(0, name: 'counter');

/// Derived state: the counter value doubled.
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

/// Derived state: whether the counter is even.
final isEvenReacton = computed(
  (read) => read(counterReacton) % 2 == 0,
  name: 'isEven',
);

/// Derived state: absolute value label.
final counterLabelReacton = computed(
  (read) {
    final count = read(counterReacton);
    if (count == 0) return 'Zero';
    if (count > 0) return 'Positive ($count)';
    return 'Negative ($count)';
  },
  name: 'counterLabel',
);

// ---------------------------------------------------------------------------
// 2. Todos Feature -- reactonList(), computed(), lens()
// ---------------------------------------------------------------------------

/// Observable list of todos with fine-grained collection operations.
final todosReacton = reactonList<Todo>(
  [
    const Todo(id: '1', title: 'Learn Reacton basics', completed: true),
    const Todo(id: '2', title: 'Build a showcase app'),
    const Todo(id: '3', title: 'Master state machines'),
  ],
  name: 'todos',
);

/// Filter mode for the todo list.
final todoFilterReacton = reacton<TodoFilter>(TodoFilter.all, name: 'todoFilter');

/// Derived: filtered list of todos.
final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(todoFilterReacton);
  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.completed).toList(),
    TodoFilter.completed => todos.where((t) => t.completed).toList(),
  };
}, name: 'filteredTodos');

/// Derived: total count.
final todoCountReacton = computed(
  (read) => read(todosReacton).length,
  name: 'todoCount',
);

/// Derived: completed count.
final completedCountReacton = computed(
  (read) => read(todosReacton).where((t) => t.completed).length,
  name: 'completedCount',
);

/// Derived: remaining (active) count.
final remainingCountReacton = computed(
  (read) => read(todosReacton).where((t) => !t.completed).length,
  name: 'remainingCount',
);

enum TodoFilter { all, active, completed }

// ---------------------------------------------------------------------------
// 3. Auth Feature -- stateMachine()
// ---------------------------------------------------------------------------

enum AuthState { loggedOut, loading, authenticated, error }

enum AuthEvent { login, logout, tokenExpired }

/// A state machine that models a typical authentication flow.
/// Transitions are guarded: login only from loggedOut, logout only when
/// authenticated, etc.
final authMachine = stateMachine<AuthState, AuthEvent>(
  initial: AuthState.loggedOut,
  transitions: {
    AuthState.loggedOut: {
      // Simulate an async login -- transitions through "loading" then
      // resolves to "authenticated" after a short delay.
      AuthEvent.login: (ctx) async {
        return AuthState.loading;
      },
    },
    AuthState.loading: {
      // After the loading state we transition to authenticated.
      // (In practice the UI will send this event after the async work.)
      AuthEvent.login: (ctx) async {
        // Simulate network latency
        await Future<void>.delayed(const Duration(seconds: 2));
        return AuthState.authenticated;
      },
    },
    AuthState.authenticated: {
      AuthEvent.logout: (ctx) => AuthState.loggedOut,
      AuthEvent.tokenExpired: (ctx) => AuthState.error,
    },
    AuthState.error: {
      AuthEvent.login: (ctx) => AuthState.loading,
      AuthEvent.logout: (ctx) => AuthState.loggedOut,
    },
  },
  name: 'auth',
);

// ---------------------------------------------------------------------------
// 4. Registration Form Feature -- reactonField(), reactonForm(), validators
// ---------------------------------------------------------------------------

final usernameField = reactonField<String>(
  '',
  validators: [required(), minLength(3)],
  name: 'username',
);

final emailField = reactonField<String>(
  '',
  validators: [required(), email()],
  name: 'email',
);

final passwordField = reactonField<String>(
  '',
  validators: [required(), minLength(8)],
  name: 'password',
);

final confirmPasswordField = reactonField<String>(
  '',
  validators: [required()],
  name: 'confirmPassword',
);

final registrationForm = reactonForm(
  fields: {
    'username': usernameField,
    'email': emailField,
    'password': passwordField,
    'confirmPassword': confirmPasswordField,
  },
  name: 'registrationForm',
);

// ---------------------------------------------------------------------------
// 5. Time Travel Feature -- enableHistory()
// ---------------------------------------------------------------------------

/// A simple numeric value whose history we will track.
final timeTravelCounterReacton = reacton(0, name: 'timeTravelCounter');

// ---------------------------------------------------------------------------
// 6. Dashboard Feature -- family(), selector(), batch()
// ---------------------------------------------------------------------------

/// A family of reactons keyed by category name.
/// Each category holds a numeric value that can be independently updated.
final categoryValueFamily = family<int, String>(
  (category) => reacton(0, name: 'category_$category'),
);

/// The list of dashboard categories.
const dashboardCategories = ['Sales', 'Users', 'Orders', 'Revenue'];

/// Selector: extract just the "Sales" value from a user profile reacton.
final userProfileReacton = reacton<Map<String, dynamic>>(
  {
    'name': 'Jane Doe',
    'role': 'Admin',
    'notifications': 3,
  },
  name: 'userProfile',
);

final userNameSelector = selector<Map<String, dynamic>, String>(
  userProfileReacton,
  (profile) => profile['name'] as String,
  name: 'userName',
);

final notificationCountSelector = selector<Map<String, dynamic>, int>(
  userProfileReacton,
  (profile) => profile['notifications'] as int,
  name: 'notificationCount',
);

/// Computed chain: total across all dashboard categories.
final dashboardTotalReacton = computed((read) {
  var total = 0;
  for (final cat in dashboardCategories) {
    total += read(categoryValueFamily(cat));
  }
  return total;
}, name: 'dashboardTotal');

/// Computed chain: percentage contribution of each category.
final categoryPercentagesReacton = computed((read) {
  final total = read(dashboardTotalReacton);
  if (total == 0) return <String, double>{};
  final result = <String, double>{};
  for (final cat in dashboardCategories) {
    final value = read(categoryValueFamily(cat));
    result[cat] = (value / total) * 100;
  }
  return result;
}, name: 'categoryPercentages');
