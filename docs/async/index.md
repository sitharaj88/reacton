# Async State

Reacton provides first-class support for asynchronous data fetching, caching, and mutation. Every async operation is represented as an `AsyncValue<T>`, a sealed type that makes it impossible to forget about loading and error states.

## Key Concepts

| Concept | Description |
|---------|-------------|
| [Async Reacton](/async/async-reacton) | Fetch data that automatically refetches when dependencies change |
| [Query Reacton](/async/query-reacton) | Smart caching layer with stale time, polling, deduplication, and cache GC |
| [Retry Policies](/async/retry) | Configurable retry with exponential backoff for failed operations |
| [Optimistic Updates](/async/optimistic) | Apply changes instantly with automatic rollback on failure |

## At a Glance

```dart
// Simple async fetch with dependency tracking
final weatherReacton = asyncReacton<Weather>((read) async {
  final city = read(selectedCityReacton);
  return await weatherApi.getWeather(city);
}, name: 'weather');

// Smart cached query with stale-while-revalidate
final usersQuery = reactonQuery<List<User>>(
  queryFn: (_) => api.fetchUsers(),
  config: QueryConfig(staleTime: Duration(minutes: 5)),
  name: 'users',
);

// Consume in widgets with pattern matching
final weather = context.watch(weatherReacton);
weather.when(
  loading: () => CircularProgressIndicator(),
  data: (w) => Text('${w.temp}°C'),
  error: (e, _) => Text('Error: $e'),
);
```

## AsyncValue&lt;T&gt;

All async reactons produce `AsyncValue<T>`, a sealed class with three states:

- **`AsyncLoading`** -- Operation is in progress (optionally carries `previousData`)
- **`AsyncData`** -- Operation succeeded with a value
- **`AsyncError`** -- Operation failed with an error and stack trace

This sealed type guarantees you handle all states at compile time. See [Async Reacton](/async/async-reacton) for full details.

## Choosing Between Async and Query Reactons

| Feature | `asyncReacton` | `reactonQuery` |
|---------|:--------------:|:--------------:|
| Dependency tracking | Yes | No |
| Auto-refetch on dep change | Yes | No |
| Stale-while-revalidate cache | -- | Yes |
| Configurable stale time | -- | Yes |
| Polling | Via `refreshInterval` | Via `pollingInterval` |
| Deduplication | -- | Yes |
| Cache garbage collection | -- | Yes |
| Prefetching | -- | Yes |
| Manual cache manipulation | -- | Yes |
| Parameterized (family) | -- | Yes |

**Rule of thumb:** Use `asyncReacton` when your fetch depends on other reactive state. Use `reactonQuery` when you need caching, polling, or TanStack Query-style data management.

## What's Next

- [Async Reacton](/async/async-reacton) -- Learn the core async primitive
- [Query Reacton](/async/query-reacton) -- Explore smart cached queries
- [Retry Policies](/async/retry) -- Add resilience to your fetches
- [Optimistic Updates](/async/optimistic) -- Build snappy UIs with instant feedback
