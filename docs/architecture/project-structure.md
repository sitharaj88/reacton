# Project Structure

How you organize your files has a direct impact on developer velocity, code review quality, and onboarding time. This page provides recommended directory layouts for three application sizes, along with naming conventions and best practices.

## Small Apps (Flat Structure)

For apps with roughly 5-15 reactons and fewer than 5 screens, a flat structure works well. The goal is simplicity: every developer can hold the entire state model in their head.

```
lib/
  main.dart
  app.dart
  state/
    counter_state.dart          # 2-3 reactons + computed values
    theme_state.dart            # Theme reacton + persistence
    user_state.dart             # User reacton + auth status computed
  services/
    api_service.dart            # HTTP client, API calls
    storage_service.dart        # SharedPreferences wrapper
  pages/
    home_page.dart
    settings_page.dart
    profile_page.dart
  widgets/
    counter_display.dart
    theme_toggle.dart
```

### Guidelines for Small Apps

- **One file per domain area** in `state/`. A "domain area" is a cohesive set of related reactons (e.g., all authentication-related state).
- **No modules needed.** Top-level reacton declarations are sufficient.
- **Services are plain classes.** They do not need to know about Reacton; effects bridge the gap.

### Example State File

```dart
// lib/state/counter_state.dart
import 'package:reacton/reacton.dart';

/// The primary counter value.
final counterReacton = reacton(0, name: 'counter');

/// Double the counter value, derived automatically.
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

/// Whether the counter is at zero.
final isZeroReacton = computed(
  (read) => read(counterReacton) == 0,
  name: 'isZero',
);
```

## Medium Apps (Feature-First)

For apps with 15-50 reactons and 5-20 screens, adopt a feature-first layout. Each feature gets its own directory containing state, UI, and any feature-specific services.

```
lib/
  main.dart
  app.dart
  core/
    di/
      service_locator.dart       # Dependency injection setup
    extensions/
      context_extensions.dart    # App-wide BuildContext extensions
    theme/
      app_theme.dart
      theme_state.dart
  features/
    auth/
      state/
        auth_state.dart          # reactons: user, authStatus, token
        auth_effects.dart        # Effects: persist token, auto-logout
      services/
        auth_service.dart        # Login/logout API calls
      pages/
        login_page.dart
        register_page.dart
      widgets/
        login_form.dart
        auth_guard.dart
      auth_module.dart           # ReactonModule grouping auth state
    cart/
      state/
        cart_state.dart          # reactons: items, computed total
        cart_effects.dart        # Effects: sync cart to backend
      services/
        cart_service.dart
      pages/
        cart_page.dart
      widgets/
        cart_item_tile.dart
        cart_summary.dart
      cart_module.dart
    products/
      state/
        product_state.dart       # family<AsyncValue<Product>, int>
        product_list_state.dart  # asyncReacton for product list
      services/
        product_service.dart
      pages/
        product_list_page.dart
        product_detail_page.dart
      widgets/
        product_card.dart
      products_module.dart
  shared/
    state/
      connectivity_state.dart    # Network connectivity reacton
      app_lifecycle_state.dart   # App foreground/background
    widgets/
      loading_indicator.dart
      error_display.dart
    services/
      analytics_service.dart
```

### Guidelines for Medium Apps

- **Feature directories are self-contained.** Everything a feature needs lives inside its directory. This makes it easy to reason about a feature in isolation and simplifies code reviews.
- **Use `ReactonModule` for each feature.** Modules provide lifecycle hooks and clean uninstallation.
- **Shared state goes in `shared/`.** Cross-cutting state (connectivity, app lifecycle) that multiple features depend on belongs here.
- **Effects live alongside state.** Keep effect declarations in the same directory as the reactons they depend on.

### Example Module

```dart
// lib/features/cart/cart_module.dart
import 'package:reacton/reacton.dart';
import 'state/cart_state.dart';

class CartModule extends ReactonModule {
  @override
  String get name => 'cart';

  late final items = register(cartItemsReacton);
  late final total = register(cartTotalReacton);

  @override
  void onInit(ReactonStore store) {
    // Load persisted cart items
    // Register effects for backend sync
  }

  @override
  void onDispose(ReactonStore store) {
    // Cancel any pending sync operations
  }
}
```

## Large Enterprise Apps (Package-Based)

For apps with 50+ reactons, 20+ screens, and multiple contributing teams, split your codebase into separate Dart packages. Each package is a bounded context with explicit dependencies.

```
packages/
  core/
    lib/
      src/
        middleware/
          logging_middleware.dart
          analytics_middleware.dart
        storage/
          storage_adapter.dart
          secure_storage_adapter.dart
        config/
          app_config.dart
          feature_flags.dart
      core.dart                      # Barrel export
    pubspec.yaml

  domain_auth/
    lib/
      src/
        models/
          user.dart
          auth_token.dart
        state/
          auth_reactons.dart         # All auth reactons
          auth_computed.dart         # Derived auth state
          auth_effects.dart
        services/
          auth_api.dart
          token_manager.dart
        auth_module.dart
      domain_auth.dart               # Barrel export
    test/
      auth_state_test.dart
      auth_module_test.dart
    pubspec.yaml                     # Depends on: core

  domain_cart/
    lib/
      src/
        models/
          cart_item.dart
          cart.dart
        state/
          cart_reactons.dart
          cart_computed.dart
          cart_sagas.dart             # Complex checkout workflow
        services/
          cart_api.dart
          inventory_checker.dart
        cart_module.dart
      domain_cart.dart
    test/
      cart_state_test.dart
      cart_saga_test.dart
    pubspec.yaml                     # Depends on: core, domain_auth

  domain_products/
    lib/ ...
    pubspec.yaml                     # Depends on: core

  ui_components/
    lib/
      src/
        buttons/
        cards/
        forms/
      ui_components.dart
    pubspec.yaml                     # Depends on: core (for theme state)

app/
  lib/
    main.dart
    app.dart
    routing/
      app_router.dart
    composition/
      module_installer.dart          # Installs all domain modules
      store_factory.dart             # Creates and configures the store
    pages/                           # Thin page shells composing features
      home_page.dart
      checkout_page.dart
  pubspec.yaml                       # Depends on: all domain_* packages, ui_components
```

