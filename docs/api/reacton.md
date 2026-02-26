# Core Package API (`reacton`)

Complete API reference for the `reacton` package -- the core reactive graph engine for Dart.

```dart
import 'package:reacton/reacton.dart';
```

---

## Factory Functions

Top-level functions for creating reactons and effects.

| Function | Signature | Description |
|----------|-----------|-------------|
| `reacton<T>()` | `WritableReacton<T> reacton<T>(T initialValue, {String? name, ReactonOptions<T>? options, void Function(void Function<V>(WritableReacton<V>, V) set, T value)? onWrite})` | Create a writable reacton with an initial value |
| `computed<T>()` | `ReadonlyReacton<T> computed<T>(T Function(ReactonReader read) compute, {String? name, ReactonOptions<T>? options})` | Create a computed (derived) reacton |
| `selector<T, S>()` | `SelectorReacton<T, S> selector<T, S>(ReactonBase<T> source, S Function(T) select, {String? name, ReactonOptions<S>? options})` | Create a selector that watches a sub-value of another reacton |
| `family<T, Arg>()` | `ReactonFamily<T, Arg> family<T, Arg>(ReactonBase<T> Function(Arg arg) create)` | Create a family of parameterized reactons |
| `asyncReacton<T>()` | `AsyncReacton<T> asyncReacton<T>(Future<T> Function(ReactonReader read) fetch, {String? name, RetryPolicy? retryPolicy, Duration? refreshInterval})` | Create an async reacton that fetches data |
| `reactonQuery<T>()` | `QueryReacton<T> reactonQuery<T>({required Future<T> Function(QueryContext<void>) queryFn, QueryConfig config, String? name})` | Create a query reacton with caching |
| `reactonQueryFamily<T, Arg>()` | `QueryFamily<T, Arg> reactonQueryFamily<T, Arg>({required Future<T> Function(QueryContext<Arg>) queryFn, QueryConfig config, String? name})` | Create a family of query reactons |
| `createEffect()` | `EffectNode createEffect(EffectCleanup? Function(ReactonReader read) fn, {String? name})` | Create a side effect with automatic dependency tracking |
| `stateMachine<S, E>()` | `StateMachineReacton<S, E> stateMachine<S, E>({required S initial, required Map<S, Map<E, TransitionHandler<S>>> transitions, Map<E, TransitionGuard<S>>? guards, TransitionEffect<S>? onTransition, String? name, ReactonOptions<S>? options})` | Create a state machine with typed states and events |

---

## Core Classes

### ReactonBase\<T\>

Abstract base class for all reactons. Provides identity (`ref`) and equality checking.

| Member | Type | Description |
|--------|------|-------------|
| `ref` | `ReactonRef` | Unique identity of this reacton |
| `options` | `ReactonOptions<T>?` | Configuration options |
| `equals(a, b)` | `bool` | Check if two values are equal (uses custom equality if configured) |

### WritableReacton\<T\>

A read-write reactive state container. Extends `ReactonBase<T>`.

| Member | Type | Description |
|--------|------|-------------|
| `initialValue` | `T` | The initial value before any writes |
| `onWrite` | `void Function(void Function<V>(WritableReacton<V>, V) set, T value)?` | Optional custom write handler |

### ReadonlyReacton\<T\>

A read-only reacton that derives its value from other reactons. Extends `ReactonBase<T>`.

| Member | Type | Description |
|--------|------|-------------|
| `compute` | `T Function(ReactonReader read)` | The computation function that derives the value |

### SelectorReacton\<T, S\>

A selector that watches a sub-value of another reacton. Extends `ReadonlyReacton<S>`.

| Member | Type | Description |
|--------|------|-------------|
| `source` | `ReactonBase<T>` | The source reacton being selected from |
| `select` | `S Function(T)` | The selector function that extracts the sub-value |

### ReactonFamily\<T, Arg\>

A factory that creates parameterized reactons on-demand.

