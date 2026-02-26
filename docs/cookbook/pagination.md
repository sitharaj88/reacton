# Pagination

Infinite scroll with `QueryReacton`: paginated API fetching, load more, pull-to-refresh, and stale-while-revalidate.

## Data Model

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

class Post {
  final int id;
  final String title;
  final String body;

  const Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
  );
}

class PagedResponse<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final bool hasMore;

  const PagedResponse({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });
}
```

## Simulated API

```dart
class PostApi {
  static Future<PagedResponse<Post>> fetchPosts({
    required int page,
    int pageSize = 20,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate 100 total posts
    const totalPosts = 100;
    final totalPages = (totalPosts / pageSize).ceil();
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalPosts);

    final items = List.generate(
      endIndex - startIndex,
      (i) => Post(
        id: startIndex + i + 1,
        title: 'Post #${startIndex + i + 1}',
        body: 'This is the body of post ${startIndex + i + 1}.',
      ),
    );

    return PagedResponse(
      items: items,
      page: page,
      totalPages: totalPages,
      hasMore: page < totalPages,
    );
  }
}
```

## Reacton Definitions

```dart
/// Current page number.
final currentPageReacton = reacton(1, name: 'currentPage');

/// Accumulated list of all loaded posts.
final allPostsReacton = reacton<List<Post>>([], name: 'allPosts');

/// Whether there are more pages to load.
final hasMoreReacton = reacton(true, name: 'hasMore');

/// Whether a page is currently being fetched.
final isLoadingMoreReacton = reacton(false, name: 'isLoadingMore');

/// The initial page query using reactonQuery with caching.
final postsQuery = reactonQuery<PagedResponse<Post>>(
  queryFn: (_) => PostApi.fetchPosts(page: 1),
  config: QueryConfig(
    staleTime: const Duration(minutes: 5),
    cacheTime: const Duration(minutes: 30),
    retryPolicy: RetryPolicy(maxAttempts: 3),
  ),
  name: 'postsQuery',
);

/// Total loaded post count.
final postCountReacton = computed(
  (read) => read(allPostsReacton).length,
  name: 'postCount',
);
```

## Pagination Logic

```dart
/// Load the initial page of posts.
Future<void> loadInitialPosts(ReactonStore store) async {
  try {
    final response = await store.fetchQuery(postsQuery);
    store.batch(() {
      store.set(allPostsReacton, response.items);
      store.set(currentPageReacton, response.page);
      store.set(hasMoreReacton, response.hasMore);
    });
  } catch (e) {
    debugPrint('Failed to load posts: $e');
  }
}

/// Load the next page of posts (append to existing list).
Future<void> loadMorePosts(ReactonStore store) async {
  final isLoading = store.get(isLoadingMoreReacton);
  final hasMore = store.get(hasMoreReacton);

  if (isLoading || !hasMore) return;

  store.set(isLoadingMoreReacton, true);

  try {
    final currentPage = store.get(currentPageReacton);
    final nextPage = currentPage + 1;

    final response = await PostApi.fetchPosts(page: nextPage);

    store.batch(() {
      store.update(allPostsReacton, (posts) => [...posts, ...response.items]);
      store.set(currentPageReacton, nextPage);
      store.set(hasMoreReacton, response.hasMore);
      store.set(isLoadingMoreReacton, false);
    });
  } catch (e) {
    store.set(isLoadingMoreReacton, false);
    debugPrint('Failed to load more posts: $e');
  }
}

/// Refresh: clear all posts and reload from page 1.
Future<void> refreshPosts(ReactonStore store) async {
  store.batch(() {
    store.set(allPostsReacton, <Post>[]);
    store.set(currentPageReacton, 1);
    store.set(hasMoreReacton, true);
  });

  // Invalidate the query to force a fresh fetch
  await store.invalidateQuery(postsQuery);
  await loadInitialPosts(store);
}
```

## UI Implementation

```dart
void main() {
  final store = ReactonStore();

  runApp(ReactonScope(
    store: store,
    child: const PaginationApp(),
  ));

  // Load initial data
  loadInitialPosts(store);
}

class PaginationApp extends StatelessWidget {
  const PaginationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagination Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const PostListPage(),
    );
  }
}

class PostListPage extends StatelessWidget {
  const PostListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch(allPostsReacton);
    final hasMore = context.watch(hasMoreReacton);
    final isLoadingMore = context.watch(isLoadingMoreReacton);
    final queryState = context.watch(postsQuery);
    final postCount = context.watch(postCountReacton);

    return Scaffold(
      appBar: AppBar(
        title: Text('Posts ($postCount)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshPosts(context.reactonStore),
          ),
        ],
      ),
      body: queryState.when(
        loading: () {
          if (posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // Stale-while-revalidate: show existing posts while refreshing
          return _PostList(
            posts: posts,
            hasMore: hasMore,
            isLoadingMore: true,
          );
        },
        data: (_) => _PostList(
          posts: posts,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
        ),
        error: (error, _) {
          if (posts.isNotEmpty) {
            // Show posts with error banner
            return Column(
              children: [
                MaterialBanner(
                  content: Text('Error: $error'),
                  actions: [
                    TextButton(
                      onPressed: () => refreshPosts(context.reactonStore),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                Expanded(
                  child: _PostList(
                    posts: posts,
                    hasMore: hasMore,
                    isLoadingMore: false,
                  ),
                ),
              ],
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => refreshPosts(context.reactonStore),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<Post> posts;
  final bool hasMore;
  final bool isLoadingMore;

  const _PostList({
    required this.posts,
    required this.hasMore,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Load more when user scrolls near the bottom
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            loadMorePosts(context.reactonStore);
          }
        }
        return false;
      },
      child: ListView.builder(
        itemCount: posts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            // Loading indicator at the bottom
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => loadMorePosts(context.reactonStore),
                        child: const Text('Load More'),
                      ),
              ),
            );
          }

          final post = posts[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${post.id}')),
            title: Text(post.title),
            subtitle: Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}
```

## Key Concepts

### QueryReacton with Caching

`reactonQuery` provides automatic caching with configurable `staleTime` and `cacheTime`. While data is fresh (within `staleTime`), re-fetches are skipped. When data becomes stale, the cached data is returned immediately while a background refetch occurs (stale-while-revalidate).

### Infinite Scroll Pattern

1. Track `currentPage`, `allPosts`, `hasMore`, and `isLoadingMore` as separate reactons
2. `loadMorePosts` checks guards (not already loading, has more pages) before fetching
3. On success, append new items to the existing list using `batch()`
4. A `ScrollNotification` listener triggers loading when the user scrolls near the bottom

### Pull-to-Refresh

`refreshPosts` clears all state, invalidates the query cache, and reloads from page 1. `invalidateQuery` forces the query to refetch regardless of stale time.

### Error Handling

When errors occur but cached data exists, the UI shows the cached posts with an error banner. When no data exists, a full-screen error with a retry button is shown.

## What's Next

- [Offline-First](./offline-first) -- Persistence and optimistic updates
- [Todo App](./todo-app) -- CRUD operations and filtering
- [Authentication](./authentication) -- State machine patterns
