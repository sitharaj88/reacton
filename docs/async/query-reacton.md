# Query Reacton

Query reactons provide a smart caching layer for asynchronous data fetching, inspired by TanStack Query (React Query). They add stale-while-revalidate semantics, polling, deduplication, and cache garbage collection on top of the standard `AsyncValue<T>` model.

## Creating a Query Reacton

Use the `reactonQuery<T>()` factory to define a cached query:

```dart
final usersQuery = reactonQuery<List<User>>(
  queryFn: (_) => api.fetchUsers(),
  config: QueryConfig(staleTime: Duration(minutes: 5)),
  name: 'users',
);
```

### Factory Signature

```dart
QueryReacton<T> reactonQuery<T>({
  required Future<T> Function(QueryContext<void>) queryFn,
  QueryConfig config = const QueryConfig(),
  String? name,
});
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `queryFn` | `Future<T> Function(QueryContext<void>)` | The async function that fetches data. Receives a `QueryContext` for cancellation support. |
| `config` | `QueryConfig` | Cache and behavior configuration. |
| `name` | `String?` | Optional debug name. |

## QueryConfig

`QueryConfig` controls caching, polling, retry, and refetch behavior.

```dart
const QueryConfig({
  Duration staleTime = const Duration(minutes: 5),
  Duration cacheTime = const Duration(minutes: 30),
  bool refetchOnReconnect = false,
  bool refetchOnResume = false,
  Duration? pollingInterval,
  RetryPolicy? retryPolicy,
});
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `staleTime` | `Duration` | 5 minutes | How long data is considered "fresh." While fresh, re-fetches are skipped and cached data is returned immediately. |
| `cacheTime` | `Duration` | 30 minutes | How long unused data stays in cache after all watchers unsubscribe. After this, the cache entry is garbage collected. |
| `refetchOnReconnect` | `bool` | `false` | If `true`, stale queries refetch when network connectivity is restored. |
| `refetchOnResume` | `bool` | `false` | If `true`, stale queries refetch when the app returns to the foreground. |
| `pollingInterval` | `Duration?` | `null` | If set, the query refetches at this interval regardless of freshness. |
| `retryPolicy` | `RetryPolicy?` | `null` | Retry policy for failed fetches. See [Retry Policies](/async/retry). |

::: tip
Choose `staleTime` based on how frequently your data changes. For user profiles, 5-10 minutes is typical. For stock prices, you might use seconds or enable polling instead.
:::

## Query Lifecycle

```
  ┌─────────────┐
  │  No Cache   │ ── fetchQuery() ──> Loading ──> Data (fresh)
  └─────────────┘                                    │
                                                     │ staleTime elapses
                                                     v
                                              Data (stale)
                                                     │
                                              fetchQuery()
                                                     │
                            ┌────────────────────────┤
                            v                        v
                   Return stale data          Background refetch
                   immediately                       │
                                                     v
                                              Data (fresh again)
```

## Store Operations

All query operations are extensions on `ReactonStore`.

### fetchQuery()

Fetch a query. Returns cached data if fresh, triggers background refetch if stale, or performs a fresh fetch if no cache exists.

```dart
final users = await store.fetchQuery(usersQuery);
```

### invalidateQuery()

Mark a query as stale and trigger an immediate refetch.

```dart
await store.invalidateQuery(usersQuery);
```

### prefetchQuery()

Prefetch a query so data is already cached when a widget mounts. Skips the fetch if data is already fresh.

```dart
// Prefetch on app startup or route transition
await store.prefetchQuery(usersQuery);
```

### setQueryData()

Manually set query data. Useful after a mutation to avoid a redundant refetch.

```dart
// After creating a user, update the cache directly
final newUser = await api.createUser(userData);
final currentUsers = store.get(usersQuery).valueOrNull ?? [];
store.setQueryData(usersQuery, [...currentUsers, newUser]);
```

### removeQuery()

Remove a query from the cache entirely, cancelling any active polling or timers.

```dart
store.removeQuery(usersQuery);
```

### invalidateAllQueries()

Mark all queries as stale. Useful when you know the data model has changed globally (e.g., after a database migration or major state change).

```dart
store.invalidateAllQueries();
```

### API Summary

| Method | Returns | Description |
|--------|---------|-------------|
| `fetchQuery(query)` | `Future<T>` | Fetch with cache. Returns fresh data or triggers refetch. |
| `invalidateQuery(query)` | `Future<void>` | Force refetch immediately. |
| `prefetchQuery(query)` | `Future<void>` | Cache data ahead of time. |
| `setQueryData(query, data)` | `void` | Manually populate the cache. |
| `removeQuery(query)` | `void` | Remove from cache, cancel timers. |
| `invalidateAllQueries()` | `void` | Mark all queries as stale. |

## QueryContext and Cancellation