| Member | Type | Description |
|--------|------|-------------|
| `call(arg)` | `ReactonBase<T>` | Get or create the reacton for the given argument |
| `contains(arg)` | `bool` | Check if a reacton exists for the argument |
| `remove(arg)` | `void` | Remove the cached reacton for the argument |
| `clear()` | `void` | Remove all cached reactons |
| `keys` | `Iterable<Arg>` | All currently cached arguments |
| `reactons` | `Iterable<ReactonBase<T>>` | All currently cached reactons |

### ReactonRef

Unique identity for a reacton, used as a key in the store.

| Member | Type | Description |
|--------|------|-------------|
| `id` | `int` | Unique numeric identifier |
| `debugName` | `String?` | Optional debug name for DevTools and logging |

### ReactonOptions\<T\>

Configuration options for reactons.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `keepAlive` | `bool` | `false` | Keep the value even when no watchers remain |
| `debounce` | `Duration?` | `null` | Debounce writes by this duration |
| `serializer` | `Serializer<T>?` | `null` | Serializer for persistence |
| `persistKey` | `String?` | `null` | Key for persistent storage |
| `middleware` | `List<Middleware<T>>` | `const []` | Middleware chain applied to this reacton |
| `equals` | `bool Function(T, T)?` | `null` | Custom equality function (uses `==` by default) |

### ReactonReader

Type alias for the reader function used by computed reactons and effects:

```dart
typedef ReactonReader = T Function<T>(ReactonBase<T> reacton);
```

---

## Store

### ReactonStore

The central value container for all reactons.

| Constructor | Description |
|-------------|-------------|
| `ReactonStore({StorageAdapter? storageAdapter, List<Middleware>? globalMiddleware})` | Create a new store with optional storage and middleware |

#### Read Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `get<T>()` | `T get<T>(ReactonBase<T> reacton)` | Read the current value (lazy-initializes if needed) |
| `getByRef()` | `dynamic getByRef(ReactonRef ref)` | Read a value by ReactonRef (internal use) |

#### Write Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `set<T>()` | `void set<T>(WritableReacton<T> reacton, T value)` | Set a writable reacton's value (triggers propagation) |
| `update<T>()` | `void update<T>(WritableReacton<T> reacton, T Function(T) updater)` | Update using a function |
| `forceSet<T>()` | `void forceSet<T>(ReactonBase<T> reacton, T value)` | Force-set without middleware (for testing) |
| `setByRefId()` | `void setByRefId(int refId, dynamic value)` | Set by ref ID (for DevTools) |

#### Subscribe

| Method | Signature | Description |
|--------|-----------|-------------|
| `subscribe<T>()` | `Unsubscribe subscribe<T>(ReactonBase<T> reacton, void Function(T) listener)` | Subscribe to value changes; returns an unsubscribe function |

#### Effects

| Method | Signature | Description |
|--------|-----------|-------------|
| `registerEffect()` | `Unsubscribe registerEffect(EffectNode effect)` | Register an effect; returns a dispose function |

#### Batch

| Method | Signature | Description |
|--------|-----------|-------------|
| `batch()` | `void batch(void Function() fn)` | Execute mutations atomically (all propagation deferred to end) |

#### Snapshot

| Method | Signature | Description |
|--------|-----------|-------------|
| `snapshot()` | `StoreSnapshot snapshot()` | Take an immutable snapshot of all current values |
| `restore()` | `void restore(StoreSnapshot snapshot)` | Restore state from a snapshot |

#### Removal

| Method | Signature | Description |
|--------|-----------|-------------|
| `remove()` | `void remove(ReactonRef ref)` | Remove a reacton from the store |
| `dispose()` | `void dispose()` | Dispose the entire store (cleans up all effects, listeners, values) |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `graph` | `ReactiveGraph` | The reactive graph (exposed for DevTools and testing) |
| `storageAdapter` | `StorageAdapter?` | The storage adapter (if configured) |
| `reactonRefs` | `Iterable<ReactonRef>` | All registered reacton refs |
| `reactonCount` | `int` | Number of reactons in the store |

### StoreSnapshot

An immutable snapshot of all reacton values.

| Member | Type | Description |
|--------|------|-------------|
| `values` | `Map<ReactonRef, dynamic>` | Unmodifiable map of ref to value |

---

## Async

### AsyncValue\<T\>

