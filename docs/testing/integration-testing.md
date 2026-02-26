# Integration Testing

Integration tests verify that multiple reactons, modules, and features work together correctly. While [unit tests](./unit-testing) focus on individual reactons in isolation, integration tests exercise the full dependency graph, lifecycle hooks, and cross-module communication.

## Module Initialization and Lifecycle

Modules group related reactons and provide lifecycle hooks. Integration tests should verify that modules initialize in the correct order and that their `onInit` / `onDispose` hooks fire as expected.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

// ---------- Module under test ----------

final userTokenReacton = reacton<String?>(null, name: 'userToken');
final userProfileReacton = asyncReacton<UserProfile?>((read) async {
  final token = read(userTokenReacton);
  if (token == null) return null;
  return await UserApi.fetchProfile(token);
}, name: 'userProfile');

class AuthModule extends ReactonModule {
  @override
  List<ReactonRef> get reactons => [userTokenReacton, userProfileReacton];

  @override
  void onInit(ReactonStore store) {
    // Restore persisted session on startup
    final saved = store.storage?.read('auth_token');
    if (saved != null) {
      store.set(userTokenReacton, saved);
    }
  }

  @override
  void onDispose(ReactonStore store) {
    store.set(userTokenReacton, null);
  }
}

// ---------- Tests ----------

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  group('AuthModule lifecycle', () {
    test('onInit restores persisted token', () async {
      final storage = MemoryStorage();
      await storage.write('auth_token', 'saved-jwt-123');

      final store = TestReactonStore(storageAdapter: storage);
      final module = AuthModule();
      module.onInit(store);

      expect(store.get(userTokenReacton), 'saved-jwt-123');
    });

    test('onDispose clears the user token', () {
      store.set(userTokenReacton, 'some-token');
      expect(store.get(userTokenReacton), 'some-token');

      final module = AuthModule();
      module.onDispose(store);

      expect(store.get(userTokenReacton), isNull);
    });

    test('module declares all expected reactons', () {
      final module = AuthModule();
      expect(module.reactons, contains(userTokenReacton));
      expect(module.reactons, contains(userProfileReacton));
    });
  });
}
```

## Testing Saga Flows End-to-End

Sagas coordinate multi-step async workflows. Integration tests should walk through the entire saga flow, verifying intermediate states and the final outcome.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

// ---------- Reactons & saga under test ----------

enum CheckoutStatus { idle, validating, charging, confirming, complete, failed }

final checkoutStatusReacton = reacton(CheckoutStatus.idle, name: 'checkoutStatus');
final cartItemsReacton = reacton<List<CartItem>>([], name: 'cartItems');
final orderIdReacton = reacton<String?>(null, name: 'orderId');
final checkoutErrorReacton = reacton<String?>(null, name: 'checkoutError');

final checkoutSaga = createSaga<void>((ctx) async {
  ctx.store.set(checkoutStatusReacton, CheckoutStatus.validating);

  final items = ctx.store.get(cartItemsReacton);
  if (items.isEmpty) {
    ctx.store.set(checkoutErrorReacton, 'Cart is empty');
    ctx.store.set(checkoutStatusReacton, CheckoutStatus.failed);
    return;
  }

  ctx.store.set(checkoutStatusReacton, CheckoutStatus.charging);
  final chargeResult = await ctx.call(PaymentApi.charge, items);

  if (!chargeResult.success) {
    ctx.store.set(checkoutErrorReacton, chargeResult.error);
    ctx.store.set(checkoutStatusReacton, CheckoutStatus.failed);
    return;
  }

  ctx.store.set(checkoutStatusReacton, CheckoutStatus.confirming);
  final orderId = await ctx.call(OrderApi.confirm, chargeResult.transactionId);

  ctx.store.set(orderIdReacton, orderId);
  ctx.store.set(cartItemsReacton, []);
  ctx.store.set(checkoutStatusReacton, CheckoutStatus.complete);
});

// ---------- Tests ----------

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  group('Checkout saga', () {
    test('fails when cart is empty', () async {
      store.set(cartItemsReacton, []);

      await checkoutSaga.run(store);

      expect(store.get(checkoutStatusReacton), CheckoutStatus.failed);
      expect(store.get(checkoutErrorReacton), 'Cart is empty');
    });

    test('completes full happy path', () async {
      store.set(cartItemsReacton, [CartItem(id: 'item1', price: 9.99)]);

      final statusHistory = <CheckoutStatus>[];
      store.subscribe(checkoutStatusReacton, (s) => statusHistory.add(s));

      await checkoutSaga.run(store);

      expect(statusHistory, [
        CheckoutStatus.validating,
        CheckoutStatus.charging,
        CheckoutStatus.confirming,
        CheckoutStatus.complete,
      ]);
      expect(store.get(orderIdReacton), isNotNull);
      expect(store.get(cartItemsReacton), isEmpty);
    });
  });
}
```

