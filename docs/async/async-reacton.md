# Async Reacton

An async reacton fetches data asynchronously and automatically refetches whenever its reactive dependencies change. It is the primary tool for connecting your UI to APIs, databases, or any `Future`-based data source.

## Creating an Async Reacton

Use the `asyncReacton<T>()` factory to create one. The fetch function receives a `read` callback for accessing other reactons, and dependencies are tracked automatically.

```dart
final weatherReacton = asyncReacton<Weather>((read) async {
  final city = read(selectedCityReacton);
  return await weatherApi.getWeather(city);
}, name: 'weather');
```

When `selectedCityReacton` changes, the weather fetch is automatically re-executed.

### Factory Signature

```dart
AsyncReacton<T> asyncReacton<T>(
  Future<T> Function(ReactonReader read) fetch, {
  String? name,
  RetryPolicy? retryPolicy,
  Duration? refreshInterval,
});
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `fetch` | `Future<T> Function(ReactonReader read)` | The async function to execute. Dependencies accessed via `read` are tracked. |
| `name` | `String?` | Optional debug name for DevTools and logging. |
| `retryPolicy` | `RetryPolicy?` | Retry policy for failed fetches. See [Retry Policies](/async/retry). |
| `refreshInterval` | `Duration?` | If set, the reacton auto-refreshes at this interval. |

### AsyncReacton Properties

| Property | Type | Description |
|----------|------|-------------|
| `fetch` | `Future<T> Function(ReactonReader)` | The async fetch function. |
| `retryPolicy` | `RetryPolicy?` | Retry configuration. |
| `refreshInterval` | `Duration?` | Auto-refresh interval. |
| `cancelOnDispose` | `bool` | Whether to cancel in-flight requests on dispose. Defaults to `true`. |

## AsyncValue&lt;T&gt;

An async reacton's value is always an `AsyncValue<T>` -- a sealed class with three subtypes.

### States

| State | Class | Fields | Description |
|-------|-------|--------|-------------|
| Loading | `AsyncLoading<T>` | `T? previousData` | Operation in progress. May carry previous data for stale-while-revalidate. |
| Data | `AsyncData<T>` | `T value` | Operation completed successfully. |
| Error | `AsyncError<T>` | `Object error`, `StackTrace? stackTrace`, `T? previousData` | Operation failed. May carry previous data. |

### Constructors

```dart
const AsyncValue.loading([T? previousData])
const AsyncValue.data(T value)
const AsyncValue.error(Object error, [StackTrace? stackTrace, T? previousData])
```

## Pattern Matching

### when()

Exhaustively match all three states. This is the recommended way to render async data in widgets.

```dart
final weather = context.watch(weatherReacton);

weather.when(
  loading: () => CircularProgressIndicator(),
  data: (w) => Text('${w.temp}°C in ${w.city}'),
  error: (e, st) => Text('Failed: $e'),
);
```

**Signature:**

```dart
R when<R>({
  required R Function() loading,
  required R Function(T data) data,
  required R Function(Object error, StackTrace? stackTrace) error,
});
```

### whenOrElse()

Optionally handle specific states, with a fallback for unhandled ones. The loading and error callbacks receive `previousData` for stale-while-revalidate scenarios.

```dart
weather.whenOrElse(
  loading: (previousData) {
    if (previousData != null) {
      return Opacity(opacity: 0.5, child: WeatherCard(previousData));
    }
    return CircularProgressIndicator();
  },
  data: (w) => WeatherCard(w),
  error: (e, st, previousData) {
    if (previousData != null) {
      return Column(children: [
        WeatherCard(previousData),
        Text('Update failed: $e'),
      ]);
    }
    return Text('Error: $e');
  },
  orElse: () => SizedBox.shrink(),
);
```

**Signature:**

```dart
R whenOrElse<R>({
  R Function(T? previousData)? loading,
  R Function(T data)? data,
  R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
  required R Function() orElse,
});
```

### map()

Transform the data value while preserving the async state.

```dart
final AsyncValue<String> cityName = weather.map((w) => w.city);
```

**Signature:**

```dart
AsyncValue<R> map<R>(R Function(T) transform);
```

::: tip
`map()` transforms `previousData` as well, so stale-while-revalidate behavior is preserved through transformations.
:::

## Convenience Getters

| Getter | Type | Description |
|--------|------|-------------|
| `valueOrNull` | `T?` | The current data value, falling back to `previousData` in loading/error states. Returns `null` if no data has ever been fetched. |
| `isLoading` | `bool` | `true` when in the `AsyncLoading` state. |
| `hasData` | `bool` | `true` when in the `AsyncData` state. |
| `hasError` | `bool` | `true` when in the `AsyncError` state. |
| `hasValue` | `bool` | `true` if `valueOrNull` is non-null (i.e., current or stale data exists). |

```dart
if (weather.isLoading) {
  print('Fetching...');
}

