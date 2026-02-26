# Retry Policies

Network requests fail. Servers time out. Connections drop. Reacton provides a `RetryPolicy` class that adds configurable retry behavior with exponential backoff to any async or query reacton.

## RetryPolicy

The `RetryPolicy` class controls how failed operations are retried.

```dart
const RetryPolicy({
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  double backoffMultiplier = 2.0,
  Duration? maxDelay,
  bool Function(Object error)? shouldRetry,
});
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `maxAttempts` | `int` | `3` | Maximum number of retry attempts. The total number of tries is `maxAttempts` (initial + retries). |
| `initialDelay` | `Duration` | 1 second | Delay before the first retry. |
| `backoffMultiplier` | `double` | `2.0` | Multiplier applied to the delay after each retry (exponential backoff). |
| `maxDelay` | `Duration?` | `null` | Upper bound on the delay between retries. Prevents delays from growing unbounded. |
| `shouldRetry` | `bool Function(Object)?` | `null` | Predicate that determines if a specific error should be retried. If `null`, all errors are retried. Return `false` to fail immediately. |

## How Backoff Works

The delay before retry attempt `n` (0-indexed) is calculated as:

```
delay(n) = min(initialDelay * backoffMultiplier^n, maxDelay)
```

For the default configuration (`initialDelay: 1s`, `backoffMultiplier: 2.0`):

| Attempt | Delay |
|---------|-------|
| 0 (initial) | -- |
| 1 (first retry) | 1 second |
| 2 (second retry) | 2 seconds |
| 3 (third retry) | 4 seconds |
| 4 | 8 seconds |
| 5 | 16 seconds |

With `maxDelay: Duration(seconds: 10)`:

| Attempt | Delay |
|---------|-------|
| 1 | 1 second |
| 2 | 2 seconds |
| 3 | 4 seconds |
| 4 | 8 seconds |
| 5 | **10 seconds** (capped) |

## Methods

### delayForAttempt()

Calculate the delay for a given attempt number (0-indexed).

```dart
final policy = RetryPolicy(
  initialDelay: Duration(seconds: 1),
  backoffMultiplier: 2.0,
);

print(policy.delayForAttempt(0)); // 1s
print(policy.delayForAttempt(1)); // 2s
print(policy.delayForAttempt(2)); // 4s
```

### canRetry()

Check whether a given error should be retried at a given attempt number.

```dart
final policy = RetryPolicy(
  maxAttempts: 3,
  shouldRetry: (e) => e is NetworkException,
);

print(policy.canRetry(NetworkException(), 0)); // true
print(policy.canRetry(NetworkException(), 3)); // false (max attempts)
print(policy.canRetry(AuthException(), 0));    // false (not retryable)
```

## Usage with asyncReacton

```dart
final dataReacton = asyncReacton<Data>(
  (read) => api.fetchData(),
  name: 'data',
  retryPolicy: RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    shouldRetry: (e) => e is NetworkException,
  ),
);
```

## Usage with reactonQuery

```dart
final usersQuery = reactonQuery<List<User>>(
  queryFn: (_) => api.fetchUsers(),
  config: QueryConfig(
    staleTime: Duration(minutes: 5),
    retryPolicy: RetryPolicy(
      maxAttempts: 3,
      initialDelay: Duration(milliseconds: 500),
      backoffMultiplier: 2.0,
      maxDelay: Duration(seconds: 30),
    ),
  ),
  name: 'users',
);
```

## Common Patterns

### Retry Only Network Errors

```dart
RetryPolicy(
  maxAttempts: 3,
  shouldRetry: (e) => e is SocketException || e is TimeoutException,
)
```

### No Retry for Client Errors

```dart
RetryPolicy(
  maxAttempts: 3,
  shouldRetry: (e) {
    if (e is HttpException) {
      // Don't retry 4xx errors (client mistakes)
      return e.statusCode >= 500;
    }
    return true; // retry everything else
  },
)
```

### Fixed Delay (No Backoff)

Set `backoffMultiplier` to `1.0` for a constant delay between retries:

```dart
RetryPolicy(
  maxAttempts: 5,
  initialDelay: Duration(seconds: 2),
  backoffMultiplier: 1.0,  // 2s, 2s, 2s, 2s, 2s
)
```

### Aggressive Backoff with Cap

```dart
RetryPolicy(
  maxAttempts: 10,
  initialDelay: Duration(milliseconds: 100),
  backoffMultiplier: 3.0,
  maxDelay: Duration(seconds: 60),  // never wait more than 1 minute
)
```

::: warning
Be careful with high `maxAttempts` and no `maxDelay`. Exponential backoff grows fast: with a multiplier of 2.0, attempt 10 waits over 17 minutes.
:::

## What's Next

- [Optimistic Updates](/async/optimistic) -- Apply changes instantly with automatic rollback
- [Async Reacton](/async/async-reacton) -- Core async data fetching primitive
- [Query Reacton](/async/query-reacton) -- Smart cached queries