### Guidelines for Enterprise Apps

- **Each domain package owns its state, models, services, and tests.** Teams can develop, test, and release packages independently.
- **The `app/` package is a thin composition layer.** It wires packages together via module installation and routing. It should contain minimal business logic.
- **Explicit dependency direction.** Domain packages depend on `core` but never on each other in a circular way. If `cart` needs auth state, it depends on `domain_auth`.
- **Module installer centralizes setup.**

```dart
// app/lib/composition/module_installer.dart
void installModules(ReactonStore store) {
  store.installModule(AuthModule());
  store.installModule(CartModule());
  store.installModule(ProductsModule());
  // Feature flags determine which modules are active
  if (FeatureFlags.enableCollaboration) {
    store.installModule(CollaborationModule());
  }
}
```

## Naming Conventions

Consistent naming makes codebases scannable. Follow these conventions:

### Reacton Names

| Type | Convention | Example |
|---|---|---|
| Writable reacton | `<noun>Reacton` | `counterReacton`, `userReacton` |
| Computed reacton | `<derivedNoun>Reacton` | `totalPriceReacton`, `isLoggedInReacton` |
| Selector | `<field>Reacton` | `userNameReacton`, `cartItemCountReacton` |
| Family | `<noun>Reacton` (factory) | `userByIdReacton`, `productReacton` |
| Async reacton | `<noun>Reacton` | `usersReacton`, `searchResultsReacton` |

### Debug Names

Always provide a `name` parameter for DevTools visibility. Use dot notation for namespaced reactons:

```dart
// Without module
final counterReacton = reacton(0, name: 'counter');

// Within a module
final items = register(reacton<List<CartItem>>([], name: 'cart.items'));
final total = register(computed(..., name: 'cart.total'));
```

### File Names

| Type | Convention | Example |
|---|---|---|
| State declarations | `<domain>_state.dart` | `auth_state.dart`, `cart_state.dart` |
| Computed derivations | `<domain>_computed.dart` | `cart_computed.dart` |
| Effects | `<domain>_effects.dart` | `auth_effects.dart` |
| Module class | `<domain>_module.dart` | `cart_module.dart` |
| Saga definitions | `<domain>_sagas.dart` | `checkout_sagas.dart` |
| Models | `<model>.dart` | `user.dart`, `cart_item.dart` |

## File Organization Best Practices

### 1. One Concern Per File

Do not mix reacton declarations with widget code. Even in small apps, separating state from UI pays for itself quickly.

```dart
// Bad: reacton declared in widget file
// lib/pages/counter_page.dart
final counterReacton = reacton(0);
class CounterPage extends StatelessWidget { ... }

// Good: state in its own file
// lib/state/counter_state.dart
final counterReacton = reacton(0, name: 'counter');

// lib/pages/counter_page.dart
import '../state/counter_state.dart';
class CounterPage extends StatelessWidget { ... }
```

### 2. Barrel Exports for Packages

In package-based architectures, use barrel files to control the public API:

```dart
// packages/domain_auth/lib/domain_auth.dart
export 'src/models/user.dart';
export 'src/auth_module.dart';
// Do NOT export internal services or implementation details
```

### 3. Co-locate Tests with Packages

```
packages/
  domain_cart/
    lib/
      src/
        state/
          cart_reactons.dart
    test/
      state/
        cart_reactons_test.dart    # Mirrors lib/ structure
```

### 4. Group Related Reactons

When a domain has many reactons, group declarations and computed values:

```dart
// lib/features/cart/state/cart_state.dart

// ---- Writable State ----
final cartItemsReacton = reacton<List<CartItem>>([], name: 'cart.items');
final cartCouponReacton = reacton<String?>(null, name: 'cart.coupon');

// ---- Computed State ----
final cartSubtotalReacton = computed(
  (read) => read(cartItemsReacton).fold(0.0, (s, i) => s + i.price * i.qty),
  name: 'cart.subtotal',
);

final cartDiscountReacton = computed((read) {
  final coupon = read(cartCouponReacton);
  final subtotal = read(cartSubtotalReacton);
  if (coupon == 'SAVE20') return subtotal * 0.20;
  return 0.0;
}, name: 'cart.discount');

final cartTotalReacton = computed(
  (read) => read(cartSubtotalReacton) - read(cartDiscountReacton),
  name: 'cart.total',
);
```

### 5. Keep the Dependency Graph Shallow

A deep chain of computed reactons (A -> B -> C -> D -> E -> F) increases propagation latency and makes debugging harder. If you find yourself chaining more than 3-4 levels, consider flattening by reading the original sources directly.

## What's Next

- [Common Patterns](/architecture/patterns) -- Repository, service layer, DI, event bus, CQRS
- [Performance](/architecture/performance) -- Optimizing your graph for smooth UI
- [Scaling to Enterprise](/architecture/scaling) -- Module boundaries, multi-package strategies
