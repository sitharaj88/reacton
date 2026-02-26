# Middleware

Middleware intercepts reacton lifecycle events -- initialization, writes, disposal, and errors. Use middleware for cross-cutting concerns like logging, validation, persistence, analytics, and access control.

## Middleware&lt;T&gt; Abstract Class

Extend `Middleware<T>` and override the hooks you need. All hooks have sensible defaults (no-op or pass-through), so you only implement what matters.

```dart
abstract class Middleware<T> {
  T onInit(ReactonBase<T> reacton, T initialValue) => initialValue;
  T onBeforeWrite(ReactonBase<T> reacton, T currentValue, T newValue) => newValue;
  void onAfterWrite(ReactonBase<T> reacton, T value) {}
  void onDispose(ReactonBase<T> reacton) {}
  void onError(ReactonBase<T> reacton, Object error, StackTrace stackTrace) {}
}
```

### Lifecycle Hooks

| Hook | Signature | When Called | Return |
|------|-----------|-------------|--------|
| `onInit` | `T onInit(reacton, initialValue)` | When the reacton is first initialized in the store. | The (possibly modified) initial value. |
| `onBeforeWrite` | `T onBeforeWrite(reacton, currentValue, newValue)` | Before a value is written. **Throw to reject the write.** | The (possibly modified) new value. |
| `onAfterWrite` | `void onAfterWrite(reacton, value)` | After a value has been written and propagated. | -- |
| `onDispose` | `void onDispose(reacton)` | When the reacton is disposed from the store. | -- |
| `onError` | `void onError(reacton, error, stackTrace)` | When an error occurs during computation. | -- |

## Applying Middleware

### Per-Reacton Middleware

Attach middleware to a specific reacton via `ReactonOptions.middleware`:

```dart
final counterReacton = reacton(0, options: ReactonOptions(
  middleware: [LoggingMiddleware('counter')],
));
```

### Global Middleware

Apply middleware to all reactons by passing it to the `ReactonStore` constructor:

```dart
final store = ReactonStore(
  globalMiddleware: [
    LoggingMiddleware('global'),
  ],
);
```

::: tip
Global middleware runs before per-reacton middleware. Both lists are evaluated in order -- first global (type-matched), then reacton-specific.
:::

::: warning
Global middleware is type-matched at runtime. A `Middleware<int>` only intercepts reactons whose value type is `int`. If you need middleware that applies to all types, use `Middleware<dynamic>`.
:::

## Built-in: LoggingMiddleware

Reacton ships with a `LoggingMiddleware<T>` that logs all lifecycle events.

```dart
class LoggingMiddleware<T> extends Middleware<T> {
  LoggingMiddleware(String tag, {void Function(String)? logger});
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `tag` | `String` | Prefix for log messages. |
| `logger` | `void Function(String)?` | Custom log function. Defaults to `print`. |

### What It Logs

| Event | Log Output |
|-------|------------|
| Init | `[tag] Initialized: <value>` |
| Before Write | `[tag] Writing: <old> -> <new>` |
| After Write | `[tag] Written: <value>` |
| Dispose | `[tag] Disposed` |
| Error | `[tag] Error: <error>` |

### Example

```dart
final counterReacton = reacton(0, options: ReactonOptions(
  middleware: [LoggingMiddleware('counter')],
));

store.set(counterReacton, 1);
// Output:
// [counter] Writing: 0 -> 1
// [counter] Written: 1
```

## Interceptor&lt;T&gt;

For simpler use cases that only need value transformation or gating, use `Interceptor<T>`. It is more lightweight than a full `Middleware` subclass.

```dart
class Interceptor<T> {
  final String name;
  final T Function(T value)? onWrite;
  final T Function(T value)? onRead;
  final bool Function(T oldValue, T newValue)? shouldUpdate;

  const Interceptor({
    required this.name,
    this.onWrite,
    this.onRead,
    this.shouldUpdate,
  });
}
```

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Debug name for this interceptor. |
| `onWrite` | `T Function(T)?` | Transform the value before it is written. |
| `onRead` | `T Function(T)?` | Transform the value when it is read. |
| `shouldUpdate` | `bool Function(T, T)?` | Gate function. Return `false` to reject the update entirely. |

### InterceptorChain

Multiple interceptors are composed into an `InterceptorChain<T>` and executed in order:

```dart
final chain = InterceptorChain<int>([
  Interceptor(name: 'clamp', onWrite: (v) => v.clamp(0, 100)),
  Interceptor(name: 'even-only', shouldUpdate: (old, next) => next.isEven),
]);

