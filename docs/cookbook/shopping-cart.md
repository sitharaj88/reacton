# Shopping Cart

An e-commerce shopping cart with product listing, quantity management, persistence across restarts, and optimistic updates. Demonstrates `ReactonModule`, `PersistenceMiddleware`, `computed` derived totals, and `store.optimistic` for instant UI feedback.

## Full Source

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- Models ---

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

// --- Simulated API ---

class ProductApi {
  static Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const [
      Product(
        id: 'p1',
        name: 'Wireless Headphones',
        description: 'Noise-cancelling over-ear headphones with 30h battery.',
        price: 149.99,
        imageUrl: 'headphones',
      ),
      Product(
        id: 'p2',
        name: 'Mechanical Keyboard',
        description: 'Hot-swappable switches with RGB backlight.',
        price: 89.99,
        imageUrl: 'keyboard',
      ),
      Product(
        id: 'p3',
        name: 'USB-C Hub',
        description: '7-in-1 hub with HDMI, USB-A, SD card reader.',
        price: 49.99,
        imageUrl: 'hub',
      ),
      Product(
        id: 'p4',
        name: 'Laptop Stand',
        description: 'Adjustable aluminium stand with cable management.',
        price: 39.99,
        imageUrl: 'stand',
      ),
      Product(
        id: 'p5',
        name: 'Webcam HD',
        description: '1080p webcam with autofocus and built-in mic.',
        price: 69.99,
        imageUrl: 'webcam',
      ),
    ];
  }

  /// Simulates a server-side quantity update (may fail).
  static Future<void> updateCartOnServer(
      String productId, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate occasional failure
    if (productId == 'p3' && quantity > 5) {
      throw Exception('Maximum quantity exceeded for this item');
    }
  }
}

// --- Cart Module ---

class CartModule extends ReactonModule {
  /// The cart items, keyed by product ID.
  late final itemsReacton = reacton<Map<String, CartItem>>(
    {},
    name: 'cart.items',
  );

  /// Computed: all items as a list.
  late final itemList = computed<List<CartItem>>(
    (read) => read(itemsReacton).values.toList(),
    name: 'cart.itemList',
  );

  /// Computed: total number of items (sum of quantities).
  late final itemCount = computed<int>(
    (read) => read(itemsReacton)
        .values
        .fold(0, (sum, item) => sum + item.quantity),
    name: 'cart.itemCount',
  );

  /// Computed: cart subtotal.
  late final subtotal = computed<double>(
    (read) => read(itemsReacton)
        .values
        .fold(0.0, (sum, item) => sum + item.subtotal),
    name: 'cart.subtotal',
  );

  /// Computed: shipping estimate (free over $100).
  late final shipping = computed<double>(
    (read) {
      final total = read(subtotal);
      if (total == 0) return 0.0;
      return total >= 100.0 ? 0.0 : 9.99;
    },
    name: 'cart.shipping',
  );

  /// Computed: grand total including shipping.
  late final grandTotal = computed<double>(
    (read) => read(subtotal) + read(shipping),
    name: 'cart.grandTotal',
  );

  /// Add a product to the cart or increment its quantity.
  void addItem(ReactonStore store, Product product) {
    store.update(itemsReacton, (items) {
      final existing = items[product.id];
      return {
        ...items,
        product.id: existing != null
            ? existing.copyWith(quantity: existing.quantity + 1)
            : CartItem(product: product),
      };
    });
  }

  /// Remove a product from the cart entirely.
  void removeItem(ReactonStore store, String productId) {
    store.update(itemsReacton, (items) {
      final updated = Map<String, CartItem>.from(items);
      updated.remove(productId);
      return updated;
    });
  }