Sealed class representing the state of an asynchronous operation.

| Subclass | Description |
|----------|-------------|
| `AsyncLoading<T>` | Operation in progress (optional `previousData`) |
| `AsyncData<T>` | Operation completed with `value` |
| `AsyncError<T>` | Operation failed with `error`, `stackTrace`, optional `previousData` |

| Method | Signature | Description |
|--------|-----------|-------------|
| `when<R>()` | `R when<R>({required R Function() loading, required R Function(T) data, required R Function(Object, StackTrace?) error})` | Pattern match on the three states |
| `whenOrElse<R>()` | `R whenOrElse<R>({...})` | Pattern match with optional handlers and `orElse` fallback |
| `map<R>()` | `AsyncValue<R> map<R>(R Function(T) transform)` | Map the data value to a new type |

| Property | Type | Description |
|----------|------|-------------|
| `valueOrNull` | `T?` | Data value or null (includes stale data from loading/error states) |
| `isLoading` | `bool` | Whether currently loading |
| `hasData` | `bool` | Whether in data state |
| `hasError` | `bool` | Whether in error state |
| `hasValue` | `bool` | Whether any data exists (current or stale) |

### AsyncReacton\<T\>

An async reacton that manages an `AsyncValue<T>`. Extends `ReactonBase<AsyncValue<T>>`.

| Member | Type | Description |
|--------|------|-------------|
| `fetch` | `Future<T> Function(ReactonReader read)` | The async fetch function |
| `retryPolicy` | `RetryPolicy?` | Retry policy for failed fetches |
| `refreshInterval` | `Duration?` | Auto-refresh interval |
| `cancelOnDispose` | `bool` | Cancel in-flight requests on dispose (default: `true`) |

### QueryReacton\<T\>

A query reacton with smart caching. Extends `WritableReacton<AsyncValue<T>>`.

| Member | Type | Description |
|--------|------|-------------|
| `queryFn` | `Future<T> Function(QueryContext<void>)` | The query function |
| `config` | `QueryConfig` | Query configuration |

### QueryConfig

Configuration for query reactons.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `staleTime` | `Duration` | `5 minutes` | How long data is fresh before becoming stale |
| `cacheTime` | `Duration` | `30 minutes` | How long unused data stays in cache |
| `refetchOnReconnect` | `bool` | `false` | Refetch when connectivity is restored |
| `refetchOnResume` | `bool` | `false` | Refetch when app returns to foreground |
| `pollingInterval` | `Duration?` | `null` | Polling interval |
| `retryPolicy` | `RetryPolicy?` | `null` | Retry policy for failed queries |

### QueryFamily\<T, Arg\>

A family of query reactons parameterized by an argument.

| Method | Signature | Description |
|--------|-----------|-------------|
| `call(arg)` | `QueryReacton<T>` | Get or create a query reacton for the argument |
| `remove(arg)` | `void` | Remove a cached query |
| `clear()` | `void` | Clear all cached queries |
| `cachedArgs` | `Iterable<Arg>` | All currently cached arguments |

### Store Query Extensions

Extensions on `ReactonStore` for query operations:

| Method | Signature | Description |
|--------|-----------|-------------|
| `fetchQuery<T>()` | `Future<T>` | Fetch a query (returns cached if fresh, background refetch if stale) |
| `invalidateQuery<T>()` | `Future<void>` | Mark stale and force refetch |
| `prefetchQuery<T>()` | `Future<void>` | Prefetch so it is cached when needed |
| `setQueryData<T>()` | `void` | Manually set query data (for optimistic updates) |
| `removeQuery<T>()` | `void` | Remove a query from the cache |
| `invalidateAllQueries()` | `void` | Invalidate all queries |

### RetryPolicy

Policy for retrying failed async operations.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `maxAttempts` | `int` | `3` | Maximum retry attempts |
| `initialDelay` | `Duration` | `1 second` | Initial delay before first retry |
| `backoffMultiplier` | `double` | `2.0` | Exponential backoff multiplier |
| `maxDelay` | `Duration?` | `null` | Maximum delay between retries |
| `shouldRetry` | `bool Function(Object)?` | `null` | Custom function to determine if an error should be retried |

