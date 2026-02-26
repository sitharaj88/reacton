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

## What's Next

- [Persistence](/advanced/persistence) -- Auto-save state to disk using serializers and storage adapters
- [History](/advanced/history) -- Add undo/redo to any reacton
- [State Branching](/advanced/branching) -- Preview and merge state changes