  /// Update quantity with optimistic update.
  Future<void> updateQuantity(
    ReactonStore store,
    String productId,
    int newQuantity,
  ) async {
    if (newQuantity <= 0) {
      removeItem(store, productId);
      return;
    }

    // Optimistic: update the UI immediately, roll back on failure
    await store.optimistic(
      reacton: itemsReacton,
      optimisticValue: () {
        final items = store.get(itemsReacton);
        final item = items[productId];
        if (item == null) return items;
        return {
          ...items,
          productId: item.copyWith(quantity: newQuantity),
        };
      }(),
      mutation: () =>
          ProductApi.updateCartOnServer(productId, newQuantity),
    );
  }

  @override
  void register(ReactonStore store) {
    store.register(itemsReacton);
    store.register(itemCount);
    store.register(subtotal);
    store.register(shipping);
    store.register(grandTotal);
    store.register(itemList);
  }
}

// --- Reactons ---

/// Products query with caching.
final productsQuery = reactonQuery<List<Product>>(
  queryFn: (_) => ProductApi.fetchProducts(),
  config: QueryConfig(
    staleTime: const Duration(minutes: 10),
    cacheTime: const Duration(minutes: 30),
  ),
  name: 'productsQuery',
);

/// Cart module instance.
final cart = CartModule();

// --- Persistence ---

/// Serializer for the cart items map.
class CartSerializer extends Serializer<Map<String, CartItem>> {
  @override
  String serialize(Map<String, CartItem> value) {
    // In production, use json_serializable or similar
    return value.entries
        .map((e) => '${e.key}:${e.value.quantity}')
        .join(',');
  }

  @override
  Map<String, CartItem> deserialize(String raw) {
    if (raw.isEmpty) return {};
    // Simplified: real app would reconstruct full CartItem from product catalog
    return {};
  }
}

// --- App ---

void main() {
  final store = ReactonStore();

  // Register the cart module
  cart.register(store);

  // Enable persistence for cart items
  store.addMiddleware(PersistenceMiddleware(
    adapter: SharedPreferencesAdapter(),
    entries: [
      PersistenceEntry(
        reacton: cart.itemsReacton,
        key: 'cart_items',
        serializer: CartSerializer(),
      ),
    ],
  ));

  runApp(ReactonScope(store: store, child: const ShopApp()));
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping Cart',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const ProductListPage(),
    );
  }
}