| Method | Signature | Description |
|--------|-----------|-------------|
| `delayForAttempt(attempt)` | `Duration` | Calculate delay for a given attempt number |
| `canRetry(error, attempt)` | `bool` | Whether the error should be retried |

---

## Effects

### EffectNode

An effect that runs side effects when dependencies change.

| Member | Type | Description |
|--------|------|-------------|
| `ref` | `ReactonRef` | Unique identity for this effect |
| `cleanup` | `EffectCleanup?` | Cleanup function from the last run |
| `run(read)` | `EffectCleanup? Function(ReactonReader)` | Execute the effect |

### EffectCleanup

```dart
typedef EffectCleanup = void Function();
```

---

## Middleware

### Middleware\<T\>

Abstract base class for reacton middleware.

| Method | Signature | Description |
|--------|-----------|-------------|
| `onInit(reacton, initialValue)` | `T` | Called on initialization; return the (possibly modified) initial value |
| `onBeforeWrite(reacton, currentValue, newValue)` | `T` | Called before write; return the (possibly modified) value or throw to reject |
| `onAfterWrite(reacton, value)` | `void` | Called after write and propagation |
| `onDispose(reacton)` | `void` | Called on disposal |
| `onError(reacton, error, stackTrace)` | `void` | Called on computation error |

---

## Persistence

### Serializer\<T\>

Abstract interface for serializing/deserializing reacton values.

| Method | Signature | Description |
|--------|-----------|-------------|
| `serialize(value)` | `String` | Serialize a value to a string |
| `deserialize(data)` | `T` | Deserialize a string to a value |

### Built-in Serializers

| Class | Description |
|-------|-------------|
| `JsonSerializer<T>` | For types with `toJson()` / `fromJson()` |
| `PrimitiveSerializer<T>` | For `int`, `double`, `String`, `bool` |
| `EnumSerializer<T>` | For `Enum` types |
| `ListSerializer<T>` | For `List<T>` with an item serializer |

### StorageAdapter

Abstract interface for persistent storage backends.

| Method | Signature | Description |
|--------|-----------|-------------|
| `read(key)` | `String?` | Read a value by key |
| `write(key, value)` | `Future<void>` | Write a value |
| `delete(key)` | `Future<void>` | Delete a value |
| `containsKey(key)` | `bool` | Check if a key exists |
| `clear()` | `Future<void>` | Clear all stored values |

### MemoryStorage

In-memory `StorageAdapter` implementation (non-persistent, for testing).

---

## History

### History\<T\>

Time-travel controller for a reacton. Records all value changes and provides undo/redo/jumpTo.

| Method / Property | Signature | Description |
|-------------------|-----------|-------------|
| `entries` | `List<HistoryEntry<T>>` | All history entries (unmodifiable) |
| `currentIndex` | `int` | Current position in history |
| `canUndo` | `bool` | Whether undo is available |
| `canRedo` | `bool` | Whether redo is available |
| `length` | `int` | Total entry count |
| `currentValue` | `T` | The current value |
| `undo()` | `void` | Go back one step |
| `redo()` | `void` | Go forward one step |
| `jumpTo(index)` | `void` | Jump to a specific index |
| `clear()` | `void` | Clear history and start fresh |
| `dispose()` | `void` | Dispose the controller |

### HistoryEntry\<T\>

A single entry in the history log.

| Field | Type | Description |
|-------|------|-------------|
| `value` | `T` | The value at this point |
| `timestamp` | `DateTime` | When recorded |
| `label` | `String?` | Optional label |

### Store History Extension

| Method | Signature | Description |
|--------|-----------|-------------|
| `enableHistory<T>()` | `History<T> enableHistory<T>(WritableReacton<T> reacton, {int maxHistory = 100})` | Enable time-travel for a reacton |

---

## Branching

### StateBranch

An isolated copy-on-write overlay on the parent store.

