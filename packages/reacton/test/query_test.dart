import 'dart:async';

import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  // =========================================================================
  // QueryReacton unit tests
  // =========================================================================
  group('QueryReacton (unit)', () {
    test('creates with default config and AsyncLoading initial value', () {
      final query = reactonQuery<String>(
        queryFn: (_) async => 'hello',
        name: 'greeting',
      );

      expect(query.ref.debugName, 'greeting');
      expect(query.initialValue, isA<AsyncLoading<String>>());
      expect(query.config.staleTime, const Duration(minutes: 5));
      expect(query.config.cacheTime, const Duration(minutes: 30));
    });

    test('creates with custom config', () {
      final query = reactonQuery<int>(
        queryFn: (_) async => 42,
        config: const QueryConfig(
          staleTime: Duration(seconds: 30),
          cacheTime: Duration(minutes: 10),
          pollingInterval: Duration(seconds: 5),
        ),
      );

      expect(query.config.staleTime, const Duration(seconds: 30));
      expect(query.config.cacheTime, const Duration(minutes: 10));
      expect(query.config.pollingInterval, const Duration(seconds: 5));
    });
  });

  // =========================================================================
  // QueryConfig unit tests
  // =========================================================================
  group('QueryConfig', () {
    test('default values', () {
      const config = QueryConfig();
      expect(config.staleTime, const Duration(minutes: 5));
      expect(config.cacheTime, const Duration(minutes: 30));
      expect(config.refetchOnReconnect, isFalse);
      expect(config.refetchOnResume, isFalse);
      expect(config.pollingInterval, isNull);
      expect(config.retryPolicy, isNull);
    });
  });

  // =========================================================================
  // QueryContext unit tests
  // =========================================================================
  group('QueryContext', () {
    test('stores argument', () {
      final ctx = QueryContext<String>('user-123');
      expect(ctx.arg, 'user-123');
    });

    test('isCancelled is initially false', () {
      final ctx = QueryContext<void>(null);
      expect(ctx.isCancelled, isFalse);
    });

    test('throwIfCancelled does nothing when not cancelled', () {
      final ctx = QueryContext<void>(null);
      expect(() => ctx.throwIfCancelled(), returnsNormally);
    });
  });

  // =========================================================================
  // QueryCancelledException
  // =========================================================================
  group('QueryCancelledException', () {
    test('toString returns descriptive message', () {
      final ex = QueryCancelledException();
      expect(ex.toString(), contains('cancelled'));
    });
  });

  // =========================================================================
  // QueryReacton + ReactonStore integration tests
  // =========================================================================
  group('QueryReacton with ReactonStore', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    tearDown(() {
      store.dispose();
    });

    // -----------------------------------------------------------------------
    // Basic query fetch
    // -----------------------------------------------------------------------
    group('fetchQuery()', () {
      test('fetches data and returns it', () async {
        final query = reactonQuery<String>(
          queryFn: (_) async => 'hello world',
          name: 'basic',
        );

        final result = await store.fetchQuery(query);
        expect(result, 'hello world');
      });

      test('sets AsyncData in the store after successful fetch', () async {
        final query = reactonQuery<int>(
          queryFn: (_) async => 42,
        );

        await store.fetchQuery(query);

        final value = store.get(query);
        expect(value, isA<AsyncData<int>>());
        expect((value as AsyncData<int>).value, 42);
      });

      test('sets AsyncError in the store on failure', () async {
        final query = reactonQuery<String>(
          queryFn: (_) async => throw Exception('network error'),
        );

        try {
          await store.fetchQuery(query);
          fail('Expected an exception');
        } catch (e) {
          expect(e, isA<Exception>());
        }

        final value = store.get(query);
        expect(value, isA<AsyncError<String>>());
        expect((value as AsyncError<String>).error, isA<Exception>());
      });

      test('starts in AsyncLoading state before fetch completes', () async {
        final completer = Completer<String>();
        final query = reactonQuery<String>(
          queryFn: (_) => completer.future,
        );

        // Trigger the fetch but don't await
        final future = store.fetchQuery(query);

        // While waiting, the state should be loading
        final value = store.get(query);
        expect(value.isLoading, isTrue);

        completer.complete('done');
        await future;

        expect(store.get(query).hasData, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Stale time enforcement / cache hit
    // -----------------------------------------------------------------------
    group('stale time and caching', () {
      test('returns cached data when fresh (within staleTime)', () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            return fetchCount;
          },
          config: const QueryConfig(
            staleTime: Duration(minutes: 5), // long stale time
          ),
        );

        // First fetch
        final first = await store.fetchQuery(query);
        expect(first, 1);
        expect(fetchCount, 1);

        // Second fetch should return cached data without re-fetching
        final second = await store.fetchQuery(query);
        expect(second, 1);
        expect(fetchCount, 1); // Still 1 - no new fetch
      });

      test('refetches in background when data is stale', () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            return fetchCount;
          },
          config: const QueryConfig(
            staleTime: Duration.zero, // immediately stale
          ),
        );

        // First fetch
        final first = await store.fetchQuery(query);
        expect(first, 1);
        expect(fetchCount, 1);

        // Let the data become stale (staleTime is zero)
        // Second fetch should return stale data and trigger background refetch
        final second = await store.fetchQuery(query);
        // Returns stale cached data immediately
        expect(second, 1);

        // Allow background refetch to complete
        await Future.delayed(const Duration(milliseconds: 50));

        // The store should now have updated data from background refetch
        final value = store.get(query);
        expect(value, isA<AsyncData<int>>());
      });
    });

    // -----------------------------------------------------------------------
    // invalidateQuery
    // -----------------------------------------------------------------------
    group('invalidateQuery()', () {
      test('forces a refetch of the query', () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            return fetchCount;
          },
          config: const QueryConfig(
            staleTime: Duration(minutes: 5),
          ),
        );

        await store.fetchQuery(query);
        expect(fetchCount, 1);

        await store.invalidateQuery(query);
        expect(fetchCount, 2);

        final value = store.get(query);
        expect(value, isA<AsyncData<int>>());
        expect((value as AsyncData<int>).value, 2);
      });

      test('invalidateQuery on never-fetched query triggers fresh fetch',
          () async {
        var fetchCount = 0;
        final query = reactonQuery<String>(
          queryFn: (_) async {
            fetchCount++;
            return 'result-$fetchCount';
          },
        );

        await store.invalidateQuery(query);
        expect(fetchCount, 1);
      });
    });

    // -----------------------------------------------------------------------
    // prefetchQuery
    // -----------------------------------------------------------------------
    group('prefetchQuery()', () {
      test('fetches and caches data for later use', () async {
        var fetchCount = 0;
        final query = reactonQuery<String>(
          queryFn: (_) async {
            fetchCount++;
            return 'prefetched-$fetchCount';
          },
          config: const QueryConfig(
            staleTime: Duration(minutes: 5),
          ),
        );

        await store.prefetchQuery(query);
        expect(fetchCount, 1);

        // Subsequent fetchQuery should return cached data
        final result = await store.fetchQuery(query);
        expect(result, 'prefetched-1');
        expect(fetchCount, 1); // No additional fetch
      });

      test('skips fetch when data is already fresh', () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            return fetchCount;
          },
          config: const QueryConfig(
            staleTime: Duration(minutes: 5),
          ),
        );

        // Initial fetch
        await store.fetchQuery(query);
        expect(fetchCount, 1);

        // Prefetch should be a no-op since data is fresh
        await store.prefetchQuery(query);
        expect(fetchCount, 1);
      });
    });

    // -----------------------------------------------------------------------
    // setQueryData
    // -----------------------------------------------------------------------
    group('setQueryData()', () {
      test('manually sets query data in the cache', () {
        final query = reactonQuery<String>(
          queryFn: (_) async => 'from-network',
        );

        store.setQueryData(query, 'manual-data');

        final value = store.get(query);
        expect(value, isA<AsyncData<String>>());
        expect((value as AsyncData<String>).value, 'manual-data');
      });

      test('setQueryData makes subsequent fetchQuery return cached data',
          () async {
        var fetchCount = 0;
        final query = reactonQuery<String>(
          queryFn: (_) async {
            fetchCount++;
            return 'fetched-$fetchCount';
          },
          config: const QueryConfig(
            staleTime: Duration(minutes: 5),
          ),
        );

        store.setQueryData(query, 'optimistic');

        final result = await store.fetchQuery(query);
        expect(result, 'optimistic');
        expect(fetchCount, 0); // No fetch needed - data is fresh
      });

      test('setQueryData updates existing cache entry', () async {
        final query = reactonQuery<int>(
          queryFn: (_) async => 100,
          config: const QueryConfig(
            staleTime: Duration(minutes: 5),
          ),
        );

        await store.fetchQuery(query);

        store.setQueryData(query, 999);

        final value = store.get(query);
        expect((value as AsyncData<int>).value, 999);
      });
    });

    // -----------------------------------------------------------------------
    // removeQuery
    // -----------------------------------------------------------------------
    group('removeQuery()', () {
      test('removes query from cache', () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            return fetchCount;
          },
          config: const QueryConfig(
            staleTime: Duration(minutes: 5),
          ),
        );

        await store.fetchQuery(query);
        expect(fetchCount, 1);

        store.removeQuery(query);

        // After removal, next fetch should execute the query function again
        await store.fetchQuery(query);
        expect(fetchCount, 2);
      });

      test('removeQuery on non-existent query is safe', () {
        final query = reactonQuery<int>(
          queryFn: (_) async => 0,
        );

        // Should not throw
        expect(() => store.removeQuery(query), returnsNormally);
      });
    });

    // -----------------------------------------------------------------------
    // invalidateAllQueries
    // -----------------------------------------------------------------------
    group('invalidateAllQueries()', () {
      test('marks all queries as stale', () async {
        var fetchCountA = 0;
        var fetchCountB = 0;

        final queryA = reactonQuery<int>(
          queryFn: (_) async {
            fetchCountA++;
            return fetchCountA;
          },
          config: const QueryConfig(staleTime: Duration(minutes: 5)),
          name: 'queryA',
        );

        final queryB = reactonQuery<String>(
          queryFn: (_) async {
            fetchCountB++;
            return 'b-$fetchCountB';
          },
          config: const QueryConfig(staleTime: Duration(minutes: 5)),
          name: 'queryB',
        );

        await store.fetchQuery(queryA);
        await store.fetchQuery(queryB);
        expect(fetchCountA, 1);
        expect(fetchCountB, 1);

        store.invalidateAllQueries();

        // After invalidation, fetching should see stale data and trigger refetch
        // Since data is stale but exists, it returns stale data and refetches in background
        final resultA = await store.fetchQuery(queryA);
        expect(resultA, 1); // Returns stale cached value immediately

        // Wait for background refetch
        await Future.delayed(const Duration(milliseconds: 50));

        // New data should be available
        final valueA = store.get(queryA);
        expect(valueA, isA<AsyncData<int>>());
      });
    });

    // -----------------------------------------------------------------------
    // Query with retry on failure
    // -----------------------------------------------------------------------
    group('query with retry', () {
      test('retries on failure according to retry policy', () async {
        var attempts = 0;
        final query = reactonQuery<String>(
          queryFn: (_) async {
            attempts++;
            if (attempts < 3) {
              throw Exception('temporary error');
            }
            return 'success';
          },
          config: const QueryConfig(
            retryPolicy: RetryPolicy(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 1),
              backoffMultiplier: 1.0,
            ),
          ),
        );

        final result = await store.fetchQuery(query);
        expect(result, 'success');
        expect(attempts, 3);
      });

      test('gives up after max retry attempts', () async {
        var attempts = 0;
        final query = reactonQuery<String>(
          queryFn: (_) async {
            attempts++;
            throw Exception('permanent error');
          },
          config: const QueryConfig(
            retryPolicy: RetryPolicy(
              maxAttempts: 2,
              initialDelay: Duration(milliseconds: 1),
              backoffMultiplier: 1.0,
            ),
          ),
        );

        try {
          await store.fetchQuery(query);
          fail('Expected exception');
        } catch (e) {
          expect(e, isA<Exception>());
        }

        expect(attempts, 2);

        final value = store.get(query);
        expect(value, isA<AsyncError<String>>());
      });

      test('shouldRetry predicate controls which errors are retried', () async {
        var attempts = 0;
        final query = reactonQuery<String>(
          queryFn: (_) async {
            attempts++;
            if (attempts == 1) {
              throw const FormatException('not retryable');
            }
            return 'ok';
          },
          config: QueryConfig(
            retryPolicy: RetryPolicy(
              maxAttempts: 3,
              initialDelay: const Duration(milliseconds: 1),
              shouldRetry: (e) => e is! FormatException,
            ),
          ),
        );

        try {
          await store.fetchQuery(query);
          fail('Expected FormatException');
        } catch (e) {
          expect(e, isA<FormatException>());
        }

        // Only 1 attempt - the FormatException was not retryable
        expect(attempts, 1);
      });
    });

    // -----------------------------------------------------------------------
    // Query cancellation
    // -----------------------------------------------------------------------
    group('query cancellation', () {
      test('cancels previous in-flight query on new fetch', () async {
        final completer1 = Completer<String>();
        var callCount = 0;

        final query = reactonQuery<String>(
          queryFn: (_) async {
            callCount++;
            if (callCount == 1) {
              return completer1.future;
            }
            return 'second';
          },
          config: const QueryConfig(
            staleTime: Duration.zero,
          ),
        );

        // Start first query (will hang on completer)
        final firstFuture = store.fetchQuery(query);

        // Invalidate triggers a new query execution which cancels the first
        final secondFuture = store.invalidateQuery(query);

        // Complete the first completer - it should be cancelled
        completer1.complete('first');

        // The second query should succeed
        await secondFuture;

        final value = store.get(query);
        expect(value, isA<AsyncData<String>>());
        expect((value as AsyncData<String>).value, 'second');

        // Clean up the first future
        try {
          await firstFuture;
        } catch (_) {
          // May throw QueryCancelledException
        }
      });
    });

    // -----------------------------------------------------------------------
    // Query polling
    // -----------------------------------------------------------------------
    group('query polling', () {
      test('sets up periodic refetch when pollingInterval is configured',
          () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            return fetchCount;
          },
          config: const QueryConfig(
            staleTime: Duration(minutes: 5),
            pollingInterval: Duration(milliseconds: 50),
          ),
        );

        await store.fetchQuery(query);
        expect(fetchCount, 1);

        // Wait for a few polling intervals
        await Future.delayed(const Duration(milliseconds: 180));

        // Polling should have triggered additional fetches
        expect(fetchCount, greaterThan(1));

        // Clean up polling timer by removing the query
        store.removeQuery(query);
      });

      test('polling timer is cleaned up when query is removed', () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            return fetchCount;
          },
          config: const QueryConfig(
            pollingInterval: Duration(milliseconds: 50),
          ),
        );

        await store.fetchQuery(query);
        store.removeQuery(query);

        final countAfterRemove = fetchCount;
        await Future.delayed(const Duration(milliseconds: 150));

        // No additional fetches should have occurred after removal
        expect(fetchCount, countAfterRemove);
      });
    });

    // -----------------------------------------------------------------------
    // Stale-while-revalidate: AsyncLoading carries previousData
    // -----------------------------------------------------------------------
    group('stale-while-revalidate', () {
      test('AsyncLoading carries previousData during refetch', () async {
        final completer = Completer<String>();
        var callCount = 0;

        final query = reactonQuery<String>(
          queryFn: (_) async {
            callCount++;
            if (callCount == 1) return 'original';
            return completer.future;
          },
          config: const QueryConfig(
            staleTime: Duration.zero,
          ),
        );

        // First fetch
        await store.fetchQuery(query);
        expect(store.get(query), isA<AsyncData<String>>());

        // Invalidate to trigger refetch - will hang on completer
        final refetchFuture = store.invalidateQuery(query);

        // During refetch, state should be loading with previous data
        final loadingState = store.get(query);
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.valueOrNull, 'original');

        completer.complete('updated');
        await refetchFuture;

        expect((store.get(query) as AsyncData<String>).value, 'updated');
      });

      test('AsyncError carries previousData from last success', () async {
        var callCount = 0;

        final query = reactonQuery<String>(
          queryFn: (_) async {
            callCount++;
            if (callCount == 1) return 'success';
            throw Exception('fail');
          },
          config: const QueryConfig(
            staleTime: Duration.zero,
          ),
        );

        // First fetch succeeds
        await store.fetchQuery(query);

        // Invalidate triggers refetch which fails
        try {
          await store.invalidateQuery(query);
        } catch (_) {}

        final value = store.get(query);
        expect(value, isA<AsyncError<String>>());
        final errorValue = value as AsyncError<String>;
        expect(errorValue.previousData, 'success');
      });
    });

    // -----------------------------------------------------------------------
    // Concurrent query deduplication
    // -----------------------------------------------------------------------
    group('concurrent query deduplication', () {
      test('second fetch cancels first in-flight query', () async {
        var fetchCount = 0;
        final query = reactonQuery<int>(
          queryFn: (_) async {
            fetchCount++;
            await Future.delayed(const Duration(milliseconds: 20));
            return fetchCount;
          },
          config: const QueryConfig(
            staleTime: Duration.zero,
          ),
        );

        // Fire two invalidate calls rapidly
        final future1 = store.invalidateQuery(query);
        final future2 = store.invalidateQuery(query);

        // The first should be cancelled by the second
        try {
          await future1;
        } on QueryCancelledException {
          // Expected: first query was cancelled
        } catch (_) {
          // May also be cancelled differently
        }

        await future2;

        // The store should have data from the last successful fetch
        final value = store.get(query);
        expect(value, isA<AsyncData<int>>());
      });
    });
  });

  // =========================================================================
  // QueryFamily tests
  // =========================================================================
  group('QueryFamily', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    tearDown(() {
      store.dispose();
    });

    test('creates parameterized queries', () {
      final userQuery = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => 'User ${ctx.arg}',
        name: 'user',
      );

      final query1 = userQuery(1);
      final query2 = userQuery(2);

      expect(query1, isNot(same(query2)));
      expect(query1.ref.debugName, 'user(1)');
      expect(query2.ref.debugName, 'user(2)');
    });

    test('caches queries per argument', () {
      final userQuery = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => 'User ${ctx.arg}',
      );

      final first = userQuery(42);
      final second = userQuery(42);

      expect(first, same(second));
    });

    test('different arguments produce different queries', () {
      final userQuery = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => 'User ${ctx.arg}',
      );

      final q1 = userQuery(1);
      final q2 = userQuery(2);

      expect(q1, isNot(same(q2)));
    });

    test('fetches parameterized queries with correct argument', () async {
      final userQuery = reactonQueryFamily<String, String>(
        queryFn: (ctx) async => 'Hello, ${ctx.arg}!',
        name: 'greeting',
      );

      final result = await store.fetchQuery(userQuery('Alice'));
      expect(result, 'Hello, Alice!');

      final result2 = await store.fetchQuery(userQuery('Bob'));
      expect(result2, 'Hello, Bob!');
    });

    test('remove() removes a cached query for an argument', () {
      final family = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => 'item ${ctx.arg}',
      );

      final q1 = family(1);
      family.remove(1);

      final q1Again = family(1);
      expect(q1Again, isNot(same(q1)));
    });

    test('clear() removes all cached queries', () {
      final family = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => 'item ${ctx.arg}',
      );

      final q1 = family(1);
      final q2 = family(2);
      family.clear();

      expect(family(1), isNot(same(q1)));
      expect(family(2), isNot(same(q2)));
    });

    test('cachedArgs returns all cached argument keys', () {
      final family = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => 'item ${ctx.arg}',
      );

      family(1);
      family(2);
      family(3);

      expect(family.cachedArgs, containsAll([1, 2, 3]));
    });

    test('cachedArgs is empty initially', () {
      final family = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => '',
      );

      expect(family.cachedArgs, isEmpty);
    });

    test('family without name produces queries with null debugName', () {
      final family = reactonQueryFamily<String, int>(
        queryFn: (ctx) async => '',
      );

      final q = family(1);
      expect(q.ref.debugName, isNull);
    });
  });

  // =========================================================================
  // RetryPolicy unit tests
  // =========================================================================
  group('RetryPolicy', () {
    test('default values', () {
      const policy = RetryPolicy();
      expect(policy.maxAttempts, 3);
      expect(policy.initialDelay, const Duration(seconds: 1));
      expect(policy.backoffMultiplier, 2.0);
      expect(policy.maxDelay, isNull);
    });

    test('delayForAttempt calculates exponential backoff', () {
      const policy = RetryPolicy(
        initialDelay: Duration(milliseconds: 100),
        backoffMultiplier: 2.0,
      );

      expect(policy.delayForAttempt(0), const Duration(milliseconds: 100));
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 200));
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 400));
      expect(policy.delayForAttempt(3), const Duration(milliseconds: 800));
    });

    test('delayForAttempt respects maxDelay', () {
      const policy = RetryPolicy(
        initialDelay: Duration(milliseconds: 100),
        backoffMultiplier: 2.0,
        maxDelay: Duration(milliseconds: 300),
      );

      expect(policy.delayForAttempt(0), const Duration(milliseconds: 100));
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 200));
      // Would be 400ms but capped at 300ms
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 300));
      expect(policy.delayForAttempt(3), const Duration(milliseconds: 300));
    });

    test('canRetry respects maxAttempts', () {
      const policy = RetryPolicy(maxAttempts: 2);

      expect(policy.canRetry(Exception(), 0), isTrue);
      expect(policy.canRetry(Exception(), 1), isTrue);
      expect(policy.canRetry(Exception(), 2), isFalse);
      expect(policy.canRetry(Exception(), 3), isFalse);
    });

    test('canRetry uses shouldRetry predicate', () {
      final policy = RetryPolicy(
        maxAttempts: 5,
        shouldRetry: (error) => error is! FormatException,
      );

      expect(policy.canRetry(Exception('ok'), 0), isTrue);
      expect(policy.canRetry(const FormatException('no'), 0), isFalse);
    });

    test('canRetry returns true for all errors when shouldRetry is null', () {
      const policy = RetryPolicy(maxAttempts: 5);
      expect(policy.canRetry(Exception(), 0), isTrue);
      expect(policy.canRetry(const FormatException(), 0), isTrue);
      expect(policy.canRetry(StateError(''), 0), isTrue);
    });
  });
}