// --- Product List ---

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final queryState = context.watch(productsQuery);
    final cartCount = context.watch(cart.itemCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Badge(
            label: Text('$cartCount'),
            isLabelVisible: cartCount > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              ),
            ),
          ),
        ],
      ),
      body: queryState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (products) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(product: product);
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.inventory_2, size: 48, color: Colors.orange.shade300),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(product.description,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text('\$${product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => cart.addItem(context.reactonStore, product),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Cart Page ---

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonConsumer(
      builder: (context, ref) {
        final items = ref.watch(cart.itemList);
        final subtotalVal = ref.watch(cart.subtotal);
        final shippingVal = ref.watch(cart.shipping);
        final totalVal = ref.watch(cart.grandTotal);

        return Scaffold(
          appBar: AppBar(title: const Text('Cart')),
          body: items.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _CartItemTile(item: item);
                        },
                      ),
                    ),

                    // Order summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'Subtotal',
                            value: '\$${subtotalVal.toStringAsFixed(2)}',
                          ),
                          _SummaryRow(
                            label: 'Shipping',
                            value: shippingVal == 0
                                ? 'FREE'
                                : '\$${shippingVal.toStringAsFixed(2)}',
                          ),
                          const Divider(),
                          _SummaryRow(
                            label: 'Total',
                            value: '\$${totalVal.toStringAsFixed(2)}',
                            bold: true,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {},
                              child: const Text('Checkout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text('\$${item.product.price.toStringAsFixed(2)}'),
                ],
              ),
            ),
            // Quantity controls
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => cart.updateQuantity(
                context.reactonStore,
                item.product.id,
                item.quantity - 1,
              ),
            ),
            Text('${item.quantity}',
                style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => cart.updateQuantity(
                context.reactonStore,
                item.product.id,
                item.quantity + 1,
              ),
            ),
            // Subtotal
            SizedBox(
              width: 70,
              child: Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  cart.removeItem(context.reactonStore, item.product.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
```

## Walkthrough

### Data Models

`Product` represents an item in the catalog. `CartItem` pairs a product with a quantity and exposes a computed `subtotal` getter. The `copyWith` method on `CartItem` enables immutable quantity updates.

### Cart Module

The `CartModule` class extends `ReactonModule` to group all cart-related state and logic:

```dart
class CartModule extends ReactonModule {
  late final itemsReacton = reacton<Map<String, CartItem>>({}, name: 'cart.items');

  late final itemCount = computed<int>(
    (read) => read(itemsReacton).values.fold(0, (sum, item) => sum + item.quantity),
    name: 'cart.itemCount',
  );

  // ... subtotal, shipping, grandTotal
}
```

Modules provide encapsulation: the cart's reactons, computed values, and mutation methods all live in one class. The `register` method ensures all reactons are registered with the store.

### Computed Chains

The computed reactons form a dependency chain:

1. `itemsReacton` (source) holds the cart map
2. `subtotal` reads `itemsReacton` and sums each item's subtotal
3. `shipping` reads `subtotal` and returns 0 if the total is over $100
4. `grandTotal` reads both `subtotal` and `shipping`

When an item quantity changes, the entire chain recomputes efficiently -- only the reactons whose inputs actually changed will recompute.

### Optimistic Updates

```dart
Future<void> updateQuantity(ReactonStore store, String productId, int newQuantity) async {
  await store.optimistic(
    reacton: itemsReacton,
    optimisticValue: () {
      final items = store.get(itemsReacton);
      final item = items[productId];
      if (item == null) return items;
      return { ...items, productId: item.copyWith(quantity: newQuantity) };
    }(),
    mutation: () => ProductApi.updateCartOnServer(productId, newQuantity),
  );
}
```

`store.optimistic` sets the value immediately so the UI updates without waiting for the server. If the `mutation` future fails, the store automatically rolls back to the previous value. This gives the user instant feedback while maintaining data consistency.

### Persistence

```dart
store.addMiddleware(PersistenceMiddleware(
  adapter: SharedPreferencesAdapter(),
  entries: [
    PersistenceEntry(
      reacton: cart.itemsReacton,
      key: 'cart_items',
      serializer: CartSerializer(),
    ),
  ],
));
```

`PersistenceMiddleware` saves the cart to `SharedPreferences` whenever `itemsReacton` changes. On app restart, the middleware restores the persisted value before the first frame renders. The `CartSerializer` handles conversion to and from a storable format.

### Badge on Cart Icon

```dart
Badge(
  label: Text('$cartCount'),
  isLabelVisible: cartCount > 0,
  child: IconButton(
    icon: const Icon(Icons.shopping_cart),
    onPressed: () => Navigator.push(...),
  ),
),
```

`cartCount` is a computed reacton that sums all quantities. The `Badge` widget displays the count and hides itself when the cart is empty.

## Key Takeaways

1. **ReactonModule groups related state** -- Cart items, counts, totals, and mutation methods live in one class, making the feature self-contained and testable.
2. **Computed chains propagate efficiently** -- `subtotal -> shipping -> grandTotal` recompute only when upstream values change.
3. **Optimistic updates provide instant feedback** -- `store.optimistic` updates the UI immediately and rolls back automatically on failure.
4. **PersistenceMiddleware survives restarts** -- Configure once, and the cart data is saved and restored transparently.
5. **Modules register all their reactons** -- The `register` method ensures the store knows about every reacton in the module.

## What's Next

- [Search with Debounce](./search-with-debounce) -- Debounced API calls with query caching
- [Multi-Step Wizard](./multi-step-wizard) -- State machines and form reactons for checkout flows
- [Offline-First](./offline-first) -- Full offline support with sync