| Method / Property | Signature | Description |
|-------------------|-----------|-------------|
| `name` | `String` | Branch name |
| `parentStore` | `ReactonStore` | The parent store |
| `createdAt` | `DateTime` | Creation timestamp |
| `isClosed` | `bool` | Whether merged or discarded |
| `isMerged` | `bool` | Whether merged |
| `isDiscarded` | `bool` | Whether discarded |
| `get<T>(reacton)` | `T` | Read (checks overrides first, then parent) |
| `set<T>(reacton, value)` | `void` | Write (only modifies branch) |
| `update<T>(reacton, updater)` | `void` | Update using a function |
| `modifiedReactons` | `Set<ReactonRef>` | All modified reacton refs |
| `diff()` | `BranchDiff` | Get all differences from parent |
| `discard()` | `void` | Discard the branch |

### MergeStrategy

| Value | Description |
|-------|-------------|
| `theirs` | Use the branch's values (default) |
| `ours` | Keep the parent's values |

### Store Branching Extension

| Method | Signature | Description |
|--------|-----------|-------------|
| `createBranch(name)` | `StateBranch` | Create a new branch |
| `mergeBranch(branch, {strategy})` | `void` | Merge a branch into the store |

---

## State Machine

### StateMachineReacton\<S, E\>

A state machine with typed states and events. Extends `ReactonBase<S>`.

| Member | Type | Description |
|--------|------|-------------|
| `initial` | `S` | Initial state |
| `transitions` | `Map<S, Map<E, TransitionHandler<S>>>` | Transition map |
| `guards` | `Map<E, TransitionGuard<S>>?` | Guard functions |
| `onTransition` | `TransitionEffect<S>?` | Side effect on transition |
| `stateReacton` | `WritableReacton<S>` | The underlying writable reacton |
| `isTransitioning` | `bool` | Whether an async transition is in progress |
| `validEvents(state)` | `Set<E>` | Valid events for a given state |
| `canHandle(state, event)` | `bool` | Check if an event is valid |

### Type Aliases

```dart
typedef TransitionHandler<S> = FutureOr<S> Function(TransitionContext<S> context);
typedef TransitionGuard<S> = bool Function(S currentState);
typedef TransitionEffect<S> = void Function(S previousState, S newState);
```

### TransitionContext\<S\>

| Member | Type | Description |
|--------|------|-------------|
| `currentState` | `S` | The current state |
| `read` | `ReactonReader?` | Optional reader for accessing other reactons |

---

## Lenses

Bidirectional optics for focusing on sub-values of a reacton's state.

### ReactonLens\<S, T\>

A bidirectional focus into a reacton's state. Reads a sub-value and writes back via a setter.

| Member | Type | Description |
|--------|------|-------------|
| `source` | `WritableReacton<S>` | The source reacton |
| `getter` | `T Function(S)` | Extract focused value |
| `setter` | `S Function(S, T)` | Create new source value with updated focus |
| `equals` | `bool Function(T, T)?` | Custom equality for the focused value |
| `then<C>({get, set})` | `ComposedLens<S, T, C>` | Chain with another lens for deeper focusing |

### Lens Factory Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `lens<S, T>()` | `ReactonLens<S, T> lens<S, T>(WritableReacton<S> source, T Function(S) get, S Function(S, T) set, {String? name, bool Function(T, T)? equals})` | Create a basic lens |
| `listLens<T>()` | `ListItemLens<T> listLens<T>(WritableReacton<List<T>> source, int index, {String? name})` | Focus on a list item by index |
| `mapLens<K, V>()` | `MapEntryLens<K, V> mapLens<K, V>(WritableReacton<Map<K, V>> source, K key, {String? name})` | Focus on a map entry by key |
| `filteredListLens<T>()` | `FilteredListLens<T> filteredListLens<T>(WritableReacton<List<T>> source, bool Function(T) predicate, {String? name, bool Function(List<T>, List<T>)? equals})` | Focus on a filtered list subset |

### Store Lens Extensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `read<S, T>()` | `T` | Read the focused value through the lens |
| `write<S, T>()` | `void` | Write a new value through the lens |
| `modify<S, T>()` | `void` | Update the focused value via a function |
| `subscribeLens<S, T>()` | `Unsubscribe` | Subscribe to changes of the focused value |
| `removeLens<S, T>()` | `void` | Cleanup lens resources |

