import CodeBlock from '../components/CodeBlock'
import Callout from '../components/Callout'
import PageNav from '../components/PageNav'

export default function AsyncMiddleware() {
  return (
    <div>
      <h1 className="text-4xl font-extrabold tracking-tight mb-4">Async & Middleware</h1>
      <p className="text-lg text-gray-500 dark:text-gray-400 mb-8">
        Handle asynchronous operations with first-class reactive primitives and intercept state changes using a powerful middleware pipeline. This guide covers everything from basic async data fetching to advanced middleware composition, persistence, and optimistic updates.
      </p>

      {/* ================================================================== */}
      {/* AsyncValue<T> */}
      {/* ================================================================== */}
      <h2 id="async-value" className="text-2xl font-bold mt-12 mb-4">
        AsyncValue&lt;T&gt;
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue&lt;T&gt;</code> is a sealed class that represents one of three possible states for any asynchronous operation: loading, data, or error. By encoding these states into the type system, Reacton eliminates the common pitfalls of manual boolean flags and ensures that every async state is handled exhaustively in your UI.
      </p>

      <h3 id="async-value-states" className="text-xl font-semibold mt-8 mb-3">The Three States</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Every <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue&lt;T&gt;</code> is exactly one of the following sealed subtypes:
      </p>
      <CodeBlock
        title="AsyncValue sealed class hierarchy"
        code={`/// Sealed class — exactly one of these at any time.
sealed class AsyncValue<T> {
  const AsyncValue();
}

/// The operation is in progress.
/// [previousData] holds the last successful value (if any)
/// for stale-while-revalidate patterns.
class AsyncLoading<T> extends AsyncValue<T> {
  final T? previousData;
  const AsyncLoading({this.previousData});
}

/// The operation completed successfully with [value].
class AsyncData<T> extends AsyncValue<T> {
  final T value;
  const AsyncData(this.value);
}

/// The operation failed with [error] and [stackTrace].
class AsyncError<T> extends AsyncValue<T> {
  final Object error;
  final StackTrace stackTrace;
  const AsyncError(this.error, this.stackTrace);
}`}
      />

      <div className="overflow-x-auto my-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Subtype</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Properties</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncLoading&lt;T&gt;</code></td>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">T? previousData</code></td>
              <td className="py-3 px-4">Operation in progress. Optionally carries the last successful value for stale-while-revalidate.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncData&lt;T&gt;</code></td>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">T value</code></td>
              <td className="py-3 px-4">Operation succeeded. Contains the resulting data.</td>
            </tr>
            <tr>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncError&lt;T&gt;</code></td>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Object error</code>, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">StackTrace stackTrace</code></td>
              <td className="py-3 px-4">Operation failed. Contains the error and its stack trace.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 id="pattern-matching-when" className="text-xl font-semibold mt-8 mb-3">Pattern Matching with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.when()</code></h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.when()</code> method is the primary way to handle all three states exhaustively. You provide a callback for each state, and the correct one is invoked based on the current value. This is the recommended approach because the compiler enforces that you handle every case.
      </p>
      <CodeBlock
        title="Exhaustive pattern matching with .when()"
        code={`final asyncUsers = store.read(usersAtom);

Widget build(BuildContext context) {
  return asyncUsers.when(
    loading: () => const Center(
      child: CircularProgressIndicator(),
    ),
    data: (List<User> users) => ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) => UserTile(user: users[index]),
    ),
    error: (Object error, StackTrace stackTrace) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to load users: \$error'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => store.refresh(usersAtom),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}`}
      />

      <h3 id="when-or-null" className="text-xl font-semibold mt-8 mb-3">Partial Handling with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.whenOrNull()</code></h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you only care about certain states and want to return <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">null</code> for the rest, use <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.whenOrNull()</code>. All callbacks are optional. Any unhandled state returns <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">null</code>.
      </p>
      <CodeBlock
        title="whenOrNull - handle only the states you need"
        code={`// Only show a snackbar when an error occurs
asyncValue.whenOrNull(
  error: (e, stack) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: \$e')),
    );
    return true; // handled
  },
);

// Only extract the data, ignoring loading/error
final String? userName = asyncUser.whenOrNull(
  data: (user) => user.displayName,
);`}
      />

      <h3 id="maybe-when" className="text-xl font-semibold mt-8 mb-3">Default Fallback with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.maybeWhen()</code></h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Similar to <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.whenOrNull()</code>, but with a required <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">orElse</code> callback that handles any state you have not explicitly handled. This is useful when you want a non-null fallback.
      </p>
      <CodeBlock
        title="maybeWhen with orElse fallback"
        code={`final widget = asyncValue.maybeWhen(
  data: (users) => UserList(users: users),
  orElse: () => const Center(child: CircularProgressIndicator()),
);

// Another example: extract data or show placeholder
final String title = asyncProfile.maybeWhen(
  data: (profile) => profile.name,
  orElse: () => 'Loading...',
);`}
      />

      <h3 id="async-value-map" className="text-xl font-semibold mt-8 mb-3">Transforming Data with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.map()</code></h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.map()</code> method transforms the data inside an <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncData</code> without affecting loading or error states. It returns a new <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue</code> with the transformed type.
      </p>
      <CodeBlock
        title="Mapping over async data"
        code={`// Transform AsyncValue<List<User>> into AsyncValue<int>
final AsyncValue<int> userCount = asyncUsers.map(
  (List<User> users) => users.length,
);

// Chain multiple maps
final AsyncValue<String> displayText = asyncUsers
    .map((users) => users.where((u) => u.isActive).toList())
    .map((activeUsers) => '\${activeUsers.length} active users');

// Loading and error states pass through unchanged:
// AsyncLoading<List<User>> -> AsyncLoading<int>
// AsyncError<List<User>>   -> AsyncError<int>
// AsyncData<List<User>>    -> AsyncData<int> (transformed)`}
      />

      <h3 id="stale-while-revalidate" className="text-xl font-semibold mt-8 mb-3">Stale-While-Revalidate Pattern</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When an async atom refreshes, instead of showing a blank loading indicator, Reacton preserves the previous successful data inside the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncLoading</code> state via its <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">previousData</code> property. This lets you continue displaying stale data while the fresh data loads in the background.
      </p>
      <CodeBlock
        title="Showing stale data during refresh"
        code={`ReactonBuilder<AsyncValue<List<User>>>(
  atom: usersAtom,
  builder: (context, state) {
    return state.when(
      loading: () {
        // On first load, state.previousData is null
        // On refresh, state.previousData holds the old users
        if (state is AsyncLoading<List<User>> &&
            state.previousData != null) {
          return Stack(
            children: [
              // Show the stale user list
              UserList(users: state.previousData!),
              // Overlay a subtle refresh indicator
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
      data: (users) => UserList(users: users),
      error: (e, _) => ErrorView(message: '\$e'),
    );
  },
)`}
      />
      <Callout type="tip" title="Best Practice">
        The stale-while-revalidate pattern provides a much smoother user experience. Instead of content disappearing on refresh, users see the previous data with a subtle loading indicator. Always check for <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">previousData</code> in your loading state handler.
      </Callout>

      <h3 id="async-value-helpers" className="text-xl font-semibold mt-8 mb-3">Convenience Helpers</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue</code> provides several boolean and nullable getters for quick checks without full pattern matching:
      </p>
      <CodeBlock
        title="AsyncValue convenience helpers"
        code={`final asyncVal = store.read(usersAtom);

// Boolean checks
asyncVal.isLoading;  // true if AsyncLoading
asyncVal.hasData;    // true if AsyncData
asyncVal.hasError;   // true if AsyncError

// Nullable accessors — return null if not in the matching state
asyncVal.data;       // T? — the value if AsyncData, else null
asyncVal.error;      // Object? — the error if AsyncError, else null
asyncVal.stackTrace; // StackTrace? — stack trace if AsyncError, else null

// Practical example: conditional refresh button
if (!asyncVal.isLoading) {
  store.refresh(usersAtom);
}

// Practical example: showing data count in app bar
final int count = asyncVal.data?.length ?? 0;
Text('\$count users');`}
      />

      {/* ================================================================== */}
      {/* Async Atoms */}
      {/* ================================================================== */}
      <h2 id="async-atoms" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Async Atoms
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Async atoms are the core primitive for reactive asynchronous data in Reacton. Created with the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">asyncAtom</code> factory, they integrate seamlessly with the reactive dependency graph. Their value is always an <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue&lt;T&gt;</code>, which transitions through states automatically as the async computation runs.
      </p>

      <h3 id="creating-async-atoms" className="text-xl font-semibold mt-8 mb-3">Creating Async Atoms</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">asyncAtom</code> factory takes a callback that receives a <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read</code> function for accessing other atoms. The callback must return a <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Future&lt;T&gt;</code>. Any atoms accessed via <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code> inside the callback are automatically tracked as dependencies.
      </p>
      <CodeBlock
        title="Basic async atom"
        code={`final usersAtom = asyncAtom<List<User>>(
  (read) async {
    final response = await http.get(
      Uri.parse('https://api.example.com/users'),
    );
    if (response.statusCode != 200) {
      throw HttpException('Failed to load users: \${response.statusCode}');
    }
    final List<dynamic> json = jsonDecode(response.body);
    return json.map((j) => User.fromJson(j)).toList();
  },
  name: 'users',
);`}
      />

      <h3 id="reactive-dependencies" className="text-xl font-semibold mt-8 mb-3">Automatic Dependency Tracking</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you call <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read(someAtom)</code> inside an async atom's computation, Reacton automatically records <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">someAtom</code> as a dependency. Whenever any dependency changes, the async atom automatically re-executes its computation. This is the same reactive graph that synchronous derived atoms use, extended to async.
      </p>
      <CodeBlock
        title="Dependency tracking in async atoms"
        code={`// When selectedCategoryAtom changes, filteredProductsAtom
// automatically re-fetches with the new category.
final selectedCategoryAtom = atom<String>('all', name: 'selectedCategory');

final filteredProductsAtom = asyncAtom<List<Product>>(
  (read) async {
    // This call registers selectedCategoryAtom as a dependency
    final category = read(selectedCategoryAtom);

    final response = await http.get(
      Uri.parse('https://api.example.com/products?category=\$category'),
    );
    return Product.fromJsonList(jsonDecode(response.body));
  },
  name: 'filteredProducts',
);

// Changing the dependency triggers a re-fetch:
store.set(selectedCategoryAtom, 'electronics');
// filteredProductsAtom transitions: AsyncData -> AsyncLoading(previousData) -> AsyncData`}
      />

      <h3 id="auto-cancel" className="text-xl font-semibold mt-8 mb-3">Auto-Cancel on Dependency Change</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When a dependency changes while an async atom is still loading, Reacton automatically cancels the in-flight request before starting the new one. This prevents race conditions where an earlier slow request might overwrite newer data.
      </p>
      <CodeBlock
        title="Auto-cancellation prevents race conditions"
        code={`final searchQueryAtom = atom<String>('', name: 'searchQuery');

final searchResultsAtom = asyncAtom<List<SearchResult>>(
  (read) async {
    final query = read(searchQueryAtom);
    if (query.isEmpty) return [];

    // If the user types again before this completes,
    // Reacton cancels this request and starts a new one
    // with the updated query. No stale results.
    final response = await http.get(
      Uri.parse('https://api.example.com/search?q=\$query'),
    );
    return SearchResult.fromJsonList(jsonDecode(response.body));
  },
  name: 'searchResults',
);

// Rapid updates: only the last request's result will be used.
store.set(searchQueryAtom, 'flu');     // request 1 starts
store.set(searchQueryAtom, 'flutt');   // request 1 cancelled, request 2 starts
store.set(searchQueryAtom, 'flutter'); // request 2 cancelled, request 3 starts`}
      />
      <Callout type="info" title="Cancellation Behavior">
        Auto-cancel only applies to in-flight async computations triggered by dependency changes. If you manually call <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.refresh()</code>, the current request is cancelled first, then the new one begins. Cancelled requests never produce data or error states.
      </Callout>

      <h3 id="async-state-machine" className="text-xl font-semibold mt-8 mb-3">State Machine Lifecycle</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        An async atom follows a well-defined state machine. Understanding this lifecycle is key to building robust async UIs:
      </p>
      <CodeBlock
        title="Async atom state transitions"
        language="text"
        code={`Initial State:
  AsyncLoading(previousData: null)
       │
       ▼
  ┌─────────────────────┐
  │  Computation runs    │
  └─────────┬───────────┘
            │
     ┌──────┴──────┐
     ▼             ▼
AsyncData(T)   AsyncError(e, st)
     │             │
     └──────┬──────┘
            │  refresh() or dependency change
            ▼
AsyncLoading(previousData: lastValue)
            │
     ┌──────┴──────┐
     ▼             ▼
AsyncData(T)   AsyncError(e, st)
     │             │
     └──────┬──────┘
            │  (cycle continues...)
            ▼`}
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        On first creation, the atom starts in <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncLoading</code> with no previous data. Once the computation completes, it moves to <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncData</code> or <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncError</code>. On subsequent refreshes or dependency changes, it transitions back to <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncLoading</code> but now with the last successful value as <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">previousData</code>.
      </p>

      <h3 id="refresh-mechanism" className="text-xl font-semibold mt-8 mb-3">Refresh Mechanism</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can force an async atom to re-execute its computation by calling <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.refresh(atom)</code>. This is useful for pull-to-refresh gestures, retry buttons, and periodic background refresh.
      </p>
      <CodeBlock
        title="Manual refresh"
        code={`// Pull-to-refresh example
RefreshIndicator(
  onRefresh: () async {
    await store.refresh(usersAtom);
  },
  child: ReactonBuilder<AsyncValue<List<User>>>(
    atom: usersAtom,
    builder: (context, state) {
      return state.when(
        loading: () {
          if (state is AsyncLoading<List<User>> &&
              state.previousData != null) {
            return UserList(users: state.previousData!);
          }
          return const Center(child: CircularProgressIndicator());
        },
        data: (users) => UserList(users: users),
        error: (e, _) => Center(child: Text('Error: \$e')),
      );
    },
  ),
)`}
      />

      <h3 id="async-widget-integration" className="text-xl font-semibold mt-8 mb-3">Using Async Atoms with Widgets</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Async atoms work with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> exactly like synchronous atoms. The builder receives the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue&lt;T&gt;</code> and rebuilds automatically when the state transitions.
      </p>
      <CodeBlock
        title="Full widget example with async atoms"
        code={`class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          // Refresh button - only enabled when not loading
          ReactonBuilder<AsyncValue<List<User>>>(
            atom: usersAtom,
            builder: (context, state) {
              return IconButton(
                onPressed: state.isLoading
                    ? null
                    : () => store.refresh(usersAtom),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: ReactonBuilder<AsyncValue<List<User>>>(
        atom: usersAtom,
        builder: (context, state) {
          return state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(child: Text(users[index].initials)),
                  title: Text(users[index].name),
                  subtitle: Text(users[index].email),
                ),
              );
            },
            error: (e, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('\$e', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => store.refresh(usersAtom),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}`}
      />

      <h3 id="async-error-handling" className="text-xl font-semibold mt-8 mb-3">Error Handling Patterns</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Errors thrown inside an async atom's computation are caught automatically and produce an <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncError</code> state. You can throw specific exception types to provide more meaningful error messages in your UI.
      </p>
      <CodeBlock
        title="Structured error handling"
        code={`// Define typed exceptions
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException(\$statusCode): \$message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

// Use typed exceptions in async atoms
final profileAtom = asyncAtom<UserProfile>(
  (read) async {
    try {
      final token = read(authTokenAtom);
      final response = await http.get(
        Uri.parse('https://api.example.com/profile'),
        headers: {'Authorization': 'Bearer \$token'},
      );

      if (response.statusCode == 401) {
        throw const ApiException(401, 'Session expired. Please log in again.');
      }
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, 'Server error');
      }

      return UserProfile.fromJson(jsonDecode(response.body));
    } on SocketException {
      throw const NetworkException('No internet connection');
    }
  },
  name: 'profile',
);

// Handle typed errors in the UI
state.when(
  loading: () => const ShimmerProfile(),
  data: (profile) => ProfileCard(profile: profile),
  error: (e, _) {
    if (e is NetworkException) {
      return const OfflineView();
    }
    if (e is ApiException && e.statusCode == 401) {
      return const LoginPrompt();
    }
    return GenericErrorView(message: '\$e');
  },
);`}
      />

      <h3 id="chained-async" className="text-xl font-semibold mt-8 mb-3">Chained Async Atoms</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Async atoms can depend on other async atoms. When you read an async atom inside another async atom's computation, Reacton waits for the dependency to resolve before running the dependent computation.
      </p>
      <CodeBlock
        title="Chaining async atoms"
        code={`// First: fetch the current user
final currentUserAtom = asyncAtom<User>(
  (read) async {
    final token = read(authTokenAtom);
    final response = await http.get(
      Uri.parse('https://api.example.com/me'),
      headers: {'Authorization': 'Bearer \$token'},
    );
    return User.fromJson(jsonDecode(response.body));
  },
  name: 'currentUser',
);

// Second: fetch the user's orders (depends on currentUserAtom)
final userOrdersAtom = asyncAtom<List<Order>>(
  (read) async {
    // This waits for currentUserAtom to resolve first
    final user = await read(currentUserAtom).dataFuture;
    final response = await http.get(
      Uri.parse('https://api.example.com/users/\${user.id}/orders'),
    );
    return Order.fromJsonList(jsonDecode(response.body));
  },
  name: 'userOrders',
);

// Third: compute order statistics (depends on userOrdersAtom)
final orderStatsAtom = asyncAtom<OrderStats>(
  (read) async {
    final orders = await read(userOrdersAtom).dataFuture;
    return OrderStats(
      totalOrders: orders.length,
      totalSpent: orders.fold(0.0, (sum, o) => sum + o.total),
      averageOrder: orders.isEmpty
          ? 0.0
          : orders.fold(0.0, (sum, o) => sum + o.total) / orders.length,
    );
  },
  name: 'orderStats',
);`}
      />
      <Callout type="warning" title="Dependency Chains">
        Deep chains of async atoms can increase latency since each level must wait for the previous one to resolve. Consider batching related API calls into a single async atom when possible, or use parallel fetching within one atom for independent data sources.
      </Callout>

      {/* ================================================================== */}
      {/* Retry Policy */}
      {/* ================================================================== */}
      <h2 id="retry-policy" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Retry Policy
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Network requests can fail transiently. Reacton provides a built-in <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">RetryPolicy</code> class that automatically retries failed async computations with configurable exponential backoff. Retries only trigger on errors -- cancelled requests (from dependency changes) are never retried.
      </p>

      <h3 id="retry-configuration" className="text-xl font-semibold mt-8 mb-3">Configuration Options</h3>
      <CodeBlock
        title="RetryPolicy class"
        code={`class RetryPolicy {
  /// Maximum number of retry attempts (not counting the initial attempt).
  final int maxAttempts;

  /// Base delay between retries.
  final Duration delay;

  /// Multiplier applied to the delay after each retry.
  /// delay * backoffMultiplier^attemptNumber
  final double backoffMultiplier;

  /// Optional predicate: return true to retry, false to give up.
  /// If null, all errors are retried.
  final bool Function(Object error, int attempt)? retryWhen;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.retryWhen,
  });
}`}
      />

      <h3 id="exponential-backoff" className="text-xl font-semibold mt-8 mb-3">Exponential Backoff Explained</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        With a base delay of 1 second and a backoff multiplier of 2.0, the retry delays progress as follows:
      </p>
      <div className="overflow-x-auto my-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Attempt</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Delay Calculation</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Wait Time</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4">Initial</td>
              <td className="py-3 px-4">--</td>
              <td className="py-3 px-4">Immediate</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4">Retry 1</td>
              <td className="py-3 px-4">1s * 2.0^0</td>
              <td className="py-3 px-4">1 second</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4">Retry 2</td>
              <td className="py-3 px-4">1s * 2.0^1</td>
              <td className="py-3 px-4">2 seconds</td>
            </tr>
            <tr>
              <td className="py-3 px-4">Retry 3</td>
              <td className="py-3 px-4">1s * 2.0^2</td>
              <td className="py-3 px-4">4 seconds</td>
            </tr>
          </tbody>
        </table>
      </div>

      <CodeBlock
        title="Basic retry policy"
        code={`final dataAtom = asyncAtom<Data>(
  (read) async {
    final response = await http.get(Uri.parse('https://api.example.com/data'));
    if (response.statusCode != 200) {
      throw HttpException('Status \${response.statusCode}');
    }
    return Data.fromJson(jsonDecode(response.body));
  },
  name: 'data',
  retry: const RetryPolicy(
    maxAttempts: 3,
    delay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
  ),
);`}
      />

      <h3 id="conditional-retry" className="text-xl font-semibold mt-8 mb-3">Conditional Retries with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">retryWhen</code></h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Not all errors are worth retrying. A 404 will not succeed on the next attempt, but a 503 might. Use the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">retryWhen</code> predicate to control which errors trigger retries.
      </p>
      <CodeBlock
        title="Selective retries based on error type"
        code={`final apiDataAtom = asyncAtom<ApiResponse>(
  (read) async {
    final response = await http.get(Uri.parse('https://api.example.com/data'));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return ApiResponse.fromJson(jsonDecode(response.body));
  },
  name: 'apiData',
  retry: RetryPolicy(
    maxAttempts: 5,
    delay: const Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    retryWhen: (error, attempt) {
      if (error is ApiException) {
        // Retry server errors (5xx) and rate limits (429)
        return error.statusCode >= 500 || error.statusCode == 429;
      }
      if (error is SocketException || error is TimeoutException) {
        // Retry network errors
        return true;
      }
      // Don't retry client errors (4xx), parse errors, etc.
      return false;
    },
  ),
);`}
      />
      <Callout type="info" title="Retry vs Cancel">
        Retries only fire on errors. If an async atom is cancelled (because a dependency changed or a new refresh was triggered), the retry counter resets and no retry is attempted for the cancelled computation. The new computation starts fresh.
      </Callout>

      {/* ================================================================== */}
      {/* Debounce & Throttle */}
      {/* ================================================================== */}
      <h2 id="debounce-throttle" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Debounce & Throttle
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Rapid state changes -- like a user typing in a search box or scrolling quickly -- can trigger an excessive number of computations and network requests. Reacton provides debounce and throttle mechanisms to control the rate at which atoms process updates.
      </p>

      <h3 id="debounce" className="text-xl font-semibold mt-8 mb-3">Debounced Atoms</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">DebouncedAtom</code> delays processing updates until a quiet period has elapsed. Each new update resets the timer. Only when the user stops changing the value for the specified duration does the atom emit its new value. This is ideal for search inputs where you want to wait until the user stops typing.
      </p>
      <CodeBlock
        title="Search input with debounce"
        code={`// Raw input atom — updates instantly on every keystroke
final searchInputAtom = atom<String>('', name: 'searchInput');

// Debounced atom — only emits after 300ms of no changes
final debouncedSearchAtom = debouncedAtom<String>(
  source: searchInputAtom,
  duration: const Duration(milliseconds: 300),
  name: 'debouncedSearch',
);

// Async atom depends on the debounced value, not the raw input
final searchResultsAtom = asyncAtom<List<SearchResult>>(
  (read) async {
    final query = read(debouncedSearchAtom);
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse('https://api.example.com/search?q=\${Uri.encodeComponent(query)}'),
    );
    return SearchResult.fromJsonList(jsonDecode(response.body));
  },
  name: 'searchResults',
);

// Widget: TextField updates the raw atom on every keystroke
TextField(
  onChanged: (value) => store.set(searchInputAtom, value),
  decoration: const InputDecoration(
    hintText: 'Search...',
    prefixIcon: Icon(Icons.search),
  ),
)`}
      />
      <Callout type="tip" title="Choosing Debounce Duration">
        For search inputs, 200-400ms is typically a good debounce duration. Too short and you still fire too many requests; too long and the UI feels sluggish. For auto-save features, a longer debounce of 1-2 seconds is common.
      </Callout>

      <h3 id="throttle" className="text-xl font-semibold mt-8 mb-3">Throttle Patterns</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        While debounce waits for a quiet period, throttle ensures updates happen at most once per interval. This is useful for scroll position tracking, window resizing, or analytics events where you want regular updates but not on every single pixel/frame.
      </p>
      <CodeBlock
        title="Scroll position throttle"
        code={`// Raw scroll position — updates on every pixel
final scrollPositionAtom = atom<double>(0.0, name: 'scrollPosition');

// Throttled — emits at most once every 100ms
final throttledScrollAtom = throttledAtom<double>(
  source: scrollPositionAtom,
  duration: const Duration(milliseconds: 100),
  name: 'throttledScroll',
);

// Derived: determine if the user has scrolled past a threshold
final showBackToTopAtom = derived<bool>(
  (read) => read(throttledScrollAtom) > 500.0,
  name: 'showBackToTop',
);

// In a CustomScrollView or NotificationListener:
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    store.set(scrollPositionAtom, notification.metrics.pixels);
    return false;
  },
  child: ListView.builder(
    itemCount: 1000,
    itemBuilder: (context, index) => ListTile(title: Text('Item \$index')),
  ),
)`}
      />

      <CodeBlock
        title="Analytics event throttle"
        code={`// Throttle analytics to avoid overwhelming the backend
final analyticsEventAtom = atom<AnalyticsEvent?>(null, name: 'analyticsEvent');

final throttledAnalyticsAtom = throttledAtom<AnalyticsEvent?>(
  source: analyticsEventAtom,
  duration: const Duration(seconds: 2),
  name: 'throttledAnalytics',
  trailing: true, // Emit the most recent value at end of interval
);

// An effect that sends throttled events to the server
store.effect(
  (read) {
    final event = read(throttledAnalyticsAtom);
    if (event != null) {
      analyticsService.track(event);
    }
  },
);`}
      />

      {/* ================================================================== */}
      {/* Optimistic Updates */}
      {/* ================================================================== */}
      <h2 id="optimistic-updates" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Optimistic Updates
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Optimistic updates immediately reflect a change in the UI before the server confirms it. If the server request succeeds, the optimistic value stays. If it fails, Reacton rolls back to the previous value. This makes your app feel instantaneous to users, especially for actions like creating items, toggling favorites, or sending messages.
      </p>

      <h3 id="optimistic-api" className="text-xl font-semibold mt-8 mb-3">The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.optimistic()</code> API</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.optimistic()</code> method orchestrates the optimistic update flow:
      </p>
      <CodeBlock
        title="store.optimistic() signature"
        code={`Future<T> store.optimistic<T>({
  /// The atom to update optimistically.
  required AtomBase<T> atom,

  /// The value to set immediately (before the server responds).
  required T optimisticValue,

  /// The async action to perform (e.g., API call).
  /// If it succeeds, the optimistic value remains.
  /// If it throws, the atom rolls back to [rollbackValue].
  required Future<T> Function() action,

  /// The value to restore if [action] fails.
  /// Typically the current value before the optimistic update.
  required T rollbackValue,
});`}
      />

      <h3 id="optimistic-flow" className="text-xl font-semibold mt-8 mb-3">Success and Failure Flows</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here is the complete flow for an optimistic update:
      </p>
      <CodeBlock
        title="Optimistic update flow"
        language="text"
        code={`Success flow:
  1. store.optimistic() called
  2. Atom immediately set to optimisticValue → UI updates instantly
  3. action() runs asynchronously (API call)
  4. action() succeeds → atom retains optimisticValue (or updates with server response)
  5. Done — user saw instant feedback, server confirmed

Failure flow:
  1. store.optimistic() called
  2. Atom immediately set to optimisticValue → UI updates instantly
  3. action() runs asynchronously (API call)
  4. action() throws an error
  5. Atom rolled back to rollbackValue → UI reverts
  6. Error propagated — show error notification to user`}
      />

      <h3 id="optimistic-todo-example" className="text-xl font-semibold mt-8 mb-3">Example: Creating a Todo</h3>
      <CodeBlock
        title="Optimistic todo creation with full error handling"
        code={`final todosAtom = atom<List<Todo>>([], name: 'todos');

Future<void> createTodo(Todo newTodo) async {
  final currentTodos = store.read(todosAtom);

  try {
    await store.optimistic(
      atom: todosAtom,
      // Immediately show the new todo in the list
      optimisticValue: [...currentTodos, newTodo.copyWith(isPending: true)],
      // The actual API call
      action: () async {
        final created = await api.createTodo(newTodo);
        // Return the list with the server-confirmed todo
        // (which now has a real ID assigned by the server)
        return [...currentTodos, created];
      },
      // Restore original list if the API call fails
      rollbackValue: currentTodos,
    );
  } catch (e) {
    // Rollback has already happened at this point.
    // Show error feedback to the user.
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Failed to create todo: \$e'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => createTodo(newTodo),
        ),
      ),
    );
  }
}`}
      />

      <h3 id="optimistic-like-example" className="text-xl font-semibold mt-8 mb-3">Example: Like / Unlike Toggle</h3>
      <CodeBlock
        title="Optimistic like toggle"
        code={`final likedPostsAtom = atom<Set<String>>({}, name: 'likedPosts');

Future<void> toggleLike(String postId) async {
  final currentLiked = store.read(likedPostsAtom);
  final isCurrentlyLiked = currentLiked.contains(postId);

  // Compute the optimistic next state
  final optimistic = isCurrentlyLiked
      ? ({...currentLiked}..remove(postId))
      : ({...currentLiked, postId});

  try {
    await store.optimistic(
      atom: likedPostsAtom,
      optimisticValue: optimistic,
      action: () async {
        if (isCurrentlyLiked) {
          await api.unlikePost(postId);
        } else {
          await api.likePost(postId);
        }
        return optimistic; // Server confirmed — keep the optimistic state
      },
      rollbackValue: currentLiked,
    );
  } catch (e) {
    // The like was rolled back automatically.
    // The heart icon has already reverted in the UI.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update like: \$e')),
    );
  }
}`}
      />

      <h3 id="optimistic-message-example" className="text-xl font-semibold mt-8 mb-3">Example: Sending a Message</h3>
      <CodeBlock
        title="Optimistic message sending"
        code={`final messagesAtom = atom<List<Message>>([], name: 'messages');

Future<void> sendMessage(String text) async {
  final currentMessages = store.read(messagesAtom);

  // Create an optimistic message with a temporary local ID
  final optimisticMsg = Message(
    id: 'temp_\${DateTime.now().millisecondsSinceEpoch}',
    text: text,
    sender: currentUser,
    timestamp: DateTime.now(),
    status: MessageStatus.sending,
  );

  try {
    await store.optimistic(
      atom: messagesAtom,
      optimisticValue: [...currentMessages, optimisticMsg],
      action: () async {
        final sentMessage = await api.sendMessage(text);
        // Replace the optimistic message with the server-confirmed one
        return [
          ...currentMessages,
          sentMessage.copyWith(status: MessageStatus.sent),
        ];
      },
      rollbackValue: currentMessages,
    );
  } catch (e) {
    // Optionally: instead of fully rolling back, mark the message as failed
    final failedMessages = store.read(messagesAtom).map((m) {
      if (m.id == optimisticMsg.id) {
        return m.copyWith(status: MessageStatus.failed);
      }
      return m;
    }).toList();
    store.set(messagesAtom, failedMessages);
  }
}`}
      />
      <Callout type="warning" title="Race Conditions">
        If the user performs multiple optimistic updates in quick succession, ensure that your <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">rollbackValue</code> is captured <em>before</em> the optimistic write, as shown in the examples above. Reading the atom <em>after</em> setting the optimistic value would capture the wrong rollback state.
      </Callout>

      {/* ================================================================== */}
      {/* Middleware System */}
      {/* ================================================================== */}
      <h2 id="middleware" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Middleware System
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Middleware lets you intercept and react to the lifecycle of atoms: initialization, state reads, state writes, disposal, and errors. Think of middleware as a pipeline through which every state change flows. Each middleware in the pipeline can inspect, transform, or side-effect before and after the change is applied.
      </p>

      <h3 id="middleware-base-class" className="text-xl font-semibold mt-8 mb-3">The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Middleware&lt;T&gt;</code> Base Class</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        All middleware extends the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Middleware&lt;T&gt;</code> base class and overrides any lifecycle methods they need. All methods have default no-op implementations so you only override what you need.
      </p>
      <CodeBlock
        title="Middleware base class"
        code={`abstract class Middleware<T> {
  /// Called when the atom is first initialized in the store.
  /// Use this for setup, logging, or loading persisted values.
  void onInit(AtomBase<T> atom) {}

  /// Called before a new value is written to the atom.
  /// [currentValue] is the existing value, [newValue] is the incoming value.
  /// Return the value that should actually be written.
  /// Return [currentValue] to reject the write.
  /// Return a modified value to transform the write.
  T onBeforeWrite(AtomBase<T> atom, T currentValue, T newValue) => newValue;

  /// Called after a new value has been successfully written to the atom.
  /// Use this for side effects like logging, analytics, or persistence.
  void onAfterWrite(AtomBase<T> atom, T value) {}

  /// Called when the atom is being disposed (removed from the store).
  /// Use this for cleanup: cancel subscriptions, close streams, etc.
  void onDispose(AtomBase<T> atom) {}

  /// Called when an error occurs during the atom's computation.
  /// Use this for error reporting, crash analytics, etc.
  void onError(AtomBase<T> atom, Object error, StackTrace stackTrace) {}
}`}
      />

      <h3 id="middleware-lifecycle-detail" className="text-xl font-semibold mt-8 mb-3">Lifecycle Methods in Detail</h3>

      <h4 className="text-lg font-medium mt-6 mb-2 text-gray-800 dark:text-gray-200">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onInit(atom)</code> -- Atom Initialization
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Called exactly once when the atom is first accessed or registered in the store. This is where you load persisted state, set up timers, or register with external systems.
      </p>
      <CodeBlock
        title="onInit example"
        code={`class TimestampMiddleware<T> extends Middleware<T> {
  final Map<String, DateTime> _initTimes = {};

  @override
  void onInit(AtomBase<T> atom) {
    _initTimes[atom.name] = DateTime.now();
    print('[\${atom.name}] initialized at \${DateTime.now()}');
  }
}`}
      />

      <h4 className="text-lg font-medium mt-6 mb-2 text-gray-800 dark:text-gray-200">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onBeforeWrite(atom, currentValue, newValue)</code> -- Pre-Write Hook
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Called before the atom's value is updated. The return value becomes the actual written value. This is the most powerful lifecycle method because you can validate, transform, or reject writes entirely.
      </p>
      <CodeBlock
        title="onBeforeWrite examples"
        code={`// Validation: reject invalid values
class PositiveOnlyMiddleware extends Middleware<int> {
  @override
  int onBeforeWrite(AtomBase<int> atom, int currentValue, int newValue) {
    if (newValue < 0) {
      print('[\${atom.name}] rejected negative value: \$newValue');
      return currentValue; // Reject by returning the current value
    }
    return newValue; // Allow the write
  }
}

// Transformation: clamp to a range
class ClampMiddleware extends Middleware<double> {
  final double min;
  final double max;
  ClampMiddleware({required this.min, required this.max});

  @override
  double onBeforeWrite(AtomBase<double> atom, double currentValue, double newValue) {
    return newValue.clamp(min, max);
  }
}

// Sanitization: trim whitespace from strings
class TrimMiddleware extends Middleware<String> {
  @override
  String onBeforeWrite(AtomBase<String> atom, String currentValue, String newValue) {
    return newValue.trim();
  }
}`}
      />

      <h4 className="text-lg font-medium mt-6 mb-2 text-gray-800 dark:text-gray-200">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onAfterWrite(atom, value)</code> -- Post-Write Hook
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Called after the atom's value has been updated and listeners have been notified. Use this for side effects that should only happen after a confirmed write, such as logging, persisting to disk, or sending analytics.
      </p>
      <CodeBlock
        title="onAfterWrite example"
        code={`class AnalyticsMiddleware<T> extends Middleware<T> {
  final AnalyticsService analytics;
  AnalyticsMiddleware(this.analytics);

  @override
  void onAfterWrite(AtomBase<T> atom, T value) {
    analytics.track('state_changed', {
      'atom': atom.name,
      'value': value.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}`}
      />

      <h4 className="text-lg font-medium mt-6 mb-2 text-gray-800 dark:text-gray-200">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onDispose(atom)</code> -- Atom Disposal
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Called when an atom is removed from the store (e.g., when a scoped store is disposed). Use this for cleanup: cancel timers, close streams, release resources.
      </p>
      <CodeBlock
        title="onDispose example"
        code={`class ResourceMiddleware<T> extends Middleware<T> {
  Timer? _autoRefreshTimer;

  @override
  void onInit(AtomBase<T> atom) {
    // Start a periodic refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => store.refresh(atom),
    );
  }

  @override
  void onDispose(AtomBase<T> atom) {
    // Clean up the timer when the atom is disposed
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    print('[\${atom.name}] disposed, timer cancelled');
  }
}`}
      />

      <h4 className="text-lg font-medium mt-6 mb-2 text-gray-800 dark:text-gray-200">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onError(atom, error, stackTrace)</code> -- Error Handler
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Called when an error occurs during the atom's computation (particularly useful for async atoms). Use this for centralized error reporting and crash analytics.
      </p>
      <CodeBlock
        title="onError example"
        code={`class CrashReportingMiddleware<T> extends Middleware<T> {
  final CrashReporter reporter;
  CrashReportingMiddleware(this.reporter);

  @override
  void onError(AtomBase<T> atom, Object error, StackTrace stackTrace) {
    reporter.recordError(
      error,
      stackTrace,
      reason: 'Error in atom: \${atom.name}',
      fatal: false,
    );
  }
}`}
      />

      <h3 id="creating-custom-middleware" className="text-xl font-semibold mt-8 mb-3">Creating Custom Middleware: Complete Example</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here is a complete middleware that combines multiple lifecycle hooks to create an undo/redo system:
      </p>
      <CodeBlock
        title="Complete custom middleware: UndoMiddleware"
        code={`class UndoMiddleware<T> extends Middleware<T> {
  final List<T> _undoStack = [];
  final List<T> _redoStack = [];
  final int maxHistory;

  UndoMiddleware({this.maxHistory = 50});

  @override
  void onInit(AtomBase<T> atom) {
    print('[\${atom.name}] UndoMiddleware initialized (maxHistory: \$maxHistory)');
  }

  @override
  T onBeforeWrite(AtomBase<T> atom, T currentValue, T newValue) {
    // Push the current value onto the undo stack
    _undoStack.add(currentValue);
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    // Clear redo stack on new write (standard undo/redo behavior)
    _redoStack.clear();
    return newValue;
  }

  @override
  void onAfterWrite(AtomBase<T> atom, T value) {
    print('[\${atom.name}] updated to: \$value (undo depth: \${_undoStack.length})');
  }

  @override
  void onDispose(AtomBase<T> atom) {
    _undoStack.clear();
    _redoStack.clear();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  T? undo(AtomBase<T> atom, T currentValue) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(currentValue);
    return _undoStack.removeLast();
  }

  T? redo(AtomBase<T> atom, T currentValue) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(currentValue);
    return _redoStack.removeLast();
  }
}`}
      />

      <h3 id="attaching-middleware" className="text-xl font-semibold mt-8 mb-3">Attaching Middleware</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Middleware can be attached in two ways: per-atom (only applies to a specific atom) or store-wide (applies to all atoms in the store).
      </p>
      <CodeBlock
        title="Per-atom middleware"
        code={`// Attach middleware to a specific atom via AtomOptions
final counterAtom = atom<int>(
  0,
  name: 'counter',
  options: AtomOptions(
    middleware: [
      LoggingMiddleware<int>(),
      PositiveOnlyMiddleware(),
    ],
  ),
);

final usernameAtom = atom<String>(
  '',
  name: 'username',
  options: AtomOptions(
    middleware: [
      TrimMiddleware(),
      LoggingMiddleware<String>(),
    ],
  ),
);`}
      />
      <CodeBlock
        title="Store-wide middleware"
        code={`// Attach middleware to the entire store — applies to ALL atoms
final store = ReactonStore(
  middleware: [
    LoggingMiddleware(),        // Log every state change
    DevToolsMiddleware(),       // Report to DevTools
    CrashReportingMiddleware(   // Report errors centrally
      FirebaseCrashReporter(),
    ),
  ],
);`}
      />

      <h3 id="middleware-ordering" className="text-xl font-semibold mt-8 mb-3">Middleware Ordering (Pipeline)</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Middleware executes in the order it is declared. For <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onBeforeWrite</code>, each middleware receives the output of the previous one. Store-wide middleware runs first, followed by atom-specific middleware.
      </p>
      <CodeBlock
        title="Middleware execution order"
        code={`// Store-wide: [LoggingMiddleware, ValidationMiddleware]
// Atom-specific: [ClampMiddleware]
//
// Write pipeline for an atom with all three:
//
// 1. LoggingMiddleware.onBeforeWrite(atom, current, new)
//    → logs the incoming write, returns newValue
// 2. ValidationMiddleware.onBeforeWrite(atom, current, newValue)
//    → validates, might return currentValue to reject
// 3. ClampMiddleware.onBeforeWrite(atom, current, validatedValue)
//    → clamps the value to range, returns clampedValue
// 4. Atom stores clampedValue
// 5. ClampMiddleware.onAfterWrite(atom, clampedValue)
// 6. ValidationMiddleware.onAfterWrite(atom, clampedValue)
// 7. LoggingMiddleware.onAfterWrite(atom, clampedValue)
//
// Note: onAfterWrite runs in reverse order (LIFO).`}
        language="text"
      />
      <Callout type="info" title="Pipeline Behavior">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onBeforeWrite</code> methods form a pipeline: each middleware can transform the value and the next middleware sees the transformed result. If any middleware returns the current value (rejecting the write), subsequent middleware still runs but sees no change. The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onAfterWrite</code> methods run in reverse order (last middleware first), similar to how HTTP middleware unwinds.
      </Callout>

      {/* ================================================================== */}
      {/* Built-in Middleware */}
      {/* ================================================================== */}
      <h2 id="built-in-middleware" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Built-in Middleware
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton ships with several production-ready middleware classes that cover the most common needs. You can use them directly or extend them for custom behavior.
      </p>

      <h3 id="logging-middleware" className="text-xl font-semibold mt-8 mb-3">LoggingMiddleware</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Logs every state change to the console with configurable log levels and custom formatters. Extremely useful during development.
      </p>
      <CodeBlock
        title="LoggingMiddleware configuration"
        code={`// Basic usage — logs all state changes at debug level
final store = ReactonStore(
  middleware: [
    LoggingMiddleware(),
  ],
);

// Advanced configuration
final store = ReactonStore(
  middleware: [
    LoggingMiddleware(
      // Minimum log level: verbose, debug, info, warning, error
      level: LogLevel.debug,

      // Only log specific atoms (null means log everything)
      filter: (atom) => atom.name.startsWith('auth'),

      // Custom formatter for log output
      formatter: (event) {
        return '[\${event.timestamp.toIso8601String()}] '
               '\${event.atom.name}: '
               '\${event.oldValue} → \${event.newValue}';
      },

      // Custom log sink (e.g., write to file or send to server)
      sink: (message, level) {
        if (level == LogLevel.error) {
          errorReporter.log(message);
        } else {
          developer.log(message, name: 'Reacton');
        }
      },
    ),
  ],
);

// Output example:
// [Reacton] counter: 0 → 1
// [Reacton] username: '' → 'alice'
// [Reacton] theme: ThemeMode.system → ThemeMode.dark`}
      />

      <h3 id="persistence-middleware" className="text-xl font-semibold mt-8 mb-3">PersistenceMiddleware</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Automatically saves atom values to a storage backend whenever they change, and restores them when the atom is initialized. Supports any <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">StorageAdapter</code> and any <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Serializer&lt;T&gt;</code>.
      </p>
      <CodeBlock
        title="PersistenceMiddleware setup"
        code={`final themeAtom = atom<ThemeMode>(
  ThemeMode.system,
  name: 'theme',
  options: AtomOptions(
    middleware: [
      PersistenceMiddleware<ThemeMode>(
        storage: sharedPrefsStorage,         // StorageAdapter implementation
        serializer: EnumSerializer(ThemeMode.values), // Serializer<ThemeMode>
        key: 'app_theme',                    // Storage key
        debounce: const Duration(milliseconds: 500), // Optional write debounce
      ),
    ],
  ),
);

// On init: PersistenceMiddleware reads 'app_theme' from storage
//          and sets the atom's value if found.
// On write: PersistenceMiddleware serializes the new ThemeMode
//           and writes it to storage (debounced).`}
      />

      <h3 id="devtools-middleware" className="text-xl font-semibold mt-8 mb-3">DevToolsMiddleware</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reports all state changes and the dependency graph to the Reacton DevTools browser extension for Flutter. This middleware is a no-op in release builds for zero overhead in production.
      </p>
      <CodeBlock
        title="DevToolsMiddleware setup"
        code={`final store = ReactonStore(
  middleware: [
    // Only active in debug/profile mode
    DevToolsMiddleware(
      // Optional: filter which atoms appear in DevTools
      filter: (atom) => true, // Show all atoms

      // Optional: customize the display name for atoms
      nameFormatter: (atom) => 'reacton.\${atom.name}',

      // Optional: max number of state history entries to keep
      maxHistory: 200,
    ),
  ],
);

// DevTools features:
// - Live state inspection for all atoms
// - State change timeline with diffs
// - Dependency graph visualization
// - Time-travel debugging (step through state history)
// - Manual state override for testing`}
      />

      {/* ================================================================== */}
      {/* Persistence */}
      {/* ================================================================== */}
      <h2 id="persistence" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Persistence
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton's persistence system is built on two abstractions: <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">StorageAdapter</code> (where to store) and <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Serializer&lt;T&gt;</code> (how to serialize). Together with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">PersistenceMiddleware</code>, they provide a flexible, pluggable persistence layer.
      </p>

      <h3 id="storage-adapter" className="text-xl font-semibold mt-8 mb-3">StorageAdapter Interface</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">StorageAdapter</code> abstract class defines the contract for any storage backend. Reacton does not depend on any specific storage library -- you provide the adapter.
      </p>
      <CodeBlock
        title="StorageAdapter interface"
        code={`abstract class StorageAdapter {
  /// Read a value from storage by key.
  /// Returns null if the key does not exist.
  Future<String?> read(String key);

  /// Write a value to storage by key.
  Future<void> write(String key, String value);

  /// Delete a value from storage by key.
  Future<void> delete(String key);

  /// Clear all values from storage.
  Future<void> clear();
}`}
      />

      <h3 id="memory-storage" className="text-xl font-semibold mt-8 mb-3">MemoryStorage (Testing)</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton includes <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MemoryStorage</code> out of the box, an in-memory implementation perfect for tests and prototyping. Values are lost when the app restarts.
      </p>
      <CodeBlock
        title="MemoryStorage"
        code={`class MemoryStorage implements StorageAdapter {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();
}

// Usage in tests:
final testStorage = MemoryStorage();
final middleware = PersistenceMiddleware<int>(
  storage: testStorage,
  serializer: JsonSerializer<int>(),
  key: 'counter',
);`}
      />

      <h3 id="shared-preferences-adapter" className="text-xl font-semibold mt-8 mb-3">SharedPreferences Adapter</h3>
      <CodeBlock
        title="Custom StorageAdapter for SharedPreferences"
        code={`import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStorage implements StorageAdapter {
  final SharedPreferences _prefs;

  SharedPreferencesStorage(this._prefs);

  /// Factory constructor that initializes SharedPreferences
  static Future<SharedPreferencesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStorage(prefs);
  }

  @override
  Future<String?> read(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

// Initialize once at app startup:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await SharedPreferencesStorage.create();
  // Use 'storage' for all PersistenceMiddleware instances
  runApp(MyApp(storage: storage));
}`}
      />

      <h3 id="hive-adapter" className="text-xl font-semibold mt-8 mb-3">Hive Adapter</h3>
      <CodeBlock
        title="Custom StorageAdapter for Hive"
        code={`import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage implements StorageAdapter {
  final Box<String> _box;

  HiveStorage(this._box);

  static Future<HiveStorage> create({String boxName = 'reacton_store'}) async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(boxName);
    return HiveStorage(box);
  }

  @override
  Future<String?> read(String key) async => _box.get(key);

  @override
  Future<void> write(String key, String value) async => _box.put(key, value);

  @override
  Future<void> delete(String key) async => _box.delete(key);

  @override
  Future<void> clear() async => _box.clear();
}`}
      />

      <h3 id="serializer-interface" className="text-xl font-semibold mt-8 mb-3">Serializer&lt;T&gt; Interface</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Serializers convert Dart objects to/from JSON strings for storage. Reacton provides built-in serializers for common types and a clear interface for custom ones.
      </p>
      <CodeBlock
        title="Serializer interface and built-in implementations"
        code={`/// Converts T to/from a JSON-compatible String.
abstract class Serializer<T> {
  String serialize(T value);
  T deserialize(String raw);
}

/// Built-in JSON serializer for primitive types (int, double, bool, String)
/// and types with toJson/fromJson.
class JsonSerializer<T> implements Serializer<T> {
  final T Function(dynamic json)? fromJson;
  final dynamic Function(T value)? toJson;

  const JsonSerializer({this.fromJson, this.toJson});

  @override
  String serialize(T value) {
    final json = toJson != null ? toJson!(value) : value;
    return jsonEncode(json);
  }

  @override
  T deserialize(String raw) {
    final json = jsonDecode(raw);
    return fromJson != null ? fromJson!(json) : json as T;
  }
}

// Usage for primitives — no fromJson/toJson needed:
JsonSerializer<int>()
JsonSerializer<String>()
JsonSerializer<bool>()
JsonSerializer<double>()`}
      />

      <h3 id="enum-serializer" className="text-xl font-semibold mt-8 mb-3">EnumSerializer</h3>
      <CodeBlock
        title="EnumSerializer for enum types"
        code={`/// Serializes enums by name.
class EnumSerializer<T extends Enum> implements Serializer<T> {
  final List<T> values;
  const EnumSerializer(this.values);

  @override
  String serialize(T value) => value.name;

  @override
  T deserialize(String raw) {
    return values.firstWhere(
      (v) => v.name == raw,
      orElse: () => throw FormatException('Unknown enum value: \$raw'),
    );
  }
}

// Usage:
EnumSerializer<ThemeMode>(ThemeMode.values)
EnumSerializer<Locale>(Locale.values)`}
      />

      <h3 id="custom-serializer" className="text-xl font-semibold mt-8 mb-3">Custom Serializers for Complex Types</h3>
      <CodeBlock
        title="Custom serializer for a user-defined class"
        code={`class UserPreferences {
  final ThemeMode theme;
  final String locale;
  final int fontSize;
  final bool notificationsEnabled;

  const UserPreferences({
    required this.theme,
    required this.locale,
    required this.fontSize,
    required this.notificationsEnabled,
  });

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'locale': locale,
    'fontSize': fontSize,
    'notificationsEnabled': notificationsEnabled,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: ThemeMode.values.firstWhere((t) => t.name == json['theme']),
      locale: json['locale'] as String,
      fontSize: json['fontSize'] as int,
      notificationsEnabled: json['notificationsEnabled'] as bool,
    );
  }
}

// Create a serializer using the JSON serializer with custom converters
final userPrefsSerializer = JsonSerializer<UserPreferences>(
  toJson: (prefs) => prefs.toJson(),
  fromJson: (json) => UserPreferences.fromJson(json as Map<String, dynamic>),
);`}
      />

      <h3 id="persistence-complete-example" className="text-xl font-semibold mt-8 mb-3">Complete Working Example: Persisting User Preferences</h3>
      <CodeBlock
        title="Full persistence setup"
        code={`// 1. Define your preferences model
class AppPreferences {
  final ThemeMode theme;
  final double fontSize;
  final bool showOnboarding;

  const AppPreferences({
    this.theme = ThemeMode.system,
    this.fontSize = 16.0,
    this.showOnboarding = true,
  });

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'fontSize': fontSize,
    'showOnboarding': showOnboarding,
  };

  factory AppPreferences.fromJson(Map<String, dynamic> json) => AppPreferences(
    theme: ThemeMode.values.firstWhere((t) => t.name == json['theme']),
    fontSize: (json['fontSize'] as num).toDouble(),
    showOnboarding: json['showOnboarding'] as bool,
  );
}

// 2. Create the atom with persistence middleware
late final StorageAdapter storage;

final preferencesAtom = atom<AppPreferences>(
  const AppPreferences(), // Default value (used if nothing in storage)
  name: 'preferences',
  options: AtomOptions(
    middleware: [
      PersistenceMiddleware<AppPreferences>(
        storage: storage,
        serializer: JsonSerializer<AppPreferences>(
          toJson: (p) => p.toJson(),
          fromJson: (j) => AppPreferences.fromJson(j as Map<String, dynamic>),
        ),
        key: 'user_preferences',
      ),
    ],
  ),
);

// 3. Initialize storage before runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  storage = await SharedPreferencesStorage.create();

  // Hydrate the store — loads all persisted values
  await store.hydrate();

  runApp(const MyApp());
}

// 4. Use in widgets — changes are automatically persisted
ReactonBuilder<AppPreferences>(
  atom: preferencesAtom,
  builder: (context, prefs) {
    return SwitchListTile(
      title: const Text('Dark Mode'),
      value: prefs.theme == ThemeMode.dark,
      onChanged: (isDark) {
        store.update(preferencesAtom, (current) => AppPreferences(
          theme: isDark ? ThemeMode.dark : ThemeMode.light,
          fontSize: current.fontSize,
          showOnboarding: current.showOnboarding,
        ));
      },
    );
  },
)`}
      />

      <h3 id="hydration" className="text-xl font-semibold mt-8 mb-3">Hydration: Loading Stored Values on App Start</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Hydration is the process of restoring persisted atom values when the app starts. Call <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.hydrate()</code> early in your app's lifecycle -- ideally before <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">runApp()</code>. This ensures all persisted atoms have their saved values before any widget builds.
      </p>
      <CodeBlock
        title="Hydration flow"
        code={`void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final storage = await SharedPreferencesStorage.create();

  // Create the store
  final store = ReactonStore(
    middleware: [
      LoggingMiddleware(),
    ],
  );

  // Hydrate: reads all persisted keys from storage
  // and restores atom values via their PersistenceMiddleware.
  // This is an async operation — it awaits all reads.
  await store.hydrate();

  // Now all persisted atoms have their stored values.
  // Safe to build the UI.
  runApp(
    ReactonScope(
      store: store,
      child: const MyApp(),
    ),
  );
}

// You can also show a splash screen while hydrating:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: store.hydrate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return const MaterialApp(home: HomePage());
      },
    );
  }
}`}
      />
      <Callout type="tip" title="Hydration Best Practice">
        Always hydrate before building widgets that depend on persisted atoms. If you need to show the app immediately, use a <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">FutureBuilder</code> with a splash screen while hydration completes.
      </Callout>

      {/* ================================================================== */}
      {/* Interceptors */}
      {/* ================================================================== */}
      <h2 id="interceptors" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Interceptors
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Interceptors are a lightweight alternative to middleware for simple value gating and transformation. While middleware provides the full lifecycle (init, before/after write, dispose, error), interceptors focus on two things: <strong className="text-gray-900 dark:text-white">whether</strong> an update should be applied and <strong className="text-gray-900 dark:text-white">how</strong> to transform the value before writing.
      </p>

      <h3 id="interceptor-api" className="text-xl font-semibold mt-8 mb-3">Interceptor API</h3>
      <CodeBlock
        title="Interceptor class"
        code={`class Interceptor<T> {
  /// Gate: return true to allow the update, false to reject it.
  /// Called before onWrite. If this returns false, the write is
  /// completely skipped and the atom retains its current value.
  final bool Function(T currentValue, T newValue)? shouldUpdate;

  /// Transform: modify the value before it is written.
  /// Only called if shouldUpdate returned true (or was null).
  /// Return the value you want stored.
  final T Function(T currentValue, T newValue)? onWrite;

  const Interceptor({
    this.shouldUpdate,
    this.onWrite,
  });
}`}
      />

      <h3 id="interceptor-validation" className="text-xl font-semibold mt-8 mb-3">Use Case: Validation</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">shouldUpdate</code> to reject invalid values. The atom will not change if <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">shouldUpdate</code> returns false.
      </p>
      <CodeBlock
        title="Validation interceptor examples"
        code={`// Prevent negative numbers
final positiveCounterAtom = atom<int>(
  0,
  name: 'positiveCounter',
  interceptor: Interceptor<int>(
    shouldUpdate: (current, next) => next >= 0,
  ),
);

store.set(positiveCounterAtom, 5);   // Accepted: value becomes 5
store.set(positiveCounterAtom, -3);  // Rejected: value stays 5

// Prevent empty strings
final requiredFieldAtom = atom<String>(
  '',
  name: 'requiredField',
  interceptor: Interceptor<String>(
    shouldUpdate: (current, next) => next.isNotEmpty || current.isEmpty,
    // Once set, cannot be emptied. But can be set for the first time.
  ),
);

// Prevent duplicate updates (skip if value hasn't changed)
final efficientAtom = atom<Map<String, dynamic>>(
  {},
  name: 'efficientState',
  interceptor: Interceptor<Map<String, dynamic>>(
    shouldUpdate: (current, next) {
      return !const DeepCollectionEquality().equals(current, next);
    },
  ),
);`}
      />

      <h3 id="interceptor-clamping" className="text-xl font-semibold mt-8 mb-3">Use Case: Range Clamping</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onWrite</code> to transform values before they are stored. This is useful for clamping ranges, normalizing data, or applying defaults.
      </p>
      <CodeBlock
        title="Range clamping and normalization"
        code={`// Clamp volume between 0 and 100
final volumeAtom = atom<int>(
  50,
  name: 'volume',
  interceptor: Interceptor<int>(
    onWrite: (current, next) => next.clamp(0, 100),
  ),
);

store.set(volumeAtom, 150);  // Stored as 100 (clamped)
store.set(volumeAtom, -20);  // Stored as 0 (clamped)

// Normalize email to lowercase and trim whitespace
final emailAtom = atom<String>(
  '',
  name: 'email',
  interceptor: Interceptor<String>(
    onWrite: (current, next) => next.trim().toLowerCase(),
  ),
);

store.set(emailAtom, '  Alice@Example.COM  ');
// Stored as 'alice@example.com'

// Combine shouldUpdate and onWrite
final temperatureAtom = atom<double>(
  20.0,
  name: 'temperature',
  interceptor: Interceptor<double>(
    // Only accept reasonable temperature values
    shouldUpdate: (current, next) => next >= -50.0 && next <= 60.0,
    // Round to one decimal place
    onWrite: (current, next) => (next * 10).roundToDouble() / 10,
  ),
);

store.set(temperatureAtom, 23.456); // Stored as 23.5
store.set(temperatureAtom, 100.0);  // Rejected (out of range)`}
      />

      <h3 id="interceptor-vs-middleware" className="text-xl font-semibold mt-8 mb-3">Interceptors vs Middleware</h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Both interceptors and middleware can affect writes, but they serve different purposes and have different scopes:
      </p>
      <div className="overflow-x-auto my-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Feature</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Interceptor</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Middleware</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4 font-medium">Scope</td>
              <td className="py-3 px-4">Per-atom only</td>
              <td className="py-3 px-4">Per-atom or store-wide</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4 font-medium">Gate writes</td>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">shouldUpdate</code></td>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onBeforeWrite</code> (return currentValue)</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4 font-medium">Transform values</td>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onWrite</code></td>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onBeforeWrite</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4 font-medium">Lifecycle hooks</td>
              <td className="py-3 px-4">None</td>
              <td className="py-3 px-4">onInit, onAfterWrite, onDispose, onError</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="py-3 px-4 font-medium">Composable</td>
              <td className="py-3 px-4">One per atom</td>
              <td className="py-3 px-4">Multiple per atom (pipeline)</td>
            </tr>
            <tr>
              <td className="py-3 px-4 font-medium">Best for</td>
              <td className="py-3 px-4">Simple validation, clamping, normalization</td>
              <td className="py-3 px-4">Logging, persistence, analytics, complex logic</td>
            </tr>
          </tbody>
        </table>
      </div>
      <Callout type="info" title="Execution Order">
        When both an interceptor and middleware are present on an atom, the interceptor runs <strong>first</strong>. If the interceptor's <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">shouldUpdate</code> returns false, the middleware pipeline is never invoked. If the interceptor transforms the value via <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onWrite</code>, the middleware's <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onBeforeWrite</code> receives the already-transformed value.
      </Callout>

      <PageNav
        prev={{ title: 'Flutter Widgets', path: '/flutter-widgets' }}
        next={{ title: 'Advanced Features', path: '/advanced' }}
      />
    </div>
  )
}
