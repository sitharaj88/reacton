# Search with Debounce

A search page with debounced API calls, query caching, loading/error/data states, and computed local filtering. Demonstrates `Debouncer`, `reactonQuery`, `computed`, and `AsyncValue` pattern matching for a responsive search experience.

## Full Source

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- Models ---

class SearchResult {
  final String id;
  final String title;
  final String description;
  final String category;

  const SearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });
}

enum ResultCategory { all, article, video, tutorial }

// --- Simulated API ---

class SearchApi {
  static Future<List<SearchResult>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (query.isEmpty) return [];

    // Simulate an API failure for testing
    if (query.toLowerCase() == 'error') {
      throw Exception('Search service unavailable');
    }

    final lower = query.toLowerCase();
    return _mockDatabase
        .where((r) =>
            r.title.toLowerCase().contains(lower) ||
            r.description.toLowerCase().contains(lower))
        .toList();
  }

  static final _mockDatabase = [
    const SearchResult(
      id: '1',
      title: 'Getting Started with Reacton',
      description: 'Learn the fundamentals of reactive state management.',
      category: 'article',
    ),
    const SearchResult(
      id: '2',
      title: 'Reacton in 10 Minutes',
      description: 'A video walkthrough of building your first app.',
      category: 'video',
    ),
    const SearchResult(
      id: '3',
      title: 'Advanced Computed Reactons',
      description: 'Deep dive into derived state and memoisation.',
      category: 'tutorial',
    ),
    const SearchResult(
      id: '4',
      title: 'State Machines with Reacton',
      description: 'Model complex flows with typed state machines.',
      category: 'article',
    ),
    const SearchResult(
      id: '5',
      title: 'Building Forms with Reacton',
      description: 'Per-field validation and async submit patterns.',
      category: 'tutorial',
    ),
    const SearchResult(
      id: '6',
      title: 'Query Caching Explained',
      description: 'Stale-while-revalidate and cache invalidation.',
      category: 'video',
    ),
    const SearchResult(
      id: '7',
      title: 'Optimistic Updates Tutorial',
      description: 'Instant UI feedback with automatic rollback.',
      category: 'tutorial',
    ),
    const SearchResult(
      id: '8',
      title: 'Reactive Collections Deep Dive',
      description: 'Observable lists and maps for granular updates.',
      category: 'article',
    ),
  ];
}

// --- Reactons ---

/// The raw text from the search input (updated on every keystroke).
final searchInputReacton = reacton('', name: 'searchInput');

/// The debounced query that actually triggers API calls.
final debouncedQueryReacton = reacton('', name: 'debouncedQuery');

/// Category filter applied locally to search results.
final categoryFilterReacton = reacton(ResultCategory.all, name: 'categoryFilter');

/// Debouncer instance: waits 300ms after the last keystroke.
final searchDebouncer = Debouncer(duration: const Duration(milliseconds: 300));

/// Query reacton that fetches results for the debounced query.
/// Results are cached so repeated searches resolve instantly.
final searchQuery = reactonQuery<List<SearchResult>>(
  queryFn: (read) => SearchApi.search(read(debouncedQueryReacton)),
  config: QueryConfig(
    staleTime: const Duration(minutes: 5),
    cacheTime: const Duration(minutes: 15),
    retryPolicy: RetryPolicy(maxAttempts: 2),
  ),
  name: 'searchQuery',
);

/// Computed: filters the raw API results by the selected category.
final filteredResultsReacton = computed<List<SearchResult>>((read) {
  final queryState = read(searchQuery);
  final category = read(categoryFilterReacton);

  final results = queryState.when(
    loading: () => <SearchResult>[],
    data: (data) => data,
    error: (_, __) => <SearchResult>[],
  );

  if (category == ResultCategory.all) return results;

  final categoryName = category.name; // 'article', 'video', 'tutorial'
  return results.where((r) => r.category == categoryName).toList();
}, name: 'filteredResults');

/// Computed: count of results per category for the chip badges.
final categoryCounts = computed((read) {
  final queryState = read(searchQuery);

  final results = queryState.when(
    loading: () => <SearchResult>[],
    data: (data) => data,
    error: (_, __) => <SearchResult>[],
  );

  return (
    all: results.length,
    article: results.where((r) => r.category == 'article').length,
    video: results.where((r) => r.category == 'video').length,
    tutorial: results.where((r) => r.category == 'tutorial').length,
  );
}, name: 'categoryCounts');

// --- Debounce Wiring ---

/// Call this from the text field's onChanged. It updates the input
/// immediately (for the UI) and debounces the query (for the API).
void onSearchChanged(ReactonStore store, String value) {
  store.set(searchInputReacton, value);

  searchDebouncer.run(() {
    store.set(debouncedQueryReacton, value.trim());
  });
}

// --- App ---

void main() => runApp(ReactonScope(child: const SearchApp()));