### Lens Composition Extensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `item<E>(index)` | `ComposedLens<S, List<E>, E>` | Compose lens to focus on a list item |
| `entry<K, V>(key)` | `ComposedLens<S, Map<K, V>, V?>` | Compose lens to focus on a map entry |

---

## Interceptors

Lightweight value transformers and gates (simpler alternative to full middleware).

### Interceptor\<T\>

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `String` | Debug name |
| `onWrite` | `T Function(T)?` | Transform the value on write |
| `onRead` | `T Function(T)?` | Transform the value on read |
| `shouldUpdate` | `bool Function(T, T)?` | Gate function: return `false` to block the update |

### InterceptorChain\<T\>

| Method | Signature | Description |
|--------|-----------|-------------|
| `executeWrite(old, new)` | `(bool, T)` | Run write interceptors; returns (shouldUpdate, transformedValue) |
| `executeRead(value)` | `T` | Run read interceptors; returns transformed value |

---

## Debounce & Throttle

Rate-limiting utilities for controlling execution frequency.

### Debouncer

Delays execution until a period of inactivity. Useful for search-as-you-type.

| Member | Type | Description |
|--------|------|-------------|
| `duration` | `Duration` | The debounce period |
| `run(callback)` | `void` | Schedule callback (cancels previous pending call) |
| `cancel()` | `void` | Cancel any pending execution |
| `isPending` | `bool` | Whether a call is pending |
| `dispose()` | `void` | Cancel and cleanup |

### Throttler

Limits execution to at most once per duration. Useful for scroll/resize handlers.

| Member | Type | Description |
|--------|------|-------------|
| `duration` | `Duration` | The throttle period |
| `run(callback)` | `void` | Execute immediately if not throttled, otherwise queue |
| `cancel()` | `void` | Cancel any pending execution |
| `dispose()` | `void` | Cancel and cleanup |

---

## Sagas

Redux-saga inspired effect orchestration for complex async flows.

### Saga Factory

```dart
Saga<E> saga<E>({String? name, required void Function(SagaBuilder<E>) builder})
```

### SagaBuilder\<E\>

DSL for registering event handlers within a saga.

| Method | Description |
|--------|-------------|
| `on<S extends E>(handler)` | Handle the first matching event (takeOnce) |
| `onEvery<S extends E>(handler)` | Handle every event concurrently (takeEvery) |
| `onLatest<S extends E>(handler)` | Handle latest only, cancel previous (takeLatest) |
| `onLeading<S extends E>(handler)` | Ignore new events while one is running (takeLeading) |

### SagaContext

API available inside saga handlers.

| Method | Signature | Description |
|--------|-----------|-------------|
| `take<E>()` | `Future<E>` | Wait for the next event of type E |
| `put<T>()` | `void` | Write a value to a reacton |
| `call<T>()` | `Future<T>` | Execute an async function with cancellation |
| `fork()` | `SagaTask` | Fork a child saga |
| `join()` | `Future<void>` | Wait for a forked task to complete |
| `cancelTask()` | `void` | Cancel a forked task |
| `delay()` | `Future<void>` | Suspend for a duration |
| `race<T>()` | `Future<Map<String, T>>` | Race multiple async effects |
| `all<T>()` | `Future<List<T>>` | Run multiple effects in parallel |
| `select<T>()` | `T` | Read a reacton value |

### SagaTask

| Member | Type | Description |
|--------|------|-------------|
| `id` | `int` | Unique task ID |
| `name` | `String?` | Optional debug name |
| `isRunning` | `bool` | Whether the task is running |
| `isCompleted` | `bool` | Whether the task completed |
| `isCancelled` | `bool` | Whether the task was cancelled |
| `result` | `Future<void>` | Completion future |
| `cancel()` | `void` | Cancel the task (cascades to children) |

### HandlerStrategy

| Value | Description |
|-------|-------------|
| `takeOnce` | Handle only the first matching event |
| `takeEvery` | Handle every event concurrently |
| `takeLatest` | Cancel the previous handler when a new event arrives |
| `takeLeading` | Ignore new events while one is being handled |

