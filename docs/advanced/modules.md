# Modules

A `ReactonModule` groups related reactons with lifecycle management. Modules provide namespace isolation, lazy initialization, and clean uninstallation. Use modules to organize large applications into self-contained feature boundaries.

## Defining a Module

Extend `ReactonModule` and register reactons using the `register()` method:

```dart
class CartModule extends ReactonModule {
  late final items = register(reactonList<CartItem>([], name: 'cart.items'));
  late final total = register(computed(
    (read) => read(items).fold(0.0, (sum, item) => sum + item.price),
    name: 'cart.total',
  ));
  late final itemCount = register(computed(
    (read) => read(items).length,
    name: 'cart.itemCount',
  ));

  @override
  String get name => 'cart';

  @override
  void onInit(ReactonStore store) {
    // Load saved cart from storage, set up effects, etc.
    print('Cart module initialized');
  }

  @override
  void onDispose(ReactonStore store) {
    // Cleanup resources
    print('Cart module disposed');
  }
}
```

### ReactonModule Abstract Class

```dart
abstract class ReactonModule {
  String get name;
  bool get isInitialized;
  List<ReactonBase> get registeredReactons;

  T register<T extends ReactonBase>(T reacton);
  void onInit(ReactonStore store);
  void onDispose(ReactonStore store);
}
```

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `name` | `String` | The module name, used for debugging and namespacing. |
| `isInitialized` | `bool` | Whether this module has been installed and initialized. |
| `registeredReactons` | `List<ReactonBase>` | Unmodifiable list of all reactons registered to this module. |
| `register(reacton)` | `T` | Register a reacton as part of this module. Call during field initialization with `late final`. |
| `onInit(store)` | `void` | Called when the module is installed. Override to perform initialization. |
| `onDispose(store)` | `void` | Called when the module is uninstalled. Override to perform cleanup. |

## Installing a Module

Use `store.installModule()` to install a module:

```dart
final cartModule = store.installModule(CartModule());
```

What happens during installation:

1. The module is registered in the store by its type.
2. All reactons registered via `register()` are initialized in the store (their values are created lazily).
3. The module's `onInit()` callback is invoked.

::: warning
Installing a module of the same type twice throws a `StateError`. Uninstall first with `uninstallModule<T>()`.
:::

## Accessing a Module

Retrieve an installed module by type:

```dart
final cart = store.module<CartModule>();

// Access the module's reactons
final items = store.get(cart.items);
final total = store.get(cart.total);
```

## Uninstalling a Module

```dart
store.uninstallModule<CartModule>();
```

What happens during uninstallation:

1. The module's `onDispose()` callback is invoked.
2. All reactons registered to the module are removed from the store.
3. The module is deregistered.

## Store Extension API

| Method | Signature | Description |
|--------|-----------|-------------|
| `installModule` | `T installModule<T extends ReactonModule>(T module)` | Install a module. Throws if already installed. |
| `module` | `T module<T extends ReactonModule>()` | Get an installed module by type. Throws if not installed. |
| `hasModule` | `bool hasModule<T extends ReactonModule>()` | Check if a module is installed. |
| `uninstallModule` | `void uninstallModule<T extends ReactonModule>()` | Uninstall a module. Throws if not installed. |
| `installedModules` | `Iterable<ReactonModule>` | All currently installed modules. |
| `moduleCount` | `int` | Number of installed modules. |

## Feature Module Pattern

Organize your app by feature, where each feature is a self-contained module:

```dart
// auth_module.dart
class AuthModule extends ReactonModule {
  late final user = register(reacton<User?>(null, name: 'auth.user'));
  late final isLoggedIn = register(computed(
    (read) => read(user) != null,
    name: 'auth.isLoggedIn',
  ));
  late final token = register(reacton<String?>( null, name: 'auth.token'));

  @override
  String get name => 'auth';

  @override
  void onInit(ReactonStore store) {
    // Restore token from storage, validate session, etc.
  }

  @override
  void onDispose(ReactonStore store) {
    // Clear sensitive data
  }
}

// settings_module.dart
class SettingsModule extends ReactonModule {
  late final theme = register(reacton(ThemeMode.system, name: 'settings.theme'));
  late final locale = register(reacton('en', name: 'settings.locale'));
  late final notifications = register(reacton(true, name: 'settings.notifications'));

  @override
  String get name => 'settings';
}

// analytics_module.dart
class AnalyticsModule extends ReactonModule {
  late final events = register(reactonList<AnalyticsEvent>([], name: 'analytics.events'));
  late final sessionId = register(reacton('', name: 'analytics.sessionId'));

  @override
  String get name => 'analytics';

  @override
  void onInit(ReactonStore store) {
    store.set(sessionId, generateSessionId());
  }
}
```

### Composing Modules

```dart
void main() {
  final store = ReactonStore();

  // Install all feature modules
  store.installModule(AuthModule());
  store.installModule(SettingsModule());
  store.installModule(AnalyticsModule());

  runApp(ReactonScope(store: store, child: MyApp()));
}

// Access across the app
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.store.module<AuthModule>();
    final user = context.watch(auth.user);

    if (user == null) return LoginPrompt();
    return Text('Welcome, ${user.displayName}');
  }
}
```

## Namespace Isolation

By convention, prefix reacton names with the module name to prevent naming collisions across teams:

```dart
class CartModule extends ReactonModule {
  // Prefixed with 'cart.' to avoid collisions
  late final items = register(reactonList<CartItem>([], name: 'cart.items'));
  late final total = register(computed(
    (read) => read(items).fold(0.0, (s, i) => s + i.price),
    name: 'cart.total',
  ));

  @override
  String get name => 'cart';
}

class OrderModule extends ReactonModule {
  // Different namespace -- no collision with cart.items
  late final items = register(reactonList<OrderItem>([], name: 'order.items'));

  @override
  String get name => 'order';
}
```

## Conditional Module Installation

Install modules based on feature flags or configuration:

```dart
final store = ReactonStore();

store.installModule(AuthModule());
store.installModule(SettingsModule());

if (featureFlags.analyticsEnabled) {
  store.installModule(AnalyticsModule());
}

if (featureFlags.betaFeatures) {
  store.installModule(ExperimentalModule());
}

// Safely check before accessing
if (store.hasModule<AnalyticsModule>()) {
  final analytics = store.module<AnalyticsModule>();
  store.listAdd(analytics.events, AnalyticsEvent('app_start'));
}
```

## What's Next

- [Observable Collections](/advanced/collections) -- Reactive lists and maps with granular change events
- [Multi-Isolate](/advanced/isolates) -- Share state across Dart isolates
- [Middleware](/advanced/middleware) -- Intercept reacton lifecycle events