class SearchApp extends StatelessWidget {
  const SearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Search Example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonConsumer(
      builder: (context, ref) {
        final input = ref.watch(searchInputReacton);
        final queryState = ref.watch(searchQuery);
        final filtered = ref.watch(filteredResultsReacton);
        final counts = ref.watch(categoryCounts);
        final category = ref.watch(categoryFilterReacton);

        return Scaffold(
          appBar: AppBar(title: const Text('Search')),
          body: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search articles, videos, tutorials...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: input.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                onSearchChanged(context.reactonStore, ''),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => onSearchChanged(context.reactonStore, v),
                ),
              ),

              // Category filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ResultCategory.values.map((c) {
                    final count = switch (c) {
                      ResultCategory.all => counts.all,
                      ResultCategory.article => counts.article,
                      ResultCategory.video => counts.video,
                      ResultCategory.tutorial => counts.tutorial,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${c.name} ($count)'),
                        selected: category == c,
                        onSelected: (_) =>
                            context.set(categoryFilterReacton, c),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Results area
              Expanded(
                child: queryState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Error: $error'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.reactonStore
                              .invalidateQuery(searchQuery),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (_) {
                    if (input.isEmpty) {
                      return const Center(
                        child: Text('Type to search'),
                      );
                    }
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No results found'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = filtered[index];
                        return ListTile(
                          leading: Icon(_iconForCategory(result.category)),
                          title: Text(result.title),
                          subtitle: Text(
                            result.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Chip(label: Text(result.category)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'article' => Icons.article_outlined,
      'video' => Icons.play_circle_outline,
      'tutorial' => Icons.school_outlined,
      _ => Icons.description_outlined,
    };
  }
}
```

## Walkthrough

### Data Model and API

`SearchResult` is a plain Dart class with an `id`, `title`, `description`, and `category`. The `SearchApi.search` method simulates a network call with a 600ms delay and filters a mock database. Typing `"error"` triggers an exception so you can test the error state.

### Debouncer Setup

Two reactons separate the raw input from the debounced query:

```dart
final searchInputReacton = reacton('', name: 'searchInput');
final debouncedQueryReacton = reacton('', name: 'debouncedQuery');

final searchDebouncer = Debouncer(duration: const Duration(milliseconds: 300));
```

`searchInputReacton` updates on every keystroke so the text field stays responsive. `debouncedQueryReacton` only updates 300ms after the user stops typing, which is what the query reacton reads.

### Debounce Wiring

```dart
void onSearchChanged(ReactonStore store, String value) {
  store.set(searchInputReacton, value);

  searchDebouncer.run(() {
    store.set(debouncedQueryReacton, value.trim());
  });
}
```

`Debouncer.run` cancels any pending invocation and schedules a new one. This means if the user types `"react"` quickly, only one API call fires for the final value rather than five calls for `"r"`, `"re"`, `"rea"`, `"reac"`, `"react"`.

### Query Reacton with Caching

```dart
final searchQuery = reactonQuery<List<SearchResult>>(
  queryFn: (read) => SearchApi.search(read(debouncedQueryReacton)),
  config: QueryConfig(
    staleTime: const Duration(minutes: 5),
    cacheTime: const Duration(minutes: 15),
    retryPolicy: RetryPolicy(maxAttempts: 2),
  ),
  name: 'searchQuery',
);
```

The `queryFn` reads `debouncedQueryReacton` through the `read` function, which establishes a reactive dependency. Whenever the debounced query changes, the query refetches automatically. Results are cached: if the user searches `"react"`, navigates away, and comes back to `"react"`, the cached data resolves instantly without a network call.

### Computed Filtering

```dart
final filteredResultsReacton = computed<List<SearchResult>>((read) {
  final queryState = read(searchQuery);
  final category = read(categoryFilterReacton);

  final results = queryState.when(
    loading: () => <SearchResult>[],
    data: (data) => data,
    error: (_, __) => <SearchResult>[],
  );

  if (category == ResultCategory.all) return results;

  final categoryName = category.name;
  return results.where((r) => r.category == categoryName).toList();
}, name: 'filteredResults');
```

This computed reacton combines two sources: the query state and the selected category. The `when` method extracts the data from the `AsyncValue` wrapper. Changing the category filter applies instantly without re-fetching because the filtering happens locally on already-loaded results.

### Category Count Badges

```dart
final categoryCounts = computed((read) {
  final queryState = read(searchQuery);
  final results = queryState.when(
    loading: () => <SearchResult>[],
    data: (data) => data,
    error: (_, __) => <SearchResult>[],
  );

  return (
    all: results.length,
    article: results.where((r) => r.category == 'article').length,
    video: results.where((r) => r.category == 'video').length,
    tutorial: results.where((r) => r.category == 'tutorial').length,
  );
}, name: 'categoryCounts');
```

A Dart record holds the counts. The filter chips display these inline so the user can see how many results exist in each category before selecting.

### AsyncValue Pattern Matching

The UI uses `queryState.when` to render the correct state:

```dart
queryState.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, _) => Center(child: ...),
  data: (_) {
    if (input.isEmpty) return const Center(child: Text('Type to search'));
    if (filtered.isEmpty) return const Center(child: Text('No results found'));
    return ListView.separated(...);
  },
)
```

This exhaustive pattern ensures the loading spinner, error message, empty state, and result list are all handled.

## Key Takeaways

1. **Debouncer prevents excessive API calls** -- The raw input updates immediately for UI responsiveness, while the debounced value triggers network requests only after the user pauses typing.
2. **Query caching makes repeated searches instant** -- `staleTime` and `cacheTime` in `QueryConfig` control when cached data is reused vs. refetched.
3. **Computed reactons layer local filtering on top of remote data** -- Category filtering runs client-side against the cached results without additional API calls.
4. **AsyncValue.when provides exhaustive state handling** -- Every possible state (loading, error, data) is handled in the UI with no missing branches.
5. **Dart records work well for computed aggregations** -- The `categoryCounts` record groups related derived values into a single computed reacton.

## What's Next

- [Pagination](./pagination) -- Infinite scroll with QueryReacton and stale-while-revalidate
- [Shopping Cart](./shopping-cart) -- Modules, persistence, and optimistic updates
- [Form Validation](./form-validation) -- Per-field validation with async support
