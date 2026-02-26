# Migrating from BLoC

A side-by-side guide for migrating from the BLoC pattern to Reacton. BLoC's event-driven state machines map naturally to Reacton's `stateMachine()`, while simpler Cubit patterns map to `reacton()` + `computed()`.

## Concept Mapping

| BLoC | Reacton | Notes |
|------|---------|-------|
| `Bloc<Event, State>` | `stateMachine<State, Event>()` | Typed state machine with transitions |
| `Cubit<State>` | `reacton()` + `computed()` | Simple state + derived values |
| `BlocProvider` | `ReactonScope` | Provides state to the widget tree |
| `BlocBuilder` | `context.watch()` or `ReactonBuilder` | Rebuild on state change |
| `BlocListener` | `ReactonListener` | Side effects on state change |
| `BlocConsumer` | `ReactonConsumer` + `ReactonListener` | Combined build + listen |
| `BlocSelector` | `ReactonSelector` or `selector()` | Fine-grained rebuilds |
| `MultiBlocProvider` | `ReactonScope` (single) | One scope provides everything |
| `context.read<Bloc>()` | `context.read(reacton)` | One-time read |
| `context.watch<Bloc>().state` | `context.watch(reacton)` | Reactive read |
| `bloc.add(event)` | `context.set()` / `context.update()` | Direct state modification |
| `emit(state)` | `store.set(reacton, value)` | No emit concept -- just set values |

## Side-by-Side Examples

### Cubit -> reacton

**BLoC (Cubit):**

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

// Provider:
BlocProvider(create: (_) => CounterCubit(), child: MyApp())

// Widget:
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterCubit, int>(
      builder: (context, count) => Text('$count'),
    );
  }
}

// Dispatch:
context.read<CounterCubit>().increment();
```

**Reacton:**

```dart
final counterReacton = reacton(0, name: 'counter');

// Provider:
ReactonScope(child: MyApp())

// Widget:
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterReacton);
    return Text('$count');
  }
}

// Modify:
context.update(counterReacton, (c) => c + 1);  // increment
context.update(counterReacton, (c) => c - 1);  // decrement
context.set(counterReacton, 0);                 // reset
```

::: tip
With Reacton, you don't need a separate class for simple state. The increment/decrement logic lives directly in event handlers. For reuse, extract functions: `void increment(BuildContext ctx) => ctx.update(counterReacton, (c) => c + 1);`
:::

### Bloc -> stateMachine

**BLoC:**

```dart
// Events
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}
class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}
class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authApi.login(event.email, event.password);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onLogout(LogoutRequested event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
```

**Reacton:**

```dart
enum AuthState { initial, loading, success, failure }
enum AuthEvent { login, logout }

final authMachine = stateMachine<AuthState, AuthEvent>(
  initial: AuthState.initial,
  transitions: {
    AuthState.initial: {
      AuthEvent.login: (ctx) => AuthState.loading,
    },
    AuthState.loading: {},
    AuthState.success: {
      AuthEvent.logout: (ctx) => AuthState.initial,
    },
    AuthState.failure: {
      AuthEvent.login: (ctx) => AuthState.loading,
      AuthEvent.logout: (ctx) => AuthState.initial,
    },
  },
  name: 'auth',
);

final authUserReacton = reacton<User?>(null, name: 'authUser');
final authErrorReacton = reacton<String?>(null, name: 'authError');

// Login logic (as a standalone function):
Future<void> login(ReactonStore store, String email, String password) async {
  store.set(authMachine.stateReacton, AuthState.loading);
  try {
    final user = await authApi.login(email, password);
    store.batch(() {
      store.set(authUserReacton, user);
      store.set(authMachine.stateReacton, AuthState.success);
    });
  } catch (e) {
    store.batch(() {
      store.set(authErrorReacton, e.toString());
      store.set(authMachine.stateReacton, AuthState.failure);
    });
  }
}
```

### BlocBuilder -> context.watch

**BLoC:**

```dart
BlocBuilder<CounterCubit, int>(
  builder: (context, count) {
    return Text('$count');
  },
)
```

**Reacton:**

```dart
// Option 1: context.watch (simplest)
Widget build(BuildContext context) {
  final count = context.watch(counterReacton);
  return Text('$count');
}

// Option 2: ReactonBuilder (closer to BlocBuilder API)
ReactonBuilder(
  reacton: counterReacton,
  builder: (context, count) => Text('$count'),
)
```

### BlocListener -> ReactonListener

**BLoC:**

```dart
BlocListener<AuthBloc, AuthState>(
  listenWhen: (previous, current) => current is AuthFailure,
  listener: (context, state) {
    if (state is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error)),
      );
    }
  },
  child: MyWidget(),
)
```

**Reacton:**

```dart
ReactonListener<String?>(
  reacton: authErrorReacton,
  listenWhen: (previous, current) => current != null,
  listener: (context, error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error!)),
    );
  },
  child: MyWidget(),
)
```

### BlocSelector -> ReactonSelector

**BLoC:**

```dart
BlocSelector<UserBloc, UserState, String>(
  selector: (state) => state.user.name,
  builder: (context, name) => Text(name),
)
```

**Reacton:**

```dart
ReactonSelector<User, String>(
  reacton: userReacton,
  selector: (user) => user.name,
  builder: (context, name) => Text(name),
)

// Or use a selector reacton for reusable projections:
final userNameReacton = selector(userReacton, (user) => user.name);
// Then in widget:
final name = context.watch(userNameReacton);
```

### MultiBlocProvider -> ReactonScope

**BLoC:**

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => CounterCubit()),
    BlocProvider(create: (_) => AuthBloc()),
    BlocProvider(create: (_) => ThemeCubit()),
  ],
  child: MyApp(),
)
```

**Reacton:**

```dart
// All reactons are available through a single ReactonScope
ReactonScope(child: MyApp())
```

In Reacton, there is no need to register each piece of state separately. All top-level reacton declarations are automatically available through any `ReactonScope`.

## Testing Migration

**BLoC:**

```dart
blocTest<CounterCubit, int>(
  'increments',
  build: () => CounterCubit(),
  act: (cubit) => cubit.increment(),
  expect: () => [1],
);
```

**Reacton:**

```dart
test('increments', () {
  final store = TestReactonStore();

  store.expectEmissions(
    counterReacton,
    () => store.update(counterReacton, (c) => c + 1),
    [1],
  );
});
```

## Migration Checklist

- [ ] Replace `BlocProvider` / `MultiBlocProvider` with `ReactonScope`
- [ ] Replace simple `Cubit<T>` classes with `reacton<T>()`
- [ ] Replace complex `Bloc<Event, State>` with `stateMachine<State, Event>()`
- [ ] Replace `BlocBuilder` with `context.watch()` or `ReactonBuilder`
- [ ] Replace `BlocListener` with `ReactonListener`
- [ ] Replace `BlocSelector` with `ReactonSelector` or `selector()`
- [ ] Replace `context.read<Bloc>().add(event)` with `context.set()` or `context.update()`
- [ ] Replace `blocTest()` with standard `test()` using `TestReactonStore`
- [ ] Move event handler logic from `on<Event>` methods to standalone functions

## What's Next

- [From Riverpod](./from-riverpod) -- Migration guide from Riverpod
- [From Provider](./from-provider) -- Migration guide from Provider
