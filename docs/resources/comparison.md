# Detailed Comparison

An in-depth comparison of Reacton with other popular Flutter state management solutions. This page covers feature matrices, code comparisons, and guidance on when each solution is the best fit.

## Feature Matrix

| Feature | Reacton | Riverpod | BLoC | Provider | GetX | Signals |
|---------|:-------:|:--------:|:----:|:--------:|:----:|:-------:|
| **Core State** | | | | | | |
| Writable state | `reacton()` | `StateProvider` | `Cubit.emit` | `ChangeNotifier` | `.obs` | `signal()` |
| Computed / derived | `computed()` | `Provider` | Separate BLoC | Manual | `Rx` getters | `computed()` |
| Selector (sub-state) | `selector()` | `select()` | `BlocSelector` | `Selector` | N/A | N/A |
| Family (parameterized) | `family()` | `.family` | N/A | N/A | N/A | N/A |
| State machines | Built-in | Manual | `bloc` events | Manual | Manual | Manual |
| Observable collections | Built-in | Manual | Manual | Manual | `RxList/Map/Set` | Manual |
| Lenses | Built-in | Manual | N/A | N/A | N/A | N/A |
| **Async** | | | | | | |
| Async data fetching | `asyncReacton` | `FutureProvider` | `emit` in async | Manual flags | `StateMixin` | Manual |
| Query with caching | `QueryReacton` | `riverpod_query` | N/A | N/A | `GetConnect` | N/A |
| Retry policies | `RetryPolicy` | Manual | Manual | Manual | Manual | Manual |
| Optimistic updates | `OptimisticUpdate` | Manual | Manual | Manual | Manual | Manual |
| Debounce / Throttle | `Debouncer`/`Throttler` | `ref.debounce` | `transformEvents` | Manual | `debounce()` | Manual |
| **Flutter Integration** | | | | | | |
| Scope / Provider | `ReactonScope` | `ProviderScope` | `BlocProvider` | `MultiProvider` | `Get.put` | `SignalProvider` |
| Context extensions | `context.watch/read/set` | `ref.watch/read` | `context.read` | `context.watch` | `Get.find` | N/A |
| Listener widget | `ReactonListener` | `ref.listen` | `BlocListener` | N/A | `ever()` | N/A |
| No base class needed | Yes | No (`Consumer`) | No (`BlocBuilder`) | No | No (`GetView`) | Yes |
| **Architecture** | | | | | | |
| Modules | `ReactonModule` | N/A | N/A | N/A | N/A | N/A |
| Middleware | Built-in | N/A | `BlocObserver` | N/A | N/A | N/A |
| Sagas | Built-in | N/A | N/A | N/A | N/A | N/A |
| Persistence | Built-in | `riverpod_persist` | `hydrated_bloc` | N/A | `GetStorage` | N/A |
| History (Undo/Redo) | Built-in | Manual | `replay_bloc` | N/A | N/A | N/A |
| State branching | Built-in | N/A | N/A | N/A | N/A | N/A |
| CRDT (collaborative) | Built-in | N/A | N/A | N/A | N/A | N/A |
| **Testing** | | | | | | |
| Test store | `TestReactonStore` | `ProviderContainer` | `blocTest` | Widget tests | Mock controller | Manual |
| Mock utilities | `MockReacton` | `overrideWith` | `MockBloc` | Mock notifier | `Get.testMode` | Manual |
| Effect tracker | `EffectTracker` | N/A | N/A | N/A | N/A | N/A |
| Graph assertions | `GraphAssertion` | N/A | N/A | N/A | N/A | N/A |
| **DevTools** | | | | | | |
| Inspector | Dedicated panel | Dedicated panel | Dedicated panel | N/A | N/A | N/A |
| Dependency graph | Visual graph | N/A | N/A | N/A | N/A | N/A |
| State timeline | Yes | Yes | Yes | N/A | N/A | N/A |
| Performance metrics | Per-reacton | N/A | N/A | N/A | N/A | N/A |
| **Tooling** | | | | | | |
| CLI | `reacton_cli` | `riverpod_cli` | N/A | N/A | `get_cli` | N/A |
| Code generation | `reacton_generator` | `riverpod_generator` | `freezed` (common) | N/A | N/A | N/A |
| Lint rules | 3 custom rules | `riverpod_lint` | `bloc_lint` | N/A | N/A | N/A |
| VS Code extension | Yes | Yes | Yes | N/A | N/A | N/A |
| **Other** | | | | | | |
| Learning curve | Low-Medium | Medium | Medium-High | Low | Low | Low |
| Boilerplate | Minimal | Low-Medium | High | Medium | Low | Minimal |
| Pure Dart support | Yes | Yes | Yes | No | Partial | Yes |