final (accepted, value) = chain.executeWrite(currentValue, newValue);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `executeWrite(current, new)` | `(bool accepted, T value)` | Run all interceptors' write handlers. Returns `false` if any gate rejects. |
| `executeRead(value)` | `T` | Run all interceptors' read handlers. |

## Custom Middleware Examples

### Validation Middleware

Reject writes that fail validation by throwing from `onBeforeWrite`:

```dart
class PositiveOnlyMiddleware extends Middleware<int> {
  @override
  int onBeforeWrite(ReactonBase<int> reacton, int currentValue, int newValue) {
    if (newValue < 0) {
      throw ArgumentError('Value must be non-negative, got $newValue');
    }
    return newValue;
  }
}

final ageReacton = reacton(0, options: ReactonOptions(
  middleware: [PositiveOnlyMiddleware()],
));
```

### Clamping Middleware

Transform values to stay within a range:

```dart
class ClampMiddleware extends Middleware<int> {
  final int min;
  final int max;

  ClampMiddleware(this.min, this.max);

  @override
  int onBeforeWrite(ReactonBase<int> reacton, int currentValue, int newValue) {
    return newValue.clamp(min, max);
  }
}

final volumeReacton = reacton(50, options: ReactonOptions(
  middleware: [ClampMiddleware(0, 100)],
));

store.set(volumeReacton, 150);
print(store.get(volumeReacton)); // 100
```

### Analytics Middleware

Track state changes for analytics:

```dart
class AnalyticsMiddleware<T> extends Middleware<T> {
  final AnalyticsService analytics;

  AnalyticsMiddleware(this.analytics);

  @override
  void onAfterWrite(ReactonBase<T> reacton, T value) {
    analytics.track('state_changed', {
      'reacton': reacton.ref.toString(),
      'value': value.toString(),
    });
  }
}
```

### Debounce Middleware

Throttle writes using a timer:

```dart
class DebounceMiddleware<T> extends Middleware<T> {
  final Duration duration;
  Timer? _timer;
  T? _pendingValue;

  DebounceMiddleware(this.duration);

  @override
  T onBeforeWrite(ReactonBase<T> reacton, T currentValue, T newValue) {
    _timer?.cancel();
    _pendingValue = newValue;
    _timer = Timer(duration, () {
      // Actual write happens after debounce period
    });
    throw _DebounceRejectException(); // reject immediate write
  }
}
```

## Middleware Execution Order

```
Global Middleware (type-matched) → Per-Reacton Middleware → Store Write
```

1. Global middleware is iterated in insertion order. Only middleware whose type parameter matches the reacton's value type is invoked.
2. Per-reacton middleware (from `ReactonOptions.middleware`) is iterated in list order.
3. Each middleware can modify the value or throw to reject.
4. After the write, `onAfterWrite` is called in the same order.

## Built-in: PersistenceMiddleware

`PersistenceMiddleware<T>` auto-persists reacton values through the middleware lifecycle. It loads the stored value on initialization (`onInit`) and saves the new value after every write (`onAfterWrite`). If deserialization fails (e.g., stale data after a schema change), the reacton silently falls back to its initial value.

```dart
class PersistenceMiddleware<T> extends Middleware<T> {
  PersistenceMiddleware({
    required StorageAdapter storage,
    required Serializer<T> serializer,
    required String key,
  });
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `storage` | `StorageAdapter` | The storage backend (e.g., `MemoryStorage`, `SharedPrefsStorage`). |
| `serializer` | `Serializer<T>` | Converts values to/from strings for storage. |
| `key` | `String` | The storage key used to read and write the persisted value. |

### JsonPersistenceMiddleware

`JsonPersistenceMiddleware<T>` is a convenience subclass that wraps a `JsonSerializer` internally, so you can pass `toJson` and `fromJson` callbacks directly instead of constructing a serializer yourself.

```dart
class JsonPersistenceMiddleware<T> extends PersistenceMiddleware<T> {
  JsonPersistenceMiddleware({
    required StorageAdapter storage,
    required String key,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
  });
}
```

### PersistenceMiddleware Example

```dart
// Using PersistenceMiddleware with MemoryStorage (useful for tests)
final storage = MemoryStorage();