## Testing State Machine Transitions

State machines enforce that only valid transitions occur. Integration tests should verify both valid and invalid transitions across the full machine.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

// ---------- State machine under test ----------

enum ConnectionState { disconnected, connecting, connected, error }
enum ConnectionEvent { connect, connectionEstablished, connectionFailed, disconnect }

final connectionMachine = stateMachine<ConnectionState, ConnectionEvent>(
  initial: ConnectionState.disconnected,
  transitions: {
    ConnectionState.disconnected: {
      ConnectionEvent.connect: ConnectionState.connecting,
    },
    ConnectionState.connecting: {
      ConnectionEvent.connectionEstablished: ConnectionState.connected,
      ConnectionEvent.connectionFailed: ConnectionState.error,
    },
    ConnectionState.connected: {
      ConnectionEvent.disconnect: ConnectionState.disconnected,
    },
    ConnectionState.error: {
      ConnectionEvent.connect: ConnectionState.connecting,
    },
  },
  name: 'connection',
);

// ---------- Tests ----------

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  group('Connection state machine', () {
    test('starts in disconnected state', () {
      expect(store.get(connectionMachine), ConnectionState.disconnected);
    });

    test('follows the happy path: connect -> connected -> disconnect', () {
      store.send(connectionMachine, ConnectionEvent.connect);
      expect(store.get(connectionMachine), ConnectionState.connecting);

      store.send(connectionMachine, ConnectionEvent.connectionEstablished);
      expect(store.get(connectionMachine), ConnectionState.connected);

      store.send(connectionMachine, ConnectionEvent.disconnect);
      expect(store.get(connectionMachine), ConnectionState.disconnected);
    });

    test('handles connection failure and retry', () {
      store.send(connectionMachine, ConnectionEvent.connect);
      store.send(connectionMachine, ConnectionEvent.connectionFailed);
      expect(store.get(connectionMachine), ConnectionState.error);

      // Retry from error state
      store.send(connectionMachine, ConnectionEvent.connect);
      expect(store.get(connectionMachine), ConnectionState.connecting);

      store.send(connectionMachine, ConnectionEvent.connectionEstablished);
      expect(store.get(connectionMachine), ConnectionState.connected);
    });

    test('ignores invalid transitions', () {
      // Already disconnected, cannot disconnect again
      store.send(connectionMachine, ConnectionEvent.disconnect);
      expect(store.get(connectionMachine), ConnectionState.disconnected);

      // Connected cannot receive connectionEstablished
      store.send(connectionMachine, ConnectionEvent.connect);
      store.send(connectionMachine, ConnectionEvent.connectionEstablished);
      expect(store.get(connectionMachine), ConnectionState.connected);

      store.send(connectionMachine, ConnectionEvent.connectionEstablished);
      expect(store.get(connectionMachine), ConnectionState.connected);
    });
  });
}
```

## Testing Persistence with MemoryStorage

Integration tests for persistence verify that values survive a simulated app restart by using `MemoryStorage` shared across two `TestReactonStore` instances.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

// ---------- Persisted reactons ----------

final themeReacton = reacton(
  'light',
  name: 'theme',
  options: ReactonOptions(
    persistKey: 'app_theme',
    serializer: PrimitiveSerializer<String>(),
  ),
);

final onboardingCompleteReacton = reacton(
  false,
  name: 'onboardingComplete',
  options: ReactonOptions(
    persistKey: 'onboarding_done',
    serializer: PrimitiveSerializer<bool>(),
  ),
);

// ---------- Tests ----------

void main() {
  group('Persistence integration', () {
    test('theme survives app restart', () async {
      final storage = MemoryStorage();

      // First "app session"
      final store1 = TestReactonStore(storageAdapter: storage);
      store1.set(themeReacton, 'dark');
      await store1.flush(); // Ensure storage writes complete

      // Second "app session" — new store, same storage
      final store2 = TestReactonStore(storageAdapter: storage);
      expect(store2.get(themeReacton), 'dark');
    });

    test('multiple persisted reactons restore independently', () async {
      final storage = MemoryStorage();

      final store1 = TestReactonStore(storageAdapter: storage);
      store1.set(themeReacton, 'dark');
      store1.set(onboardingCompleteReacton, true);
      await store1.flush();

      final store2 = TestReactonStore(storageAdapter: storage);
      expect(store2.get(themeReacton), 'dark');
      expect(store2.get(onboardingCompleteReacton), true);
    });

    test('clearing storage resets to default values', () async {
      final storage = MemoryStorage();

      final store1 = TestReactonStore(storageAdapter: storage);
      store1.set(themeReacton, 'dark');
      await store1.flush();

      await storage.clear();

      final store2 = TestReactonStore(storageAdapter: storage);
      expect(store2.get(themeReacton), 'light'); // Back to default
    });
  });
}
```

