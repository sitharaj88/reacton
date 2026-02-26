# Glossary

An alphabetical reference of every term used in the Reacton documentation. Each entry includes a concise definition, the relevant API, and a cross-reference to the page where the concept is explained in depth.

---

## AsyncValue

A discriminated union type that represents the lifecycle of an asynchronous operation. It has three states: `loading`, `data(value)`, and `error(error, stackTrace)`. Used as the value type for `asyncReacton` and `QueryReacton`.

```dart
final users = asyncReacton<List<User>>(
  (read) => api.fetchUsers(),
  name: 'users',
);

// In a widget:
final value = context.watch(users); // AsyncValue<List<User>>
value.when(
  loading: () => CircularProgressIndicator(),
  data: (users) => UserList(users),
  error: (e, st) => ErrorWidget(e),
);
```

**See:** [Async Reactons](/async/async-reacton)

---

## Batch

An operation that groups multiple state mutations into a single atomic transaction. During a batch, the reactive graph delays propagation until all mutations are complete, ensuring that computed values and widgets observe only the final, consistent state.

```dart
store.batch(() {
  store.set(firstNameReacton, 'Jane');
  store.set(lastNameReacton, 'Smith');
  // fullNameReacton recomputes once, not twice
});
```

**API:** `ReactonStore.batch(void Function() fn)`
**See:** [Core Concepts](/guide/core-concepts), [Performance](/architecture/performance)

---

## Branch (State Branch)

An isolated, copy-on-write overlay on the parent store. Changes made to a branch do not affect the parent until explicitly merged. Useful for speculative updates, A/B testing, and preview features.

```dart
final branch = store.createBranch('dark-theme-preview');
branch.set(themeReacton, ThemeData.dark());
// Parent store is unchanged
store.mergeBranch(branch); // Now the parent has the dark theme
```

**API:** `StateBranch`, `store.createBranch()`, `store.mergeBranch()`
**See:** [State Branching](/advanced/branching)

---

## Computed

A read-only reacton whose value is automatically derived from one or more other reactons. The compute function re-runs only when its dependencies change, and only if the result differs from the current value (equality gating). Computed reactons are lazy -- they do not compute until first read.

```dart
final totalReacton = computed(
  (read) => read(priceReacton) * read(quantityReacton),
  name: 'total',
);
```

**API:** `computed<T>(T Function(ReactonReader read) compute, {String? name})`
**See:** [Core Concepts](/guide/core-concepts)

---

## CRDT (Conflict-free Replicated Data Type)

A data structure that can be replicated across multiple nodes and merged without conflicts. Reacton's collaborative module uses CRDTs with vector clocks for distributed state synchronization. Built-in merge strategies include `LastWriterWins`, `MaxValue` (GCounter), `UnionMerge` (GSet), and `CustomMerge`.

**API:** `VectorClock`, `CrdtValue`, `CrdtMergeStrategy`, `CollaborativeSession`
**See:** [Collaborative (CRDT)](/advanced/collaborative)

---

## Effect

A side effect that runs whenever its reactive dependencies change. Effects are registered with a store and can optionally return a cleanup function that runs before the effect re-executes or when it is disposed.

```dart
final dispose = store.registerEffect(
  createEffect((read) {
    final count = read(counterReacton);
    print('Counter: $count');
    return () => print('Cleanup');
  }, name: 'logCounter'),
);
```

**API:** `createEffect()`, `store.registerEffect()`
**See:** [Core Concepts](/guide/core-concepts)

---

## Family

A factory that produces a distinct reacton instance for each unique argument. Results are cached: calling `family(42)` twice returns the same instance. Useful for parameterized data fetching.

```dart
final userReacton = family<AsyncValue<User>, int>((userId) {
  return asyncReacton((read) => api.getUser(userId), name: 'user_$userId');
});

// In a widget:
final user = context.watch(userReacton(42));
```