### Store Saga Extensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `runSaga<E>()` | `SagaTask` | Start a saga and return the running task |
| `dispatch<E>()` | `void` | Dispatch an event to all running sagas |

---

## Collaborative (CRDT)

Conflict-free Replicated Data Types for distributed state synchronization.

### VectorClock

Causal ordering across distributed nodes.

| Member | Type | Description |
|--------|------|-------------|
| `entries` | `Map<String, int>` | Node IDs mapped to counters |
| `operator[](nodeId)` | `int` | Get counter for a node |
| `increment(nodeId)` | `VectorClock` | Return new clock with incremented counter |
| `merge(other)` | `VectorClock` | Return new clock with pointwise max |
| `happensBefore(other)` | `bool` | Causal precedence check |
| `isConcurrent(other)` | `bool` | Whether events are concurrent |
| `sum` | `int` | Total events metric |
| `toJson()` | `Map<String, dynamic>` | Serialize |

### CrdtValue\<T\>

A value with CRDT metadata attached.

| Member | Type | Description |
|--------|------|-------------|
| `value` | `T` | The application value |
| `clock` | `VectorClock` | Causal history |
| `nodeId` | `String` | Source node ID |
| `timestamp` | `int` | Wall-clock timestamp (tiebreaker) |

### Merge Strategies

| Class | Description |
|-------|-------------|
| `LastWriterWins<T>` | Most recent wall-clock timestamp wins (default tiebreaker: lexicographic node ID) |
| `MaxValue<T>` | Numerically larger value wins (requires `Comparable<T>`) |
| `UnionMerge<T>` | Set union (for GSet-like behavior, requires `Set`) |
| `CustomMerge<T>` | User-provided deterministic merge function |

### CollaborativeReacton\<T\>

A reacton that syncs across peers via CRDT. Extends `WritableReacton<T>`.

| Member | Type | Description |
|--------|------|-------------|
| `collaborativeName` | `String` | Name for sync identification |
| `strategy` | `CrdtMergeStrategy<T>` | Merge strategy for conflicts |
| `serializer` | `Serializer<T>?` | JSON serializer |

### CollaborativeSession

Manages a CRDT sync session with peers.

| Member | Type | Description |
|--------|------|-------------|
| `onConflict` | `Stream<ConflictEvent>` | Stream of conflict resolution events |
| `syncStatus` | `Stream<SyncStatus>` | Stream of status changes |
| `currentStatus` | `SyncStatus` | Current connection status |
| `isConnected` | `bool` | Whether connected |
| `peers` | `Set<String>` | Known peer node IDs |
| `localNodeId` | `String` | This node's ID |
| `disconnect()` | `Future<void>` | Disconnect and cleanup |

### SyncStatus

| Value | Description |
|-------|-------------|
| `disconnected` | Not connected to any peers |
| `connecting` | Connection is being established |
| `connected` | Fully connected and syncing |
| `reconnecting` | Lost connection, attempting to reconnect |

### Store Collaborative Extensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `collaborate()` | `CollaborativeSession` | Start a collaborative sync session |
| `isSynced()` | `bool` | Whether a collaborative reacton is synced |
| `clockOf()` | `VectorClock` | Get the vector clock for a collaborative reacton |
| `collaborativeSessions` | `List<CollaborativeSession>` | All active sessions |

---

## Modules

### ReactonModule

Abstract base class for grouping related reactons with lifecycle management.

| Member | Type | Description |
|--------|------|-------------|
| `name` | `String` | Module name |
| `isInitialized` | `bool` | Whether initialized |
| `registeredReactons` | `List<ReactonBase>` | All reactons registered by this module |
| `register<T>(reacton)` | `T` | Register a reacton with the module |
| `onInit(store)` | `void` | Called when the module is installed |
| `onDispose(store)` | `void` | Called when the module is uninstalled |

### Store Module Extensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `installModule<T>()` | `T` | Install a module and call its `onInit` |
| `module<T>()` | `T` | Get an installed module by type |
| `hasModule<T>()` | `bool` | Check if a module is installed |
| `uninstallModule<T>()` | `void` | Uninstall a module and call its `onDispose` |
| `installedModules` | `Iterable<ReactonModule>` | All installed modules |
| `moduleCount` | `int` | Number of installed modules |