## Architectural Philosophy

### Reacton
**Atom-based reactivity.** State is declared as independent atoms (`reacton()`) that form a dependency graph. Computed values automatically track their sources. No classes, no events, no streams for basic state. The reactive graph handles propagation. Advanced patterns (state machines, sagas, CRDT) are built into the library rather than requiring separate packages.

### Riverpod
**Provider-based with compile-time safety.** Every piece of state is a provider. Riverpod v2 introduces code generation for a more concise API. Strong emphasis on compile-time error detection and ref-based lifecycle management. Architecture is flexible but guided by the provider pattern.

### BLoC
**Event-driven with strict separation.** State changes happen through events processed by a Bloc class. The unidirectional data flow (Event -> Bloc -> State) enforces discipline. Good for large teams that benefit from rigid conventions. Higher boilerplate but very predictable.

### Provider
**InheritedWidget wrapper.** The simplest step up from raw Flutter. Uses `ChangeNotifier` classes exposed through the widget tree. Limited built-in features for async, testing, or advanced patterns. Often used as a foundation before migrating to Riverpod.

### GetX
**All-in-one toolkit.** Bundles state management, routing, DI, and HTTP in one package. Minimal boilerplate and fast to get started. Less structured, which can lead to maintenance challenges in large apps. Uses magic strings and global singletons extensively.

### Signals (flutter_hooks / signals)
**Fine-grained reactivity inspired by SolidJS.** Similar philosophy to Reacton with signals and computed values. Focuses on the core reactive primitive. Fewer built-in advanced features (no persistence, no sagas, no state machines) but extremely lightweight.

## Code Comparison

### Counter (Minimal Example)

**Reacton:**

```dart
final counter = reacton(0, name: 'counter');

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counter);
    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.update(counter, (c) => c + 1),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**Riverpod:**

```dart
final counter = StateProvider<int>((ref) => 0);