## Testing Computed Reacton Chains

Multi-level computed chains are a common source of bugs. Integration tests should verify that changes propagate correctly through deep dependency chains.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

// ---------- Reacton chain under test ----------

final priceReacton = reacton(100.0, name: 'price');
final quantityReacton = reacton(1, name: 'quantity');
final discountPercentReacton = reacton(0.0, name: 'discountPercent');
final taxRateReacton = reacton(0.08, name: 'taxRate');

// Level 1 computed
final subtotalReacton = computed(
  (read) => read(priceReacton) * read(quantityReacton),
  name: 'subtotal',
);

// Level 2 computed (depends on Level 1)
final discountAmountReacton = computed(
  (read) => read(subtotalReacton) * (read(discountPercentReacton) / 100),
  name: 'discountAmount',
);

// Level 3 computed (depends on Level 1 and Level 2)
final taxAmountReacton = computed(
  (read) => (read(subtotalReacton) - read(discountAmountReacton)) * read(taxRateReacton),
  name: 'taxAmount',
);

// Level 4 computed (depends on Level 1, 2, and 3)
final totalReacton = computed(
  (read) =>
      read(subtotalReacton) - read(discountAmountReacton) + read(taxAmountReacton),
  name: 'total',
);

// ---------- Tests ----------

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  group('Computed chain: price calculator', () {
    test('computes initial total correctly', () {
      // price=100, qty=1, discount=0%, tax=8%
      expect(store.get(subtotalReacton), 100.0);
      expect(store.get(discountAmountReacton), 0.0);
      expect(store.get(taxAmountReacton), 8.0);
      expect(store.get(totalReacton), 108.0);
    });

    test('quantity change propagates through all levels', () {
      store.set(quantityReacton, 3);

      expect(store.get(subtotalReacton), 300.0);
      expect(store.get(discountAmountReacton), 0.0);
      expect(store.get(taxAmountReacton), 24.0);
      expect(store.get(totalReacton), 324.0);
    });

    test('discount propagates correctly', () {
      store.set(quantityReacton, 2);
      store.set(discountPercentReacton, 10.0);

      // subtotal=200, discount=20, taxable=180, tax=14.4
      expect(store.get(subtotalReacton), 200.0);
      expect(store.get(discountAmountReacton), 20.0);
      expect(store.get(taxAmountReacton), 14.4);
      expect(store.get(totalReacton), 194.4);
    });

    test('batch update computes final result correctly', () {
      store.batch(() {
        store.set(priceReacton, 50.0);
        store.set(quantityReacton, 4);
        store.set(discountPercentReacton, 25.0);
        store.set(taxRateReacton, 0.10);
      });

      // subtotal=200, discount=50, taxable=150, tax=15
      expect(store.get(subtotalReacton), 200.0);
      expect(store.get(discountAmountReacton), 50.0);
      expect(store.get(taxAmountReacton), 15.0);
      expect(store.get(totalReacton), 165.0);
    });
  });
}
```

## Cross-Module Integration Tests

Real applications use multiple modules that depend on each other. Integration tests verify the interactions between modules work correctly.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';

// ---------- Auth module ----------

final authTokenReacton = reacton<String?>(null, name: 'authToken');
final isLoggedInReacton = computed(
  (read) => read(authTokenReacton) != null,
  name: 'isLoggedIn',
);

class AuthModule extends ReactonModule {
  @override
  List<ReactonRef> get reactons => [authTokenReacton, isLoggedInReacton];
}

// ---------- Cart module (depends on Auth) ----------

final cartItemsReacton = reacton<List<String>>([], name: 'cartItems');
final cartCountReacton = computed(
  (read) => read(cartItemsReacton).length,
  name: 'cartCount',
);
final canCheckoutReacton = computed(
  (read) => read(isLoggedInReacton) && read(cartCountReacton) > 0,
  name: 'canCheckout',
);

class CartModule extends ReactonModule {
  @override
  List<ReactonRef> get reactons => [
        cartItemsReacton,
        cartCountReacton,
        canCheckoutReacton,
      ];
}

// ---------- Notifications module (depends on Auth and Cart) ----------

final notificationCountReacton = reacton(0, name: 'notificationCount');
final showBadgeReacton = computed(
  (read) => read(isLoggedInReacton) && read(notificationCountReacton) > 0,
  name: 'showBadge',
);

class NotificationModule extends ReactonModule {
  @override
  List<ReactonRef> get reactons => [notificationCountReacton, showBadgeReacton];
}

// ---------- Tests ----------

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  group('Cross-module integration', () {
    test('canCheckout requires both login and items', () {
      // No login, no items
      expect(store.get(canCheckoutReacton), false);

      // Logged in, no items
      store.set(authTokenReacton, 'jwt-token');
      expect(store.get(canCheckoutReacton), false);

      // Logged in, has items
      store.set(cartItemsReacton, ['Widget A']);
      expect(store.get(canCheckoutReacton), true);

      // Not logged in, has items
      store.set(authTokenReacton, null);
      expect(store.get(canCheckoutReacton), false);
    });

    test('logout clears dependent module state', () {
      store.set(authTokenReacton, 'jwt-token');
      store.set(cartItemsReacton, ['A', 'B', 'C']);
      store.set(notificationCountReacton, 5);

      expect(store.get(canCheckoutReacton), true);
      expect(store.get(showBadgeReacton), true);

      // Simulate logout
      store.set(authTokenReacton, null);
      store.set(cartItemsReacton, []);
      store.set(notificationCountReacton, 0);

      expect(store.get(isLoggedInReacton), false);
      expect(store.get(canCheckoutReacton), false);
      expect(store.get(showBadgeReacton), false);
    });

    test('notification badge depends on auth state', () {
      store.set(notificationCountReacton, 3);
      expect(store.get(showBadgeReacton), false); // Not logged in

      store.set(authTokenReacton, 'token');
      expect(store.get(showBadgeReacton), true); // Now logged in with notifications

      store.set(notificationCountReacton, 0);
      expect(store.get(showBadgeReacton), false); // No notifications
    });
  });
}
```

## Tips for Integration Tests

::: tip Use `store.batch()` for multi-reacton updates
When your integration test updates multiple reactons simultaneously (like a form submission), wrap them in `store.batch()` to match production behavior and ensure computed reactons only recompute once.
:::

::: tip Share MemoryStorage across stores
To simulate an app restart in a persistence integration test, create a single `MemoryStorage` instance and pass it to multiple `TestReactonStore` instances sequentially.
:::

::: warning Avoid testing implementation details
Integration tests should verify observable outcomes (final state values, emitted events) rather than internal implementation details like how many times a computed reacton recomputed. Use [effect testing](./effect-testing) and the `EffectTracker` for side-effect verification.
:::

## What's Next

- [Best Practices](./best-practices) -- Testing patterns and anti-patterns
- [Assertions](./assertions) -- Fluent assertion helpers for cleaner tests
- [Effect Testing](./effect-testing) -- Testing side effects and createEffect