---

## Observable Collections

### ListReacton\<T\>

A reactive list with granular change events. Wraps `WritableReacton<List<T>>`.

**Change events (sealed class `CollectionChange<T>`):**

| Subclass | Fields | Description |
|----------|--------|-------------|
| `ItemAdded<T>` | `index`, `item` | Item added at index |
| `ItemRemoved<T>` | `index`, `item` | Item removed from index |
| `ItemUpdated<T>` | `index`, `oldItem`, `newItem` | Item updated at index |
| `CollectionCleared<T>` | — | List cleared |
| `ItemsMoved<T>` | `fromIndex`, `toIndex`, `item` | Item moved |

**Store list extensions:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `listAdd<T>()` | `void` | Add item to end |
| `listInsert<T>()` | `void` | Insert at index |
| `listRemoveAt<T>()` | `T` | Remove and return item at index |
| `listRemove<T>()` | `bool` | Remove first occurrence |
| `listUpdate<T>()` | `void` | Update item at index via function |
| `listSet<T>()` | `void` | Replace item at index |
| `listClear<T>()` | `void` | Clear all items |
| `listAddAll<T>()` | `void` | Add multiple items |
| `listRemoveWhere<T>()` | `void` | Remove items matching predicate |
| `listSort<T>()` | `void` | Sort in-place |
| `listLength<T>()` | `int` | Get length |

### MapReacton\<K, V\>

A reactive map with granular change events. Wraps `WritableReacton<Map<K, V>>`.

**Change events (sealed class `MapChange<K, V>`):**

| Subclass | Fields | Description |
|----------|--------|-------------|
| `MapEntryAdded<K, V>` | `key`, `value` | Entry added |
| `MapEntryRemoved<K, V>` | `key`, `value` | Entry removed |
| `MapEntryUpdated<K, V>` | `key`, `oldValue`, `newValue` | Entry updated |
| `MapCleared<K, V>` | — | Map cleared |

**Store map extensions:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `mapPut<K, V>()` | `void` | Put a key-value pair |
| `mapPutAll<K, V>()` | `void` | Put multiple entries |
| `mapRemove<K, V>()` | `V?` | Remove and return value by key |
| `mapUpdate<K, V>()` | `void` | Update value for key via function |
| `mapClear<K, V>()` | `void` | Clear all entries |
| `mapContainsKey<K, V>()` | `bool` | Check if key exists |
| `mapLength<K, V>()` | `int` | Get entry count |
| `mapRemoveWhere<K, V>()` | `void` | Remove entries matching predicate |

---

## Snapshots

### StoreSnapshot

An immutable snapshot of all reacton values in the store.

| Member | Type | Description |
|--------|------|-------------|
| `values` | `Map<ReactonRef, dynamic>` | Captured values (unmodifiable) |
| `timestamp` | `DateTime` | When the snapshot was taken |
| `get<T>(reacton)` | `T?` | Get a value from the snapshot |
| `contains(reacton)` | `bool` | Check if reacton exists in snapshot |
| `size` | `int` | Number of reactons captured |
| `diff(other)` | `SnapshotDiff` | Compare with another snapshot |
| `copy()` | `StoreSnapshot` | Create a deep copy |

### SnapshotDiff

Differences between two snapshots.

| Member | Type | Description |
|--------|------|-------------|
| `added` | `Map<ReactonRef, dynamic>` | Reactons in second but not first |
| `removed` | `Map<ReactonRef, dynamic>` | Reactons in first but not second |
| `changed` | `Map<ReactonRef, (dynamic, dynamic)>` | Changed values (old, new) |
| `isEmpty` | `bool` | Whether there are no differences |
| `isNotEmpty` | `bool` | Whether there are differences |

---

## What's Next

- [Flutter Package API](./flutter-reacton) -- Widgets and BuildContext extensions
- [Test Package API](./reacton-test) -- Testing utilities
- [CLI Package API](./reacton-cli) -- Command reference
- [DevTools Package API](./reacton-devtools) -- DevTools extension reference
