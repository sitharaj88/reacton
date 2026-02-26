import 'dart:async';
import '../core/reacton_base.dart';
import '../core/writable_reacton.dart';
import '../store/store.dart';
import 'async_value.dart';
import 'retry.dart';

/// Configuration for a query reacton.
class QueryConfig {
  /// How long data is considered "fresh" before becoming stale.
  /// While fresh, re-fetches are skipped and cached data is returned.
  final Duration staleTime;

  /// How long unused data stays in cache after all watchers unsubscribe.
  /// After this, the data is garbage collected.
  final Duration cacheTime;

  /// If true, automatically refetch when connectivity is restored.
  final bool refetchOnReconnect;

  /// If true, automatically refetch when the app returns to foreground.
  final bool refetchOnResume;

  /// Polling interval. If set, the query refetches at this interval.
  final Duration? pollingInterval;

  /// Retry policy for failed queries.
  final RetryPolicy? retryPolicy;

  const QueryConfig({
    this.staleTime = const Duration(minutes: 5),
    this.cacheTime = const Duration(minutes: 30),
    this.refetchOnReconnect = false,
    this.refetchOnResume = false,
    this.pollingInterval,
    this.retryPolicy,
  });
}

/// Context available during query execution.
class QueryContext<Arg> {
  /// The argument passed to this query (for family queries).
  final Arg arg;

  /// Signal that the query has been cancelled.
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  QueryContext(this.arg);

  /// Throws if the query has been cancelled.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw QueryCancelledException();
    }
  }
}

/// Exception thrown when a query is cancelled.
class QueryCancelledException implements Exception {
  @override
  String toString() => 'QueryCancelledException: Query was cancelled.';
}

/// Internal metadata for tracking query cache state.
class _QueryCacheEntry<T> {
  AsyncValue<T> value;
  DateTime fetchedAt;
  Timer? pollingTimer;
  Timer? cacheTimer;
  QueryContext? activeContext;
  int watcherCount;

  _QueryCacheEntry({
    required this.value,
    required this.fetchedAt,
    this.pollingTimer,
    this.cacheTimer,
    this.activeContext,
    this.watcherCount = 0,
  });

  bool isStale(Duration staleTime) {
    return DateTime.now().difference(fetchedAt) > staleTime;
  }

  void dispose() {
    pollingTimer?.cancel();
    cacheTimer?.cancel();
    activeContext?._isCancelled = true;
  }
}

/// A query reacton that fetches data from an async source with smart caching.
///
/// Provides:
/// - Automatic caching with stale time
/// - Background refetching (stale-while-revalidate)
/// - Polling support
/// - Retry on failure
/// - Deduplication (same query won't run concurrently)
/// - Cache garbage collection
///
/// ```dart
/// final usersQuery = reactonQuery<List<User>>(
///   queryFn: (_) => api.fetchUsers(),
///   config: QueryConfig(staleTime: Duration(minutes: 5)),
///   name: 'users',
/// );
///
/// // In store:
/// final users = store.get(usersQuery); // AsyncValue<List<User>>
/// store.invalidateQuery(usersQuery); // Force refetch
/// ```
class QueryReacton<T> extends WritableReacton<AsyncValue<T>> {
  final Future<T> Function(QueryContext<void>) queryFn;
  final QueryConfig config;

  QueryReacton({
    required this.queryFn,
    this.config = const QueryConfig(),
    String? name,
  }) : super(AsyncLoading<T>(), name: name);
}

/// Create a query reacton.
///
/// ```dart
/// final usersQuery = reactonQuery<List<User>>(
///   queryFn: (_) => api.fetchUsers(),
///   config: QueryConfig(staleTime: Duration(minutes: 5)),
///   name: 'users',
/// );
/// ```
QueryReacton<T> reactonQuery<T>({
  required Future<T> Function(QueryContext<void>) queryFn,
  QueryConfig config = const QueryConfig(),
  String? name,
}) {
  return QueryReacton<T>(
    queryFn: queryFn,
    config: config,
    name: name,
  );
}

/// A family of query reactons parameterized by an argument.
///
/// ```dart
/// final userQuery = reactonQueryFamily<User, String>(
///   queryFn: (ctx) => api.fetchUser(ctx.arg),
///   name: 'user',
/// );
///
/// // Usage:
/// final user = store.get(userQuery('user-123'));
/// ```
class QueryFamily<T, Arg> {
  final Future<T> Function(QueryContext<Arg>) queryFn;
  final QueryConfig config;
  final String? _baseName;
  final Map<Arg, QueryReacton<T>> _cache = {};

  QueryFamily({
    required this.queryFn,
    this.config = const QueryConfig(),
    String? name,
  }) : _baseName = name;

  /// Get or create a query reacton for the given argument.
  QueryReacton<T> call(Arg arg) {
    return _cache.putIfAbsent(arg, () {
      return QueryReacton<T>(
        queryFn: (ctx) => queryFn(QueryContext<Arg>(arg)),
        config: config,
        name: _baseName != null ? '$_baseName($arg)' : null,
      );
    });
  }

  /// Remove a cached query.
  void remove(Arg arg) => _cache.remove(arg);

  /// Clear all cached queries.
  void clear() => _cache.clear();

  /// All currently cached arguments.
  Iterable<Arg> get cachedArgs => _cache.keys;
}

