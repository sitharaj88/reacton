# Performance

Reacton's fine-grained reactive graph is designed for performance out of the box. Most applications will never need to think about optimization. But when you are building complex UIs with hundreds of reactons or rendering large lists, understanding the performance characteristics helps you make informed decisions.

## Selector vs. Computed: When to Use Each

Both `selector` and `computed` produce read-only derived values, but they serve different purposes and have different performance profiles.

### Selector

A selector watches **one specific source** and extracts a sub-value. It is optimized for the common case of plucking a field from a complex object.

```dart
final userNameReacton = selector(
  userReacton,
  (user) => user.name,
  name: 'userName',
);
```

**Use a selector when:**
- You have a complex object (User, Settings, Order) and widgets only need one field
- You want to prevent rebuilds when unrelated fields of the same object change
- The derivation is a simple field access or a trivial transformation

### Computed

A computed reacton can read from **any number of sources** and perform arbitrary logic to derive its value.

```dart
final cartTotalReacton = computed((read) {
  final items = read(cartItemsReacton);
  final discount = read(discountReacton);
  final tax = read(taxRateReacton);
  final subtotal = items.fold(0.0, (s, i) => s + i.price * i.qty);
  return (subtotal - discount) * (1 + tax);
}, name: 'cartTotal');
```

**Use a computed when:**
- The derived value depends on multiple sources
- The derivation involves logic beyond simple field access
- You need conditional dependency tracking (reading different sources based on conditions)

### Performance Comparison

| Aspect | Selector | Computed |
|---|---|---|
| Number of sources | Exactly 1 | Any number |
| Dependency tracking | Static (always the same source) | Dynamic (re-tracked on each computation) |
| Typical cost per recompute | Very low (field access) | Varies (depends on computation) |
| When to reach for it | Plucking fields from objects | Combining or transforming multiple sources |

::: tip
When in doubt, use `computed`. It is the more general tool. Use `selector` when you identify a specific field-plucking pattern and want to be explicit about the single-source dependency.
:::

## Batching Strategies

Every call to `store.set()` triggers graph propagation. If you set multiple reactons in sequence, each set triggers its own propagation cycle, which can cause computed values to recompute multiple times and widgets to rebuild multiple times.

### The Problem

```dart
// Without batching: 3 separate propagation cycles
store.set(firstNameReacton, 'Jane');   // fullNameReacton recomputes
store.set(lastNameReacton, 'Smith');   // fullNameReacton recomputes again
store.set(emailReacton, 'j@s.com');   // emailDisplayReacton recomputes
```

### The Solution: Batch

```dart
// With batching: 1 propagation cycle
store.batch(() {
  store.set(firstNameReacton, 'Jane');
  store.set(lastNameReacton, 'Smith');
  store.set(emailReacton, 'j@s.com');
  // All computed values recompute once, with consistent state
});
```

### When to Batch

| Scenario | Batch? |
|---|---|
| Setting multiple related reactons from one user action | Yes |
| Restoring state from a snapshot or API response | Yes |
| Setting a single reacton | No (unnecessary) |
| Setting reactons in separate event handlers | No (they are independent) |
| Initializing state in `onInit` | Yes, if setting multiple values |

### Nested Batches

Batches can be nested. The outer batch boundary is what matters -- propagation happens only after the outermost batch completes.

```dart
store.batch(() {
  store.set(a, 1);
  store.batch(() {  // Nested -- still part of outer batch
    store.set(b, 2);
    store.set(c, 3);
  });
  store.set(d, 4);
  // Propagation happens here, after the outer batch
});
```

## Avoiding Unnecessary Recomputation

### Equality Gating

By default, Reacton uses Dart's `==` operator to compare values. A set that produces an equal value is a no-op. For custom objects, ensure your equality operator is correct:

```dart
class User {
  final String name;
  final String email;

  const User({required this.name, required this.email});

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is User && name == other.name && email == other.email;

  @override
  int get hashCode => Object.hash(name, email);
}
```

### Custom Equality for Collections

Dart's default `==` for `List` and `Map` is reference equality, not deep equality. This means setting a list reacton to a new list with the same contents will trigger propagation. If this is a problem, provide a custom equality:

```dart
import 'package:collection/collection.dart';

final todosReacton = reacton<List<Todo>>(
  [],
  name: 'todos',
  options: ReactonOptions<List<Todo>>(
    equals: (a, b) => const ListEquality().equals(a, b),
  ),
);
```

::: warning
Deep equality on large collections can be expensive. Profile before adding it blindly. Sometimes it is cheaper to let the propagation happen and let widgets handle the comparison.
:::

### The keepAlive Option

By default, computed reactons may have their values garbage collected when no watchers remain. The `keepAlive` option prevents this:

```dart
final expensiveComputation = computed(
  (read) {
    // This takes 50ms to compute
    return heavyDataProcessing(read(rawDataReacton));
  },
  name: 'expensiveResult',
  options: ReactonOptions<ProcessedData>(keepAlive: true),
);
```

**Use `keepAlive: true` when:**
- The computation is expensive and you want to preserve the cached result
- The reacton is used across multiple screens (navigating away and back should not recompute)