**API:** `family<T, Arg>(ReactonBase<T> Function(Arg) create)`
**See:** [Core Concepts](/guide/core-concepts)

---

## Glitch-Free

A property of the reactive graph engine guaranteeing that no computed value or widget subscriber ever observes an inconsistent intermediate state during propagation. Achieved through topological-order processing in the two-phase mark/propagate algorithm.

**See:** [Core Concepts](/guide/core-concepts), [Thinking in Reacton](/guide/thinking-in-reacton)

---

## Graph (Reactive Graph)

The underlying directed acyclic graph (DAG) that tracks dependencies between reactons, computed values, selectors, effects, and widget subscribers. The graph is managed by the `ReactiveGraph` class and is accessed via `store.graph` for DevTools and testing.

**API:** `ReactiveGraph`, `store.graph`
**See:** [Core Concepts](/guide/core-concepts), [Debugging](/architecture/debugging)

---

## Interceptor

A lightweight mechanism for transforming or rejecting reacton updates. Simpler than middleware, interceptors provide `onWrite` (transform before write), `onRead` (transform on read), and `shouldUpdate` (gate function to reject updates).

```dart
final clampInterceptor = Interceptor<int>(
  name: 'clamp',
  onWrite: (value) => value.clamp(0, 100),
  shouldUpdate: (old, next) => old != next,
);
```

**API:** `Interceptor<T>`, `InterceptorChain<T>`
**See:** [Interceptors](/advanced/interceptors)

---

## Lens

A bidirectional, composable optic that focuses on part of a reacton's state. A lens can both read a sub-value and write it back, propagating changes through the reactive graph. Lenses compose -- you can chain `.then()` to drill into deeply nested structures.

```dart
final nameLens = lens(userReacton, (u) => u.name, (u, n) => u.copyWith(name: n));
store.read(nameLens);         // 'Alice'
store.write(nameLens, 'Bob'); // Updates userReacton
```

**API:** `lens()`, `listLens()`, `mapLens()`, `filteredListLens()`, `ReactonLens`
**See:** [Lenses](/advanced/lenses)

---

## Middleware

An abstract class that intercepts reacton lifecycle events: initialization, reads, writes, and disposal. Middleware is used for cross-cutting concerns like logging, validation, persistence, and analytics. Can be applied globally to all reactons or per-reacton via `ReactonOptions`.

```dart
class ValidationMiddleware<T> extends Middleware<T> {
  @override
  T onBeforeWrite(ReactonBase<T> reacton, T currentValue, T newValue) {
    if (newValue == null) throw ArgumentError('Value cannot be null');
    return newValue;
  }
}
```

**API:** `Middleware<T>`, `LoggingMiddleware`, `ReactonOptions.middleware`
**See:** [Middleware](/advanced/middleware)

---

## Module

A grouping mechanism for related reactons with lifecycle management. Modules provide namespace isolation, `onInit`/`onDispose` hooks, lazy initialization, and clean uninstallation. Designed for large teams where different groups own different domains.

```dart
class AuthModule extends ReactonModule {
  @override
  String get name => 'auth';
  late final user = register(reacton<User?>(null, name: 'auth.user'));
  late final isLoggedIn = register(computed(
    (read) => read(user) != null, name: 'auth.isLoggedIn',
  ));
}
```

**API:** `ReactonModule`, `store.installModule()`, `store.module<T>()`
**See:** [Modules](/advanced/modules)

---

## Persistence

The ability to automatically save and restore reacton values across app restarts. Configured via `ReactonOptions.persistKey` and `ReactonOptions.serializer`, backed by a `StorageAdapter` plugged into the `ReactonStore`.

```dart
final counterReacton = reacton(0, options: ReactonOptions(
  persistKey: 'counter',
  serializer: intSerializer,
));
final store = ReactonStore(storageAdapter: SharedPrefsAdapter());
```

**API:** `StorageAdapter`, `Serializer<T>`, `ReactonOptions.persistKey`
**See:** [Persistence](/advanced/persistence)