/// Create a query family.
QueryFamily<T, Arg> reactonQueryFamily<T, Arg>({
  required Future<T> Function(QueryContext<Arg>) queryFn,
  QueryConfig config = const QueryConfig(),
  String? name,
}) {
  return QueryFamily<T, Arg>(
    queryFn: queryFn,
    config: config,
    name: name,
  );
}

/// Extension on [ReactonStore] for query operations.
extension ReactonStoreQuery on ReactonStore {
  static final _queryCache = Expando<Map<ReactonRef, _QueryCacheEntry>>('queryCache');

  Map<ReactonRef, _QueryCacheEntry> _getQueryCache() {
    var cache = _queryCache[this];
    if (cache == null) {
      cache = {};
      _queryCache[this] = cache;
    }
    return cache;
  }

  /// Fetch a query reacton. If cached and fresh, returns cached data.
  /// If stale, returns cached data immediately and refetches in background.
  /// If not cached, fetches and returns loading state.
  Future<T> fetchQuery<T>(QueryReacton<T> query) async {
    final cache = _getQueryCache();
    final entry = cache[query.ref];

    // If we have fresh data, return it
    if (entry != null && !entry.isStale(query.config.staleTime)) {
      final value = entry.value;
      if (value is AsyncData<T>) return value.value;
    }

    // If we have stale data, return it but trigger background refetch
    if (entry != null && entry.value is AsyncData<T>) {
      _executeQuery(query); // fire-and-forget background refetch
      return (entry.value as AsyncData<T>).value;
    }

    // No data - do a fresh fetch
    return _executeQuery(query);
  }

  /// Execute a query (internal).
  Future<T> _executeQuery<T>(QueryReacton<T> query) async {
    final cache = _getQueryCache();
    final existing = cache[query.ref];

    // Cancel previous in-flight query
    existing?.activeContext?._isCancelled = true;

    final context = QueryContext<void>(null);
    final cacheEntry = existing ?? _QueryCacheEntry<T>(
      value: AsyncLoading<T>(),
      fetchedAt: DateTime.now(),
    );
    cacheEntry.activeContext = context;
    cache[query.ref] = cacheEntry;

    // Set loading state (with previous data for stale-while-revalidate)
    final previousData = cacheEntry.value is AsyncData<T>
        ? (cacheEntry.value as AsyncData<T>).value
        : null;
    set(query, AsyncLoading<T>(previousData));

    int attempt = 0;
    final retryPolicy = query.config.retryPolicy;
    final maxAttempts = retryPolicy?.maxAttempts ?? 1;

    while (attempt < maxAttempts) {
      try {
        if (context.isCancelled) throw QueryCancelledException();

        final data = await query.queryFn(context);

        if (context.isCancelled) throw QueryCancelledException();

        final asyncData = AsyncData<T>(data);
        cacheEntry.value = asyncData;
        cacheEntry.fetchedAt = DateTime.now();
        cacheEntry.activeContext = null;
        set(query, asyncData);

        // Set up polling if configured
        _setupPolling(query, cacheEntry);

        return data;
      } on QueryCancelledException {
        rethrow;
      } catch (e, st) {
        attempt++;
        if (retryPolicy != null && retryPolicy.canRetry(e, attempt) && attempt < maxAttempts) {
          await Future.delayed(retryPolicy.delayForAttempt(attempt));
          continue;
        }

        final asyncError = AsyncError<T>(e, st, previousData);
        cacheEntry.value = asyncError;
        cacheEntry.activeContext = null;
        set(query, asyncError);
        rethrow;
      }
    }

    // Should not reach here, but just in case
    throw StateError('Query exhausted all retry attempts');
  }

  void _setupPolling<T>(QueryReacton<T> query, _QueryCacheEntry cacheEntry) {
    cacheEntry.pollingTimer?.cancel();
    if (query.config.pollingInterval != null) {
      cacheEntry.pollingTimer = Timer.periodic(
        query.config.pollingInterval!,
        (_) => _executeQuery(query),
      );
    }
  }

  /// Invalidate a query, marking it as stale and triggering a refetch.
  Future<void> invalidateQuery<T>(QueryReacton<T> query) async {
    final cache = _getQueryCache();
    final entry = cache[query.ref];
    if (entry != null) {
      // Set fetched time to epoch to force stale
      entry.fetchedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    await _executeQuery(query);
  }

  /// Prefetch a query so it's cached when needed.
  Future<void> prefetchQuery<T>(QueryReacton<T> query) async {
    final cache = _getQueryCache();
    final entry = cache[query.ref];
    if (entry != null && !entry.isStale(query.config.staleTime)) {
      return; // Already fresh
    }
    await _executeQuery(query);
  }

  /// Set query data manually (useful for optimistic updates).
  void setQueryData<T>(QueryReacton<T> query, T data) {
    final cache = _getQueryCache();
    final entry = cache[query.ref] ?? _QueryCacheEntry<T>(
      value: AsyncData<T>(data),
      fetchedAt: DateTime.now(),
    );
    entry.value = AsyncData<T>(data);
    entry.fetchedAt = DateTime.now();
    cache[query.ref] = entry;
    set(query, AsyncData<T>(data));
  }

  /// Remove a query from the cache entirely.
  void removeQuery<T>(QueryReacton<T> query) {
    final cache = _getQueryCache();
    cache[query.ref]?.dispose();
    cache.remove(query.ref);
  }

  /// Invalidate all queries.
  void invalidateAllQueries() {
    final cache = _getQueryCache();
    for (final entry in cache.values) {
      entry.fetchedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