The `queryFn` receives a `QueryContext` that provides cancellation support. When a new fetch starts while a previous one is still in-flight, the previous context is cancelled.

```dart
final dataQuery = reactonQuery<Data>(
  queryFn: (ctx) async {
    final response = await http.get(Uri.parse('https://api.example.com/data'));

    // Check if this query was superseded by a newer fetch
    ctx.throwIfCancelled();

    return Data.fromJson(jsonDecode(response.body));
  },
  name: 'data',
);
```

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `ctx.isCancelled` | `bool` | Whether this query has been cancelled. |
| `ctx.throwIfCancelled()` | `void` | Throws `QueryCancelledException` if cancelled. |

## Query Family (Parameterized Queries)

Use `reactonQueryFamily<T, Arg>()` to create a family of queries parameterized by an argument. Each unique argument gets its own cached query instance.

```dart
final userQuery = reactonQueryFamily<User, String>(
  queryFn: (ctx) => api.fetchUser(ctx.arg),
  config: QueryConfig(staleTime: Duration(minutes: 10)),
  name: 'user',
);

// Each call with a different argument creates a separate cached query
final alice = store.get(userQuery('user-alice'));  // AsyncValue<User>
final bob = store.get(userQuery('user-bob'));      // AsyncValue<User>
```

### Factory Signature

```dart
QueryFamily<T, Arg> reactonQueryFamily<T, Arg>({
  required Future<T> Function(QueryContext<Arg>) queryFn,
  QueryConfig config = const QueryConfig(),
  String? name,
});
```

::: tip
Inside a family `queryFn`, access the argument via `ctx.arg`. The `QueryContext<Arg>` is typed to match your argument type.
:::

### QueryFamily Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `call(arg)` | `QueryReacton<T>` | Get or create a query for the given argument. |
| `remove(arg)` | `void` | Remove a cached query for a specific argument. |
| `clear()` | `void` | Remove all cached queries in the family. |
| `cachedArgs` | `Iterable<Arg>` | All currently cached arguments. |

## Comparison with TanStack Query

If you are coming from React Query / TanStack Query, here is how the concepts map:

| TanStack Query | Reacton | Notes |
|---------------|---------|-------|
| `useQuery()` | `reactonQuery()` | Define outside widgets, consume with `context.watch()` |
| `queryKey` | `name` parameter | Used for debugging; identity is by reacton ref |
| `staleTime` | `QueryConfig.staleTime` | Same concept |
| `gcTime` (cacheTime) | `QueryConfig.cacheTime` | Same concept |
| `refetchInterval` | `QueryConfig.pollingInterval` | Same concept |
| `queryClient.invalidateQueries()` | `store.invalidateQuery()` | Per-query or `invalidateAllQueries()` |
| `queryClient.prefetchQuery()` | `store.prefetchQuery()` | Same concept |
| `queryClient.setQueryData()` | `store.setQueryData()` | Same concept |
| `useMutation()` | `store.optimistic()` | See [Optimistic Updates](/async/optimistic) |

## Complete Example: Paginated User List

```dart
// Query family parameterized by page number
final usersPageQuery = reactonQueryFamily<UsersPage, int>(
  queryFn: (ctx) async {
    final page = ctx.arg;
    final response = await http.get(
      Uri.parse('https://api.example.com/users?page=$page&limit=20'),
    );
    ctx.throwIfCancelled();
    return UsersPage.fromJson(jsonDecode(response.body));
  },
  config: QueryConfig(
    staleTime: Duration(minutes: 5),
    cacheTime: Duration(minutes: 30),
    retryPolicy: RetryPolicy(maxAttempts: 2),
  ),
  name: 'usersPage',
);

// Current page state
final currentPageReacton = reacton(1, name: 'currentPage');

// Widget
class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final page = context.watch(currentPageReacton);
    final usersPage = context.watch(usersPageQuery(page));

    return Column(
      children: [
        Expanded(
          child: usersPage.when(
            loading: () => Center(child: CircularProgressIndicator()),
            data: (data) => ListView.builder(
              itemCount: data.users.length,
              itemBuilder: (_, i) => UserTile(data.users[i]),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: page > 1
                  ? () => context.update(currentPageReacton, (p) => p - 1)
                  : null,
              icon: Icon(Icons.chevron_left),
            ),
            Text('Page $page'),
            IconButton(
              onPressed: () {
                // Prefetch next page for instant navigation
                final nextPage = page + 1;
                context.store.prefetchQuery(usersPageQuery(nextPage));
                context.update(currentPageReacton, (p) => p + 1);
              },
              icon: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
```

## What's Next

- [Retry Policies](/async/retry) -- Configure retry strategies for resilient fetches
- [Optimistic Updates](/async/optimistic) -- Apply changes instantly with automatic rollback
- [Middleware](/advanced/middleware) -- Intercept and transform reacton operations
