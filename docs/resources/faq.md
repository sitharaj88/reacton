# Frequently Asked Questions

## Why should I use Reacton instead of setState?

`setState` is fine for local, widget-scoped state like a toggle or text field. It becomes painful when:

- **Multiple widgets** need to read the same state -- you end up lifting state and passing it through constructor chains.
- **Derived state** needs to be computed from other state -- you recalculate inside `build()` with no caching.
- **Side effects** (API calls, analytics, persistence) need to run on state changes -- you scatter logic across `didUpdateWidget` and `initState`.
- **Testing** requires spinning up the widget tree for every assertion.

Reacton gives you:

```dart
// Declare once, use anywhere
final counterReacton = reacton(0, name: 'counter');

// Derived state is automatic
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);
```

No prop drilling, no `InheritedWidget`, no `ChangeNotifier`. State lives outside the widget tree and widgets subscribe to exactly what they need via `context.watch()`.

**When to keep using setState:** Animation controllers, focus nodes, scroll positions -- anything that is truly local to a single widget and has no external observers.

---

## How does Reacton compare to Riverpod, BLoC, and Provider?

| Aspect | Reacton | Riverpod | BLoC | Provider |
|--------|---------|----------|------|----------|
| State declaration | `reacton(0)` | `StateProvider((ref) => 0)` | `Cubit` / `Bloc` class | `ChangeNotifier` class |
| Derived state | `computed((read) => ...)` | `Provider((ref) => ...)` | Separate selector BLoC | Manual `Selector` |
| Async | `asyncReacton` | `FutureProvider` | `emit` in async method | Manual loading flags |
| Widget access | `context.watch()` | `ref.watch()` | `BlocBuilder` | `context.watch()` |
| Testing | `TestReactonStore` | `ProviderContainer` | `blocTest` | Widget-level |
| Code generation | Optional | Optional (v2) | None | None |
| DevTools | Dedicated extension | Dedicated extension | Dedicated extension | None |

See the [Detailed Comparison](./comparison) page for code examples and a full feature matrix.

---

## Is code generation required?

**No.** Code generation is entirely optional. Every Reacton feature works without it.

Code generation is available through `reacton_generator` and the `@ReactonSerializable` annotation for:

- Automatic `toJson` / `fromJson` for persisted reactons
- Immutable state classes with `copyWith`

You can adopt code generation later for convenience without changing your reacton declarations.

```dart
// Without codegen — works perfectly fine
final userReacton = reacton(
  User(name: '', email: ''),
  name: 'user',
);

// With codegen — adds toJson/fromJson/copyWith
@ReactonSerializable()
class User {
  final String name;
  final String email;
  // Generated: User.fromJson, toJson, copyWith
}
```

---

## Can I use Reacton with other state management solutions?

Yes. Reacton does not take over your widget tree or require an exclusive provider hierarchy. You can:

- **Wrap only part of your app** in `ReactonScope` and use BLoC or Provider elsewhere.
- **Incrementally migrate** by converting one feature at a time (see the [Migration Guides](/migration/)).
- **Bridge to other systems** by reading external state in a `computed()` or `createEffect()`.

```dart
// Bridge: read a BLoC value into a reacton
final authBloc = context.read<AuthBloc>();
createEffect(
  (read) => authBloc.stream,
  effect: (state) => store.set(authStateReacton, state),
);
```

---

## Is Reacton production ready?

Reacton is at version 0.1.2 and is suitable for production use with the understanding that the API may evolve before 1.0. The core reactive engine, Flutter integration, async handling, testing utilities, and DevTools extension are all fully functional.

We recommend:

- Pinning your dependency to a specific minor version (`^0.1.2`)
- Following the [changelog](/resources/changelog) for breaking changes
- Writing comprehensive tests using `reacton_test` so upgrades are safe

---

## How do I handle dependency injection?

Reacton's dependency injection is intentionally simple:

**1. Top-level declarations (most common):**

```dart
// Reactons are global singletons — no registration needed
final userReacton = reacton<User?>(null, name: 'user');
```

**2. ReactonScope overrides (for testing or configuration):**

```dart
ReactonScope(
  overrides: [
    ReactonOverride(apiBaseUrlReacton, 'https://staging.example.com'),
  ],
  child: MyApp(),
)
```

**3. Modules (for grouping and lifecycle):**

```dart
class AuthModule extends ReactonModule {
  @override
  List<ReactonRef> get reactons => [tokenReacton, userReacton];

  @override
  void onInit(ReactonStore store) {
    // Setup logic
  }
}
```

You do not need a service locator like `get_it` or `GetX`'s `Get.put()`. If you already use one, Reacton can coexist with it.

---

## Does Reacton work with Flutter Web and Desktop?

Yes. Reacton is pure Dart with no platform-specific native code. It works on every Flutter target:

- Android
- iOS
- Web
- macOS
- Windows
- Linux