// Safe access to data regardless of current state
final temp = weather.valueOrNull?.temp;
```

## Stale-While-Revalidate

When an async reacton refetches (due to a dependency change or manual refresh), it transitions to `AsyncLoading` while retaining the previous successful data in the `previousData` field.

```
AsyncData(Weather(28°C))
         |
  dependency changes
         |
         v
AsyncLoading(previousData: Weather(28°C))   <-- UI can show stale data
         |
    fetch completes
         |
         v
AsyncData(Weather(31°C))                    <-- UI updates to fresh data
```

This pattern lets you display stale data with a loading indicator instead of flashing an empty loading screen on every refetch.

```dart
Widget build(BuildContext context) {
  final weather = context.watch(weatherReacton);

  return Stack(
    children: [
      // Show data if available (current or stale)
      if (weather.hasValue)
        WeatherCard(weather.valueOrNull!),

      // Overlay loading indicator during refetch
      if (weather.isLoading)
        Positioned(top: 8, right: 8, child: SmallSpinner()),
    ],
  );
}
```

## Dependency Tracking

Dependencies are tracked automatically via the `read` function inside the fetch callback. When any dependency changes, the fetch re-executes.

```dart
final selectedCityReacton = reacton('London', name: 'selectedCity');
final unitReacton = reacton(TemperatureUnit.celsius, name: 'unit');

final weatherReacton = asyncReacton<Weather>((read) async {
  final city = read(selectedCityReacton);    // dependency 1
  final unit = read(unitReacton);            // dependency 2
  return await weatherApi.getWeather(city, unit: unit);
}, name: 'weather');
```

Changing either `selectedCityReacton` or `unitReacton` triggers a new fetch. The previous in-flight request is cancelled automatically.

## Auto-Refresh

Set `refreshInterval` to periodically refetch data:

```dart
final stockPriceReacton = asyncReacton<double>((read) async {
  final symbol = read(selectedStockReacton);
  return await stockApi.getPrice(symbol);
},
  name: 'stockPrice',
  refreshInterval: Duration(seconds: 30),
);
```

## Retry on Failure

Attach a `RetryPolicy` to automatically retry failed fetches:

```dart
final dataReacton = asyncReacton<Data>((read) async {
  return await api.fetchData();
},
  name: 'data',
  retryPolicy: RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    shouldRetry: (e) => e is NetworkException,
  ),
);
```

See [Retry Policies](/async/retry) for full documentation.

## Complete Example: User Profile

```dart
// Reactive user ID (e.g., from auth state or route)
final currentUserIdReacton = reacton<String>('user-1', name: 'currentUserId');

// Async fetch that tracks the user ID
final userProfileReacton = asyncReacton<UserProfile>((read) async {
  final userId = read(currentUserIdReacton);
  final response = await http.get(Uri.parse('https://api.example.com/users/$userId'));
  if (response.statusCode != 200) {
    throw HttpException('Failed to load user: ${response.statusCode}');
  }
  return UserProfile.fromJson(jsonDecode(response.body));
},
  name: 'userProfile',
  retryPolicy: RetryPolicy(maxAttempts: 2),
);

// Widget
class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profile = context.watch(userProfileReacton);

    return profile.when(
      loading: () => Center(child: CircularProgressIndicator()),
      data: (user) => Column(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
          Text(user.displayName, style: Theme.of(context).textTheme.headlineMedium),
          Text(user.email),
        ],
      ),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48),
            SizedBox(height: 16),
            Text('Could not load profile'),
            TextButton(
              onPressed: () {
                // Trigger refetch by "touching" a dependency
                context.set(currentUserIdReacton, context.read(currentUserIdReacton));
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## What's Next

- [Query Reacton](/async/query-reacton) -- Smart caching, polling, and cache management
- [Retry Policies](/async/retry) -- Configure retry strategies for resilient fetches
- [Optimistic Updates](/async/optimistic) -- Apply changes instantly with rollback