**Avoid `keepAlive: true` when:**
- The reacton holds large data that should be released when no longer needed
- You have many parameterized reactons (via `family`) that should be cleaned up

## Memory Management

### Auto-Dispose

When a widget that watches a reacton is unmounted and no other watchers remain, the reacton's subscription is cleaned up automatically. For computed reactons without `keepAlive`, this means the computed value can be reclaimed.

### Manual Cleanup for Families

`family()` caches reacton instances by argument. Over time, this cache can grow unbounded if arguments are dynamic (e.g., user IDs from pagination). Clean up explicitly:

```dart
// Remove a single cached instance
userReacton.remove(42);

// Clear all cached instances
userReacton.clear();
```

A good pattern is to clean up when navigating away from a detail screen:

```dart
@override
void dispose() {
  // Remove the cached reacton for this user
  userByIdReacton.remove(widget.userId);
  super.dispose();
}
```

### Module Uninstallation

When a module is uninstalled, all its registered reactons are removed from the store:

```dart
store.uninstallModule<CartModule>();
// All cart reactons are removed, subscriptions cleaned up
```

This is useful for feature modules that should release resources when the user navigates away from that feature.

## Profiling with DevTools

The Reacton DevTools extension provides several views for performance analysis.

### Timeline Tab

The timeline shows every state mutation and propagation in chronological order:

- **Mutation markers**: Each `store.set()` call appears as a marker with the reacton name and old/new values
- **Propagation waves**: You can see which computed values recomputed and how long each took
- **Batch boundaries**: Batched mutations are grouped visually

**What to look for:**
- Rapid consecutive mutations that should be batched
- Computed values recomputing more often than expected
- Long propagation chains (deep dependency graphs)

### Graph Tab

The graph view shows the reactive dependency graph:

- **Node size**: Proportional to the number of subscribers
- **Edge color**: Green for active dependencies, gray for stale
- **Highlight path**: Click a node to highlight all its upstream dependencies and downstream subscribers

**What to look for:**
- Nodes with many incoming edges (potential bottlenecks)
- Unexpectedly long dependency chains
- Disconnected subgraphs (might indicate unused state)

### Values Tab

Real-time view of all reacton values in the store:

- Current value for each reacton
- Last update timestamp
- Subscriber count

**What to look for:**
- Reactons with zero subscribers that are still being updated (wasted computation)
- Large values that could be broken into smaller reactons

## Large Collection Optimization

When working with lists of hundreds or thousands of items, consider these strategies:

### 1. Use Observable Collections

Instead of storing lists in a plain reacton, use `reactonList` which emits granular change events:

```dart
final items = reactonList<Item>([], name: 'items');

// Adding an item emits only an "insert" event, not a full list replacement
store.get(items).add(newItem);
```

### 2. Paginate with Families

Instead of loading all items into one reacton, paginate using families:

```dart
final itemPageReacton = family<AsyncValue<List<Item>>, int>((page) {
  return asyncReacton(
    (read) => api.getItems(page: page, limit: 20),
    name: 'items.page_$page',
  );
});
```

### 3. Virtual Scrolling

For long lists, use Flutter's `ListView.builder` and only watch the reactons that are currently visible:

```dart
ListView.builder(
  itemCount: itemIds.length,
  itemBuilder: (context, index) {
    return ReactonBuilder(
      builder: (context) {
        final item = context.watch(itemByIdReacton(itemIds[index]));
        return ItemTile(item: item);
      },
    );
  },
);
```

Each `ReactonBuilder` creates an independent subscription, so only the visible items are watched.

### 4. Avoid Expensive Computed Values on Large Lists

If you need to filter or sort a large list, consider whether the computation can be done lazily or incrementally rather than recomputing from scratch:

```dart
// Potentially expensive: sorts the entire list on every change
final sortedItemsReacton = computed((read) {
  final items = read(allItemsReacton);
  return List.of(items)..sort((a, b) => a.name.compareTo(b.name));
}, name: 'sortedItems');

// Better: use a selector on the sort key to avoid re-sorting when
// non-sort-relevant fields change
final sortedItemsReacton = computed((read) {
  final items = read(allItemsReacton);
  final sortKey = read(sortKeyReacton);
  return List.of(items)..sort((a, b) => a.compareBy(sortKey, b));
}, name: 'sortedItems',
  options: ReactonOptions(
    equals: (a, b) => const ListEquality().equals(a, b),
  ),
);
```

## Performance Checklist

Use this checklist when auditing your application's performance:

- [ ] Are multi-field updates wrapped in `store.batch()`?
- [ ] Are computed values reading only the reactons they need (not entire parent objects)?
- [ ] Are selectors used for field plucking from complex objects?
- [ ] Do custom data classes implement `==` and `hashCode` correctly?
- [ ] Are `family()` caches cleaned up when entries are no longer needed?
- [ ] Are expensive computations guarded with `keepAlive: true`?
- [ ] Are large lists handled with pagination, virtual scrolling, or observable collections?
- [ ] Is the DevTools timeline free of unexpected rapid-fire propagation?

## What's Next

- [Debugging](/architecture/debugging) -- Using DevTools and logging to diagnose issues
- [Scaling to Enterprise](/architecture/scaling) -- Performance at scale with 1000+ reactons