final counterReacton = reacton(0, options: ReactonOptions(
  middleware: [
    PersistenceMiddleware<int>(
      storage: storage,
      serializer: PrimitiveSerializer<int>(),
      key: 'counter',
    ),
  ],
));

// For JSON-serializable objects, use JsonPersistenceMiddleware
final settingsReacton = reacton(
  Settings.defaults(),
  options: ReactonOptions(
    middleware: [
      JsonPersistenceMiddleware<Settings>(
        storage: storage,
        key: 'app_settings',
        toJson: (s) => s.toJson(),
        fromJson: (json) => Settings.fromJson(json),
      ),
    ],
  ),
);
```

### When to Use PersistenceMiddleware vs Manual Persistence

Reacton offers two ways to persist state: `ReactonOptions.persistKey` + `serializer` (configured on the store's `StorageAdapter`) and `PersistenceMiddleware` (attached per-reacton as middleware). Choose based on your needs:

| | Manual (`persistKey` + `serializer`) | `PersistenceMiddleware` |
|---|---|---|
| **Storage backend** | Single `StorageAdapter` on the store, shared by all persisted reactons. | Each middleware instance carries its own `StorageAdapter` reference -- different reactons can use different backends. |
| **Configuration** | Set in `ReactonOptions` fields. Requires a `StorageAdapter` on the store. | Set as a middleware entry. No store-level storage adapter needed. |
| **Flexibility** | Good for apps with one storage backend. | Better when you need per-reacton storage backends, or want to compose persistence with other middleware. |
| **Testability** | Must configure the store with a `MemoryStorage`. | Pass `MemoryStorage` directly to the middleware -- no store-level setup required. |

::: tip
If all your persisted reactons use the same storage backend, the manual `persistKey` approach is simpler. Reach for `PersistenceMiddleware` when you need per-reacton storage flexibility or want persistence as part of a middleware pipeline.
:::

## Built-in: DevToolsMiddleware

`DevToolsMiddleware<T>` sends state changes to the Dart DevTools extension. It emits timeline events on writes and posts service extension events that the Reacton DevTools panel consumes for the state timeline view. Errors are also reported as DevTools events.

```dart
class DevToolsMiddleware<T> extends Middleware<T> {
  DevToolsMiddleware();
}
```

### What It Reports

| Event | DevTools Output |
|-------|----------------|
| Before Write | Starts a timeline sync event named `Reacton: <ref>` with old and new values. |
| After Write | Finishes the timeline event and posts a `reacton.stateChange` event with the reacton ref, id, value, and timestamp. |
| Error | Posts a `reacton.error` event with the reacton ref, id, error, and stack trace. |

### When to Use

Use `DevToolsMiddleware` during development and debug builds to inspect state changes in real time. Remove or disable it in release builds to avoid unnecessary overhead.

::: warning
`DevToolsMiddleware` uses `dart:developer` APIs (`Timeline` and `postEvent`) which have no effect in release mode, but the middleware still runs its logic. For best performance in production, exclude it from your middleware lists in release builds.
:::

### DevToolsMiddleware Example

```dart
import 'package:flutter/foundation.dart';

final counterReacton = reacton(0, options: ReactonOptions(
  middleware: [
    if (kDebugMode) DevToolsMiddleware<int>(),
  ],
));

// Or apply globally to all reactons during development
final store = ReactonStore(
  globalMiddleware: [
    if (kDebugMode) DevToolsMiddleware<dynamic>(),
  ],
);
```

::: tip
Use `DevToolsMiddleware<dynamic>` as global middleware to capture state changes from all reactons regardless of their value type.
:::

## What's Next

- [Persistence](/advanced/persistence) -- Auto-save state to disk using serializers and storage adapters
- [History](/advanced/history) -- Add undo/redo to any reacton
- [State Branching](/advanced/branching) -- Preview and merge state changes