The `reacton_devtools` extension works with the Dart DevTools on all platforms. The VS Code extension works on all platforms supported by VS Code.

---

## How do I handle authentication state?

A common pattern is an auth module with token persistence and computed login state:

```dart
final authTokenReacton = reacton<String?>(
  null,
  name: 'authToken',
  options: ReactonOptions(
    persistKey: 'auth_token',
    serializer: PrimitiveSerializer<String?>(),
  ),
);

final isLoggedInReacton = computed(
  (read) => read(authTokenReacton) != null,
  name: 'isLoggedIn',
);

final currentUserReacton = asyncReacton<User?>((read) async {
  final token = read(authTokenReacton);
  if (token == null) return null;
  return await AuthApi.getUser(token);
}, name: 'currentUser');

// Login
void login(BuildContext context, String email, String password) async {
  final token = await AuthApi.login(email, password);
  context.set(authTokenReacton, token);
}

// Logout
void logout(BuildContext context) {
  context.set(authTokenReacton, null);
}

// In widget
Widget build(BuildContext context) {
  final isLoggedIn = context.watch(isLoggedInReacton);
  return isLoggedIn ? HomePage() : LoginPage();
}
```

See the [Authentication Cookbook](/cookbook/authentication) for a full example with error handling, loading states, and token refresh.

---

## What about performance with thousands of reactons?

Reacton uses a fine-grained dependency graph. Only the reactons that are actually observed by mounted widgets are tracked. Key performance characteristics:

- **O(1) reads and writes** for individual reactons.
- **Topological propagation** ensures computed reactons recompute only when their direct dependencies change.
- **Batch updates** via `store.batch()` coalesce multiple writes into a single propagation pass.
- **Selector reactons** prevent rebuilds when only an irrelevant slice of state changes.

In practice, applications with hundreds or even thousands of reactons perform well because:

1. Most reactons are idle (no active widget subscribers).
2. Only the changed subgraph propagates -- not the entire graph.
3. Computed reactons cache their results and skip recomputation when inputs are unchanged.

If you notice performance issues, use `reacton analyze` to detect unnecessary complexity and check the DevTools performance tab for hot reactons.

---

## Can I use Reacton without Flutter (pure Dart)?

Yes. The core `reacton` package has no Flutter dependency. You can use it in:

- Dart CLI tools
- Dart server applications (shelf, dart_frog)
- Shared logic packages consumed by Flutter apps

```dart
// Pure Dart — no Flutter import
import 'package:reacton/reacton.dart';

final store = ReactonStore();
final counter = reacton(0, name: 'counter');

store.set(counter, 1);
print(store.get(counter)); // 1

final doubled = computed((read) => read(counter) * 2, name: 'doubled');
print(store.get(doubled)); // 2
```

The `flutter_reacton` package adds Flutter-specific bindings (`ReactonScope`, `context.watch()`, widgets). Import only the package you need.

---

## How do I debug state issues?

Reacton provides multiple debugging tools:

**1. DevTools Extension**

Install `reacton_devtools` and call `ReactonDevToolsExtension.install(store)` at app startup. The DevTools extension provides:

- Live dependency graph visualization
- State inspector (read and write values)
- Timeline of all state changes
- Performance metrics per reacton

**2. Middleware Logging**

```dart
final store = ReactonStore(
  middleware: [
    LoggingMiddleware(), // Logs every state change to the console
  ],
);
```

**3. CLI Analysis**

```bash
# Detect dead reactons, cycles, and complexity issues
reacton analyze

# Visualize the dependency graph
reacton graph --dot | dot -Tpng -o graph.png
```

**4. Named Reactons**

Always provide a `name` parameter. It appears in DevTools, error messages, and logs:

```dart
final counterReacton = reacton(0, name: 'counter');
// Without name: error messages show "Reacton<int>#12345"
// With name: error messages show "counter"
```

See the [Debugging Guide](/architecture/debugging) for a detailed walkthrough.

---

## Is there server-side rendering support?

Dart does not have a built-in server-side rendering (SSR) story like React/Next.js. However, Reacton's architecture supports pre-rendering patterns:

- **Pre-populate state on the server** by creating a `ReactonStore`, setting values, and serializing the store snapshot to JSON.
- **Hydrate on the client** by deserializing the snapshot and passing it as overrides to `ReactonScope`.

```dart
// Server (dart_frog handler)
final store = ReactonStore();
store.set(pageDataReacton, await fetchPageData(request));
final snapshot = store.snapshot();
final json = jsonEncode(snapshot);
// Embed json in the HTML response

// Client (Flutter Web)
final snapshot = jsonDecode(embeddedJson);
ReactonScope(
  initialSnapshot: snapshot,
  child: MyApp(),
)
```

This is an advanced pattern. For most Flutter applications, client-side state initialization is sufficient.