class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counter);
    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counter.notifier).state++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**BLoC:**

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: Scaffold(
        body: Center(
          child: BlocBuilder<CounterCubit, int>(
            builder: (context, count) => Text('$count'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.read<CounterCubit>().increment(),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```

**GetX:**

```dart
class CounterController extends GetxController {
  var count = 0.obs;
  void increment() => count++;
}

class CounterPage extends StatelessWidget {
  final ctrl = Get.put(CounterController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Obx(() => Text('${ctrl.count}'))),
      floatingActionButton: FloatingActionButton(
        onPressed: ctrl.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Async Data Fetching

**Reacton:**

```dart
final cityReacton = reacton('London', name: 'city');
final weatherReacton = asyncReacton<Weather>((read) async {
  final city = read(cityReacton);
  return await WeatherApi.fetch(city);
}, name: 'weather');

// Widget:
final weather = context.watch(weatherReacton);
return weather.when(
  loading: () => CircularProgressIndicator(),
  data: (w) => Text('${w.temp}C'),
  error: (e, _) => Text('Error: $e'),
);
```

**Riverpod:**

```dart
final cityProvider = StateProvider<String>((ref) => 'London');
final weatherProvider = FutureProvider<Weather>((ref) async {
  final city = ref.watch(cityProvider);
  return await WeatherApi.fetch(city);
});

// Widget (ConsumerWidget):
final weather = ref.watch(weatherProvider);
return weather.when(
  loading: () => CircularProgressIndicator(),
  data: (w) => Text('${w.temp}C'),
  error: (e, _) => Text('Error: $e'),
);
```

**BLoC:**

```dart
// Events
abstract class WeatherEvent {}
class FetchWeather extends WeatherEvent { final String city; FetchWeather(this.city); }

// States
abstract class WeatherState {}
class WeatherLoading extends WeatherState {}
class WeatherLoaded extends WeatherState { final Weather weather; WeatherLoaded(this.weather); }
class WeatherError extends WeatherState { final String message; WeatherError(this.message); }

// Bloc
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(WeatherLoading()) {
    on<FetchWeather>((event, emit) async {
      emit(WeatherLoading());
      try {
        final weather = await WeatherApi.fetch(event.city);
        emit(WeatherLoaded(weather));
      } catch (e) {
        emit(WeatherError(e.toString()));
      }
    });
  }
}

// Widget:
BlocBuilder<WeatherBloc, WeatherState>(
  builder: (context, state) => switch (state) {
    WeatherLoading() => CircularProgressIndicator(),
    WeatherLoaded(:final weather) => Text('${weather.temp}C'),
    WeatherError(:final message) => Text('Error: $message'),
    _ => SizedBox(),
  },
)
```

### Form Validation

**Reacton:**

```dart
final emailReacton = reacton('', name: 'email');
final passwordReacton = reacton('', name: 'password');

final emailErrorReacton = computed((read) {
  final email = read(emailReacton);
  if (email.isEmpty) return null;
  return email.contains('@') ? null : 'Invalid email';
}, name: 'emailError');

final canSubmitReacton = computed((read) {
  return read(emailErrorReacton) == null &&
         read(emailReacton).isNotEmpty &&
         read(passwordReacton).length >= 8;
}, name: 'canSubmit');
```

**BLoC:**

```dart
class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(LoginFormState());

  void emailChanged(String email) => emit(state.copyWith(
    email: email,
    emailError: email.contains('@') ? null : 'Invalid email',
  ));

  void passwordChanged(String password) => emit(state.copyWith(
    password: password,
  ));

  bool get canSubmit =>
    state.emailError == null &&
    state.email.isNotEmpty &&
    state.password.length >= 8;
}
```

## When to Choose Each Solution

### Choose Reacton when:
- You want **minimal boilerplate** with powerful built-in features
- You need **advanced patterns** (state machines, sagas, CRDT, state branching) without extra packages
- You want a **unified testing API** with `TestReactonStore`
- You prefer **atom-based reactivity** over class-based state
- You want built-in **persistence, undo/redo, and middleware** out of the box
- Your team is **small to medium** and values developer velocity

### Choose Riverpod when:
- You want **compile-time safety** and ref-based lifecycle management
- You are already familiar with the Riverpod ecosystem
- You want **code generation** (v2) for provider declarations
- You have a **medium to large** team that benefits from Riverpod's structure

### Choose BLoC when:
- Your team values **strict unidirectional data flow** enforced at the architecture level
- You work on a **large team** where rigid conventions prevent inconsistency
- You want the **event-sourcing pattern** (replay, transform events)
- You are comfortable with **higher boilerplate** for predictability

### Choose Provider when:
- You need the **simplest possible** step up from raw Flutter
- Your app is **small** and unlikely to grow complex
- You want **official Flutter team backing** (Provider is endorsed by Flutter)

### Choose GetX when:
- You want **rapid prototyping** with minimal setup
- You prefer an **all-in-one** solution (state + routing + DI + HTTP)
- **Speed of development** matters more than architectural purity

### Choose Signals when:
- You want the **lightest possible** reactive primitive
- You are coming from a **web framework** (SolidJS, Preact Signals)
- You do not need built-in persistence, testing utilities, or DevTools

## Migration Difficulty

| From | To Reacton | Effort | Notes |
|------|:----------:|:------:|-------|
| Provider | Low | 1-2 days | Mostly mechanical: `ChangeNotifier` to `reacton()`, `context.watch()` is identical |
| Riverpod | Low | 1-2 days | Concept mapping is 1:1. See [From Riverpod](/migration/from-riverpod) |
| BLoC | Medium | 3-5 days | Flatten Bloc classes into reactons. Events become direct `set`/`update` calls. See [From BLoC](/migration/from-bloc) |
| GetX | Medium | 3-5 days | Replace `.obs` with `reacton()`, workers with effects. See [From GetX](/migration/from-getx) |
| setState | Low | Hours | Lift local state into reactons as needed |

All migration guides are available in the [Migration section](/migration/).