---

## Query (QueryReacton)

A specialized async reacton with built-in support for caching, automatic refresh, retry policies, and stale-while-revalidate semantics. Ideal for API data fetching.

**API:** `QueryReacton`
**See:** [Query Reactons](/async/query-reacton)

---

## Reacton

The fundamental building block of the Reacton library. A writable reactive state container created with the `reacton()` function. Each reacton has a unique identity (`ReactonRef`), an initial value, and optional configuration. The name "reacton" comes from combining "reactive" and "atom."

```dart
final counterReacton = reacton(0, name: 'counter');
```

**API:** `reacton<T>()`, `WritableReacton<T>`
**See:** [Core Concepts](/guide/core-concepts)

---

## Ref (ReactonRef)

The unique identity of a reacton within the store. A ref consists of an auto-incremented integer `id` and an optional `debugName`. Two reacton declarations always produce distinct refs, even with identical initial values. Refs are used internally as map keys in the store.

```dart
final a = reacton(0, name: 'a');
final b = reacton(0, name: 'b');
assert(a.ref != b.ref); // Different identities
```

**API:** `ReactonRef`
**See:** [Core Concepts](/guide/core-concepts)

---

## Saga

A declarative workflow orchestrator inspired by Redux-Saga. Sagas handle complex asynchronous flows using imperative-style handlers with cancellation-aware effects like `take`, `put`, `call`, `fork`, `join`, `delay`, `race`, and `all`. Four concurrency strategies are supported: `takeOnce`, `takeEvery`, `takeLatest`, and `takeLeading`.

```dart
final authSaga = saga<AuthEvent>(
  name: 'auth',
  builder: (on) {
    on.onLatest<LoginRequested>((ctx, event) async {
      ctx.put(statusReacton, AuthStatus.loading);
      final user = await ctx.call(() => api.login(event.credentials));
      ctx.put(userReacton, user);
    });
  },
);
```

**API:** `saga<E>()`, `SagaContext`, `SagaTask`, `SagaBuilder`
**See:** [Sagas](/advanced/sagas)

---

## Selector

A read-only reacton that watches a sub-value of another reacton. Only triggers updates when the selected portion changes, providing more granular subscriptions than watching the entire source.

```dart
final userNameReacton = selector(
  userReacton,
  (user) => user.name,
  name: 'userName',
);
```

**API:** `selector<T, S>(ReactonBase<T> source, S Function(T) select)`
**See:** [Core Concepts](/guide/core-concepts)

---

## Snapshot

An immutable capture of all current reacton values in a store at a point in time. Used for time-travel debugging, regression testing, and state restoration. Snapshots can be compared via diffs to identify what changed.

```dart
final snap = store.snapshot();
// ... make changes ...
store.restore(snap); // Roll back to the snapshot state
```

**API:** `StoreSnapshot`, `store.snapshot()`, `store.restore()`
**See:** [Snapshots & Diffs](/advanced/snapshots)

---

## Store (ReactonStore)

The central value container for all reactons. The store holds values, manages subscriptions, bridges your code with the reactive graph engine, and provides APIs for reading, writing, batching, snapshotting, and restoring state. Every Reacton application has at least one store.

```dart
final store = ReactonStore(
  storageAdapter: myAdapter,
  globalMiddleware: [loggingMiddleware],
);
```

**API:** `ReactonStore`
**See:** [Core Concepts](/guide/core-concepts)

---

## Sync (Synchronization)

The process of keeping state consistent across distributed nodes using the CRDT protocol. Sync uses a wire protocol with four message types: `SyncFull` (complete state), `SyncDelta` (incremental update), `SyncAck` (acknowledgment), and `SyncRequestFull` (request for full state). Transport is abstracted via `SyncChannel`.

**API:** `SyncMessage`, `SyncChannel`, `SyncStatus`
**See:** [Collaborative (CRDT)](/advanced/collaborative)
