import CodeBlock from '../components/CodeBlock'
import Callout from '../components/Callout'
import PageNav from '../components/PageNav'

export default function Testing() {
  return (
    <div>
      <h1 id="testing" className="text-4xl font-extrabold tracking-tight mb-4">
        Testing
      </h1>
      <p className="text-lg text-gray-500 dark:text-gray-400 mb-8">
        Comprehensive testing utilities for Reacton state management. Everything you need to unit test atoms,
        widget test reactive UIs, and integration test complex state flows with confidence.
      </p>

      {/* ------------------------------------------------------------------ */}
      {/* Setup */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="setup" className="text-2xl font-bold mt-12 mb-4">
        Setup
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton ships a dedicated testing package called{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_test</code>{' '}
        that provides an isolated test store, rich assertion helpers, mock atoms, effect trackers, and
        widget-testing extensions. Add it as a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">dev_dependency</code>{' '}
        so it is never bundled into your production build.
      </p>

      <h3 id="setup-install" className="text-xl font-semibold mt-8 mb-3">
        Installing reacton_test
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Open your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pubspec.yaml</code>{' '}
        and add the following under{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">dev_dependencies</code>:
      </p>
      <CodeBlock
        language="yaml"
        title="pubspec.yaml"
        code={`dev_dependencies:
  reacton_test: ^0.1.0
  flutter_test:
    sdk: flutter
  # Optional but recommended:
  mocktail: ^1.0.0   # for mocking external services
  fake_async: ^1.3.0 # for controlling time in tests`}
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Then run{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter pub get</code>{' '}
        (or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">dart pub get</code>{' '}
        for pure Dart projects) to fetch the package.
      </p>

      <h3 id="setup-imports" className="text-xl font-semibold mt-8 mb-3">
        Import Structure
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A single import gives you access to the full testing API. For widget tests you will also need{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter_test</code>{' '}
        and the Reacton Flutter bindings:
      </p>
      <CodeBlock
        title="Typical test imports"
        code={`// Core testing utilities (TestReactonStore, assertions, mocks, trackers)
import 'package:reacton_test/reacton_test.dart';

// For widget tests
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// Your app atoms & widgets
import 'package:my_app/atoms/counter_atoms.dart';
import 'package:my_app/widgets/counter_widget.dart';`}
      />

      <h3 id="setup-organization" className="text-xl font-semibold mt-8 mb-3">
        Test File Organization
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        We recommend mirroring your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">lib/</code>{' '}
        directory structure inside{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">test/</code>{' '}
        so that every atom file, widget file, and feature module has a corresponding test file:
      </p>
      <CodeBlock
        language="text"
        title="Recommended directory layout"
        code={`test/
├── atoms/
│   ├── counter_atoms_test.dart    # unit tests for counter atoms
│   ├── user_atoms_test.dart       # unit tests for user atoms
│   └── cart_atoms_test.dart       # unit tests for cart atoms
├── widgets/
│   ├── counter_widget_test.dart   # widget tests
│   └── user_profile_test.dart     # widget tests
├── features/
│   ├── auth_flow_test.dart        # integration tests for auth flow
│   └── checkout_flow_test.dart    # integration tests for checkout
└── helpers/
    └── test_overrides.dart        # shared overrides & utilities`}
      />
      <Callout type="tip" title="Shared overrides helper">
        If many test files use the same set of overrides (e.g., a logged-in user, a pre-populated cart), extract them
        into a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">test/helpers/test_overrides.dart</code>{' '}
        file and import it where needed.
      </Callout>

      {/* ------------------------------------------------------------------ */}
      {/* TestReactonStore */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="test-store" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        TestReactonStore
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        is a special-purpose, fully isolated store designed exclusively for tests. It lets you pre-seed atom
        values through <strong className="text-gray-900 dark:text-white">overrides</strong>, so each test starts
        from a known state without touching global singletons. Under the hood it creates a completely fresh
        dependency graph, meaning no test can leak state into another.
      </p>

      <h3 id="test-store-creating" className="text-xl font-semibold mt-8 mb-3">
        Creating a Test Store
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Instantiate a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        and pass an optional list of overrides. Each override seeds a specific atom with the value you choose:
      </p>
      <CodeBlock
        code={`final store = TestReactonStore(overrides: [
  AtomTestOverride<int>(counterAtom, 10),
  AtomTestOverride<String>(nameAtom, 'Test User'),
  AtomTestOverride<List<String>>(tagsAtom, ['flutter', 'dart']),
]);`}
      />

      <h3 id="test-store-atom-override" className="text-xl font-semibold mt-8 mb-3">
        AtomTestOverride&lt;T&gt;
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomTestOverride&lt;T&gt;(atom, value)</code>{' '}
        replaces the default initial value of a synchronous atom. The type parameter{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">T</code>{' '}
        must match the atom's value type. This is the most common override and should be your go-to when testing
        atoms that hold plain data.
      </p>
      <CodeBlock
        code={`// Override a simple counter
AtomTestOverride<int>(counterAtom, 42)

// Override a complex model
AtomTestOverride<User>(currentUserAtom, User(id: '1', name: 'Test'))

// Override a list atom
AtomTestOverride<List<Todo>>(todosAtom, [
  Todo(id: '1', title: 'Write tests', done: true),
  Todo(id: '2', title: 'Ship feature', done: false),
])`}
      />

      <h3 id="test-store-async-override" className="text-xl font-semibold mt-8 mb-3">
        AsyncTestOverride&lt;T&gt;
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncTestOverride&lt;T&gt;(atom, asyncValue)</code>{' '}
        lets you override an async atom with a specific{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue&lt;T&gt;</code>{' '}
        state. This is crucial for testing how your code behaves under loading, data, and error conditions
        without making real network requests:
      </p>
      <CodeBlock
        code={`// Override with loaded data
AsyncTestOverride<List<Post>>(postsAtom, AsyncData([
  Post(id: '1', title: 'Hello World'),
]))

// Override with loading state
AsyncTestOverride<List<Post>>(postsAtom, AsyncLoading())

// Override with error state
AsyncTestOverride<List<Post>>(postsAtom, AsyncError(
  Exception('Network unreachable'),
  StackTrace.current,
))`}
      />

      <h3 id="test-store-setup-teardown" className="text-xl font-semibold mt-8 mb-3">
        Using setUp() and tearDown()
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Every test should get a fresh store. Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">setUp()</code>{' '}
        to instantiate and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">tearDown()</code>{' '}
        to dispose. The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">late</code>{' '}
        keyword ensures the store is initialized before each test and disposed after, preventing memory leaks
        and cross-test contamination:
      </p>
      <CodeBlock
        code={`void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore(overrides: [
      AtomTestOverride<int>(counterAtom, 0),
      AtomTestOverride<String>(nameAtom, 'Guest'),
    ]);
  });

  tearDown(() => store.dispose());

  // All tests below get a fresh store with counter=0, name='Guest'
  test('...', () { /* ... */ });
}`}
      />
      <Callout type="warning" title="Always dispose your store">
        Forgetting to call{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.dispose()</code>{' '}
        in{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">tearDown</code>{' '}
        can cause lingering subscriptions, timer leaks, and flaky tests. Always clean up.
      </Callout>

      <h3 id="test-store-interaction" className="text-xl font-semibold mt-8 mb-3">
        Interacting with the Store
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        exposes the same read/write API as the production store. You can{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">get</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update</code>,
        and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">subscribe</code>{' '}
        to any atom:
      </p>
      <CodeBlock
        code={`test('store supports get, set, update, subscribe', () {
  // Read the current value
  expect(store.get(counterAtom), 0);

  // Write a new value
  store.set(counterAtom, 5);
  expect(store.get(counterAtom), 5);

  // Update based on current value
  store.update(counterAtom, (current) => current + 1);
  expect(store.get(counterAtom), 6);

  // Subscribe for future changes
  final emissions = <int>[];
  final unsub = store.subscribe(counterAtom, (value) {
    emissions.add(value);
  });

  store.set(counterAtom, 10);
  store.set(counterAtom, 20);
  expect(emissions, [10, 20]);

  unsub(); // stop listening
});`}
      />

      <h3 id="test-store-computed" className="text-xl font-semibold mt-8 mb-3">
        Testing Computed Atoms
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Computed (derived) atoms automatically recompute when their dependencies change. In a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>,
        the dependency graph works identically to production, so computed atoms will resolve correctly based
        on overridden dependency values:
      </p>
      <CodeBlock
        code={`// Atom definitions (in your app code)
final priceAtom = atom<double>(29.99);
final taxRateAtom = atom<double>(0.08);
final totalAtom = computed<double>(
  (get) => get(priceAtom) * (1 + get(taxRateAtom)),
);

// Test
test('totalAtom recomputes when dependencies change', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<double>(priceAtom, 100.0),
    AtomTestOverride<double>(taxRateAtom, 0.10),
  ]);

  // Computed atom resolves from overridden values
  expect(store.get(totalAtom), 110.0);

  // Changing a dependency triggers recomputation
  store.set(taxRateAtom, 0.20);
  expect(store.get(totalAtom), 120.0);

  store.set(priceAtom, 50.0);
  expect(store.get(totalAtom), 60.0);

  store.dispose();
});`}
      />

      <h3 id="test-store-batched" className="text-xl font-semibold mt-8 mb-3">
        Testing Batched Updates
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you update multiple atoms simultaneously, Reacton batches the notifications so dependents
        only recompute once. You can verify this behavior in tests by counting emissions:
      </p>
      <CodeBlock
        code={`test('batched updates fire a single notification', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<double>(priceAtom, 100.0),
    AtomTestOverride<double>(taxRateAtom, 0.10),
  ]);

  var recomputeCount = 0;
  store.subscribe(totalAtom, (_) => recomputeCount++);

  // Without batching: two separate updates = two notifications
  store.set(priceAtom, 200.0);
  store.set(taxRateAtom, 0.20);
  // recomputeCount would be 2

  recomputeCount = 0; // reset

  // With batching: single notification
  store.batch(() {
    store.set(priceAtom, 300.0);
    store.set(taxRateAtom, 0.15);
  });
  expect(recomputeCount, 1);
  expect(store.get(totalAtom), 345.0);

  store.dispose();
});`}
      />

      <h3 id="test-store-complete-example" className="text-xl font-semibold mt-8 mb-3">
        Complete Test Suite Example
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here is a full test file that demonstrates all of the above patterns working together:
      </p>
      <CodeBlock
        title="test/atoms/shopping_cart_test.dart"
        code={`import 'package:reacton_test/reacton_test.dart';
import 'package:my_app/atoms/cart_atoms.dart';

void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore(overrides: [
      AtomTestOverride<List<CartItem>>(cartItemsAtom, []),
      AtomTestOverride<double>(discountAtom, 0.0),
    ]);
  });

  tearDown(() => store.dispose());

  group('cartItemsAtom', () {
    test('starts empty with override', () {
      expect(store.get(cartItemsAtom), isEmpty);
    });

    test('can add items', () {
      final item = CartItem(id: '1', name: 'Widget', price: 9.99);
      store.update(cartItemsAtom, (items) => [...items, item]);
      expect(store.get(cartItemsAtom), hasLength(1));
      expect(store.get(cartItemsAtom).first.name, 'Widget');
    });

    test('can remove items', () {
      final item = CartItem(id: '1', name: 'Widget', price: 9.99);
      store.set(cartItemsAtom, [item]);
      store.update(cartItemsAtom,
        (items) => items.where((i) => i.id != '1').toList(),
      );
      expect(store.get(cartItemsAtom), isEmpty);
    });
  });

  group('cartTotalAtom (computed)', () {
    test('computes subtotal from items', () {
      store.set(cartItemsAtom, [
        CartItem(id: '1', name: 'A', price: 10.0),
        CartItem(id: '2', name: 'B', price: 20.0),
      ]);
      expect(store.get(cartSubtotalAtom), 30.0);
    });

    test('applies discount to subtotal', () {
      store.set(cartItemsAtom, [
        CartItem(id: '1', name: 'A', price: 100.0),
      ]);
      store.set(discountAtom, 0.25); // 25% off
      expect(store.get(cartTotalAtom), 75.0);
    });

    test('batched item + discount update notifies once', () {
      var notifications = 0;
      store.subscribe(cartTotalAtom, (_) => notifications++);

      store.batch(() {
        store.set(cartItemsAtom, [
          CartItem(id: '1', name: 'A', price: 50.0),
        ]);
        store.set(discountAtom, 0.10);
      });

      expect(notifications, 1);
      expect(store.get(cartTotalAtom), 45.0);
    });
  });
}`}
      />

      {/* ------------------------------------------------------------------ */}
      {/* Assertion Helpers */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="assertions" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Assertion Helpers
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_test</code>{' '}
        extends{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        with a rich set of assertion methods that produce clear, human-readable failure messages.
        These helpers let you verify current values, match patterns, collect emissions over time,
        and wait for async state changes.
      </p>

      <h3 id="assert-expect-atom" className="text-xl font-semibold mt-8 mb-3">
        store.expectAtom(atom, expectedValue)
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Asserts that the current value of an atom equals the expected value. Uses deep equality, so it
        works with lists, maps, and custom objects that implement{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code>{' '}
        and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">hashCode</code>:
      </p>
      <CodeBlock
        code={`test('expectAtom checks current value', () {
  store.set(counterAtom, 42);
  store.expectAtom(counterAtom, 42); // passes

  store.set(nameAtom, 'Alice');
  store.expectAtom(nameAtom, 'Alice'); // passes

  // Also works with collections
  store.set(tagsAtom, ['a', 'b', 'c']);
  store.expectAtom(tagsAtom, ['a', 'b', 'c']); // passes (deep equality)
});`}
      />

      <h3 id="assert-expect-matches" className="text-xl font-semibold mt-8 mb-3">
        store.expectAtomMatches(atom, matcher)
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Uses a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Matcher</code>{' '}
        from the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">test</code>{' '}
        package for flexible assertions. This is useful when you want to check a range, a type, a predicate,
        or any condition more nuanced than strict equality:
      </p>
      <CodeBlock
        code={`test('expectAtomMatches uses matchers', () {
  store.set(counterAtom, 15);

  // Range check
  store.expectAtomMatches(counterAtom, greaterThan(10));
  store.expectAtomMatches(counterAtom, lessThan(20));
  store.expectAtomMatches(counterAtom, inInclusiveRange(10, 20));

  // Type check
  store.expectAtomMatches(counterAtom, isA<int>());

  // Predicate
  store.expectAtomMatches(counterAtom, predicate<int>((v) => v.isOdd));

  // Collection matchers
  store.set(tagsAtom, ['flutter', 'dart', 'reacton']);
  store.expectAtomMatches(tagsAtom, contains('reacton'));
  store.expectAtomMatches(tagsAtom, hasLength(3));
});`}
      />

      <h3 id="assert-collect-values" className="text-xl font-semibold mt-8 mb-3">
        store.collectValues(atom, count: n)
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Starts listening to an atom and collects the next{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">n</code>{' '}
        emitted values into a list. The subscription is automatically cleaned up after{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">n</code>{' '}
        emissions. This is ideal for verifying a specific sequence of state changes:
      </p>
      <CodeBlock
        code={`test('collectValues captures emissions in order', () {
  final values = store.collectValues(counterAtom, count: 4);

  store.set(counterAtom, 1);
  store.set(counterAtom, 2);
  store.set(counterAtom, 3);
  store.set(counterAtom, 4);

  expect(values, [1, 2, 3, 4]);
});

test('collectValues works with update()', () {
  store.set(counterAtom, 0);
  final values = store.collectValues(counterAtom, count: 3);

  store.update(counterAtom, (v) => v + 10);
  store.update(counterAtom, (v) => v + 10);
  store.update(counterAtom, (v) => v + 10);

  expect(values, [10, 20, 30]);
});`}
      />

      <h3 id="assert-expect-emissions" className="text-xl font-semibold mt-8 mb-3">
        store.expectEmissions(atom, [values])
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A convenience method that combines{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">collectValues</code>{' '}
        with an assertion. It collects exactly{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">values.length</code>{' '}
        emissions and asserts they match the expected list. The test will fail with a clear diff if any
        emission does not match:
      </p>
      <CodeBlock
        code={`test('expectEmissions validates full sequence', () {
  // Set up the expectation BEFORE triggering changes
  final expectation = store.expectEmissions(counterAtom, [1, 2, 3]);

  store.set(counterAtom, 1);
  store.set(counterAtom, 2);
  store.set(counterAtom, 3);

  // Verify - throws if sequence doesn't match
  expectation.verify();
});`}
      />

      <h3 id="assert-emission-count" className="text-xl font-semibold mt-8 mb-3">
        store.expectEmissionCount(atom, count)
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Asserts that an atom has emitted exactly{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">count</code>{' '}
        times since tracking began. This is useful for verifying that computed atoms recompute the expected
        number of times, or that deduplication logic correctly filters out duplicate values:
      </p>
      <CodeBlock
        code={`test('expectEmissionCount tracks total emissions', () {
  // Start tracking
  store.startTracking(counterAtom);

  store.set(counterAtom, 1);
  store.set(counterAtom, 2);
  store.set(counterAtom, 3);

  store.expectEmissionCount(counterAtom, 3);
});

test('deduplication prevents duplicate emissions', () {
  store.startTracking(counterAtom);

  store.set(counterAtom, 5);
  store.set(counterAtom, 5); // same value — deduplicated
  store.set(counterAtom, 5); // same value — deduplicated

  store.expectEmissionCount(counterAtom, 1); // only 1 actual emission
});`}
      />

      <h3 id="assert-wait-for" className="text-xl font-semibold mt-8 mb-3">
        store.waitForAtom(atom, value, timeout)
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Returns a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Future</code>{' '}
        that completes when the atom reaches the expected value, or times out after the specified duration.
        This is essential for testing async atoms and delayed state transitions:
      </p>
      <CodeBlock
        code={`test('waitForAtom resolves when value matches', () async {
  // Simulate an async update happening after a delay
  Future.delayed(Duration(milliseconds: 100), () {
    store.set(statusAtom, 'complete');
  });

  // Wait for the atom to reach the expected value
  await store.waitForAtom(
    statusAtom,
    'complete',
    timeout: Duration(seconds: 2),
  );

  store.expectAtom(statusAtom, 'complete');
});

test('waitForAtom throws on timeout', () async {
  // This will time out because the value is never set
  expect(
    () => store.waitForAtom(
      statusAtom,
      'never-gonna-happen',
      timeout: Duration(milliseconds: 100),
    ),
    throwsA(isA<TimeoutException>()),
  );
});`}
      />

      {/* ------------------------------------------------------------------ */}
      {/* Widget Testing */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="widget-testing" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Widget Testing
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Widget tests verify that your Flutter UI reacts correctly to state changes.{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_test</code>{' '}
        provides the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">tester.pumpReacton()</code>{' '}
        extension on{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">WidgetTester</code>{' '}
        which handles all the boilerplate of wrapping your widget in the correct providers.
      </p>

      <h3 id="widget-pump-reacton" className="text-xl font-semibold mt-8 mb-3">
        tester.pumpReacton() Helper
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">tester.pumpReacton(widget, overrides: [...])</code>{' '}
        is an extension method that does three things automatically:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>Creates a fresh{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
          with the given overrides</li>
        <li>Wraps your widget in a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>{' '}
          so all descendant widgets can read/write atoms</li>
        <li>Wraps everything in a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MaterialApp</code>{' '}
          so that Material widgets, navigation, and theming work correctly</li>
      </ul>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        It returns the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        so you can read and mutate atoms from the test side:
      </p>
      <CodeBlock
        code={`testWidgets('pumpReacton sets up the full test environment', (tester) async {
  final store = await tester.pumpReacton(
    const MyWidget(),
    overrides: [
      AtomTestOverride<int>(counterAtom, 0),
      AtomTestOverride<String>(nameAtom, 'Test'),
    ],
  );

  // 'store' is the TestReactonStore used by the widget tree
  expect(store.get(counterAtom), 0);
});`}
      />

      <h3 id="widget-reactive-rebuilds" className="text-xl font-semibold mt-8 mb-3">
        Testing Reactive Rebuilds
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The fundamental pattern for widget testing with Reacton is: pump the widget, verify the initial
        rendered state, change an atom value, pump again, and verify the updated rendered state. This
        confirms that your widget is reactively subscribed to the atom:
      </p>
      <CodeBlock
        code={`testWidgets('widget rebuilds when atom changes', (tester) async {
  final store = await tester.pumpReacton(
    const CounterDisplay(),
    overrides: [AtomTestOverride<int>(counterAtom, 0)],
  );

  // Step 1: Verify initial state
  expect(find.text('Count: 0'), findsOneWidget);

  // Step 2: Change the atom value from the test side
  store.set(counterAtom, 99);

  // Step 3: Pump to trigger a rebuild
  await tester.pump();

  // Step 4: Verify the widget updated
  expect(find.text('Count: 99'), findsOneWidget);
});

testWidgets('only rebuilds for subscribed atoms', (tester) async {
  final store = await tester.pumpReacton(
    const CounterDisplay(), // only subscribes to counterAtom
    overrides: [
      AtomTestOverride<int>(counterAtom, 0),
      AtomTestOverride<String>(nameAtom, 'Alice'),
    ],
  );

  expect(find.text('Count: 0'), findsOneWidget);

  // Changing an unrelated atom should NOT trigger a rebuild
  store.set(nameAtom, 'Bob');
  await tester.pump();

  // Widget still shows the same content — no unnecessary rebuild
  expect(find.text('Count: 0'), findsOneWidget);
});`}
      />

      <h3 id="widget-user-interactions" className="text-xl font-semibold mt-8 mb-3">
        Testing User Interactions
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Simulate taps, drags, and text entry, then verify the atom value changed as expected:
      </p>
      <CodeBlock
        code={`testWidgets('tapping increment button updates atom', (tester) async {
  final store = await tester.pumpReacton(
    const CounterWidget(),
    overrides: [AtomTestOverride<int>(counterAtom, 0)],
  );

  // Initial state
  expect(find.text('0'), findsOneWidget);
  expect(store.get(counterAtom), 0);

  // Tap the increment button
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  // Verify both the atom and the UI updated
  expect(store.get(counterAtom), 1);
  expect(find.text('1'), findsOneWidget);

  // Tap three more times
  await tester.tap(find.byIcon(Icons.add));
  await tester.tap(find.byIcon(Icons.add));
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  expect(store.get(counterAtom), 4);
  expect(find.text('4'), findsOneWidget);
});

testWidgets('text field updates name atom on change', (tester) async {
  final store = await tester.pumpReacton(
    const NameInputWidget(),
    overrides: [AtomTestOverride<String>(nameAtom, '')],
  );

  // Enter text
  await tester.enterText(find.byType(TextField), 'Alice');
  await tester.pump();

  expect(store.get(nameAtom), 'Alice');
});`}
      />

      <h3 id="widget-async-atoms" className="text-xl font-semibold mt-8 mb-3">
        Testing with Async Atoms
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncTestOverride</code>{' '}
        to place an async atom in any state — loading, data, or error — without making real network calls.
        This lets you test every branch of your UI:
      </p>
      <CodeBlock
        title="Testing the loading state"
        code={`testWidgets('shows spinner while loading', (tester) async {
  await tester.pumpReacton(
    const PostsPage(),
    overrides: [
      AsyncTestOverride<List<Post>>(postsAtom, AsyncLoading()),
    ],
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.byType(ListView), findsNothing);
});`}
      />
      <CodeBlock
        title="Testing the data state"
        code={`testWidgets('shows posts when data is loaded', (tester) async {
  await tester.pumpReacton(
    const PostsPage(),
    overrides: [
      AsyncTestOverride<List<Post>>(postsAtom, AsyncData([
        Post(id: '1', title: 'First Post'),
        Post(id: '2', title: 'Second Post'),
      ])),
    ],
  );

  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.text('First Post'), findsOneWidget);
  expect(find.text('Second Post'), findsOneWidget);
});`}
      />
      <CodeBlock
        title="Testing the error state"
        code={`testWidgets('shows error message on failure', (tester) async {
  await tester.pumpReacton(
    const PostsPage(),
    overrides: [
      AsyncTestOverride<List<Post>>(postsAtom, AsyncError(
        Exception('Failed to fetch posts'),
        StackTrace.current,
      )),
    ],
  );

  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.text('Failed to fetch posts'), findsOneWidget);
  expect(find.byIcon(Icons.error), findsOneWidget);
});`}
      />

      <h3 id="widget-reacton-builder" className="text-xl font-semibold mt-8 mb-3">
        Testing ReactonBuilder Widgets
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>{' '}
        rebuilds its child whenever a watched atom changes. Test it by verifying the builder output
        before and after atom mutations:
      </p>
      <CodeBlock
        code={`testWidgets('ReactonBuilder rebuilds on atom change', (tester) async {
  final store = await tester.pumpReacton(
    ReactonBuilder<int>(
      atom: counterAtom,
      builder: (context, value) => Text('Value: \$value'),
    ),
    overrides: [AtomTestOverride<int>(counterAtom, 0)],
  );

  expect(find.text('Value: 0'), findsOneWidget);

  store.set(counterAtom, 42);
  await tester.pump();

  expect(find.text('Value: 42'), findsOneWidget);
});`}
      />

      <h3 id="widget-reacton-consumer" className="text-xl font-semibold mt-8 mb-3">
        Testing ReactonConsumer Widgets
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code>{' '}
        gives access to both reading and writing atoms in its builder. Test that reads display correctly
        and that write operations triggered from the builder update state:
      </p>
      <CodeBlock
        code={`testWidgets('ReactonConsumer can read and write atoms', (tester) async {
  final store = await tester.pumpReacton(
    ReactonConsumer(
      builder: (context, ref) {
        final count = ref.watch(counterAtom);
        return Column(
          children: [
            Text('Count: \$count'),
            ElevatedButton(
              onPressed: () => ref.set(counterAtom, count + 1),
              child: const Text('Increment'),
            ),
          ],
        );
      },
    ),
    overrides: [AtomTestOverride<int>(counterAtom, 0)],
  );

  expect(find.text('Count: 0'), findsOneWidget);

  await tester.tap(find.text('Increment'));
  await tester.pump();

  expect(find.text('Count: 1'), findsOneWidget);
  expect(store.get(counterAtom), 1);
});`}
      />

      <h3 id="widget-reacton-listener" className="text-xl font-semibold mt-8 mb-3">
        Testing ReactonListener Side Effects
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonListener</code>{' '}
        fires a callback when an atom changes but does not rebuild the child. Common uses include
        showing snackbars, navigating, or logging. Test it by mutating the atom and verifying
        the side effect occurred:
      </p>
      <CodeBlock
        code={`testWidgets('ReactonListener shows snackbar on error', (tester) async {
  final store = await tester.pumpReacton(
    ReactonListener<String?>(
      atom: errorAtom,
      listener: (context, error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      child: const Scaffold(body: Text('Content')),
    ),
    overrides: [AtomTestOverride<String?>(errorAtom, null)],
  );

  // No snackbar initially
  expect(find.byType(SnackBar), findsNothing);

  // Trigger an error
  store.set(errorAtom, 'Something went wrong');
  await tester.pump(); // process the listener callback
  await tester.pump(); // render the snackbar animation

  expect(find.text('Something went wrong'), findsOneWidget);
});

testWidgets('ReactonListener triggers navigation', (tester) async {
  final store = await tester.pumpReacton(
    ReactonListener<bool>(
      atom: isLoggedInAtom,
      listener: (context, isLoggedIn) {
        if (isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      child: const Text('Login Page'),
    ),
    overrides: [AtomTestOverride<bool>(isLoggedInAtom, false)],
  );

  expect(find.text('Login Page'), findsOneWidget);

  store.set(isLoggedInAtom, true);
  await tester.pumpAndSettle();

  // Navigation occurred — login page is gone
  expect(find.text('Login Page'), findsNothing);
});`}
      />

      <Callout type="tip" title="pumpAndSettle vs pump">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">tester.pumpAndSettle()</code>{' '}
        when your widget triggers animations or delayed microtasks (like navigation transitions or snackbar
        animations). Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">tester.pump()</code>{' '}
        for immediate, synchronous rebuilds.
      </Callout>

      {/* ------------------------------------------------------------------ */}
      {/* Mock Atoms */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="mocks" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Mock Atoms
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MockAtom&lt;T&gt;</code>{' '}
        wraps an existing atom and records every read and write interaction. This is invaluable when you need
        to verify <em>how</em> your code uses an atom — not just the final value, but the full history of
        interactions.
      </p>

      <h3 id="mocks-creating" className="text-xl font-semibold mt-8 mb-3">
        Creating a MockAtom
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Pass the original atom and an initial value. The mock replaces the atom in the test store:
      </p>
      <CodeBlock
        code={`final mock = MockAtom<int>(counterAtom, initialValue: 0);

final store = TestReactonStore(overrides: [
  mock.asOverride(), // register the mock as an override
]);`}
      />

      <h3 id="mocks-tracking-reads" className="text-xl font-semibold mt-8 mb-3">
        Tracking Reads
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Every time any code calls{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.get(atom)</code>{' '}
        or a computed atom reads this atom as a dependency, the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">readCount</code>{' '}
        is incremented:
      </p>
      <CodeBlock
        code={`test('tracks read count', () {
  final mock = MockAtom<int>(counterAtom, initialValue: 0);
  final store = TestReactonStore(overrides: [mock.asOverride()]);

  store.get(counterAtom);
  store.get(counterAtom);
  store.get(counterAtom);

  expect(mock.readCount, 3);

  store.dispose();
});`}
      />

      <h3 id="mocks-tracking-writes" className="text-xl font-semibold mt-8 mb-3">
        Tracking Writes
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">writeCount</code>{' '}
        records how many times the atom was written to, and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">valueHistory</code>{' '}
        records the complete ordered list of values the atom has held (including the initial value):
      </p>
      <CodeBlock
        code={`test('tracks writes and value history', () {
  final mock = MockAtom<int>(counterAtom, initialValue: 0);
  final store = TestReactonStore(overrides: [mock.asOverride()]);

  store.set(counterAtom, 5);
  store.set(counterAtom, 10);
  store.set(counterAtom, 15);

  expect(mock.writeCount, 3);
  expect(mock.valueHistory, [0, 5, 10, 15]); // includes initial

  store.dispose();
});`}
      />

      <h3 id="mocks-verifying-interactions" className="text-xl font-semibold mt-8 mb-3">
        Verifying Specific Interactions
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Combine read and write tracking to assert exact interaction patterns:
      </p>
      <CodeBlock
        code={`test('increment action reads once, writes once', () {
  final mock = MockAtom<int>(counterAtom, initialValue: 0);
  final store = TestReactonStore(overrides: [mock.asOverride()]);

  // Reset counts after setup reads
  mock.resetCounts();

  // The action under test
  store.update(counterAtom, (v) => v + 1);

  expect(mock.readCount, 1);  // read current value
  expect(mock.writeCount, 1); // wrote new value
  expect(mock.valueHistory.last, 1);

  store.dispose();
});`}
      />

      <h3 id="mocks-vs-overrides" className="text-xl font-semibold mt-8 mb-3">
        When to Use Mock Atoms vs Regular Overrides
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use the right tool for the right job:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">AtomTestOverride</strong> — when you only need to
          seed an initial value and verify the final value. This is the common case for most tests.</li>
        <li><strong className="text-gray-900 dark:text-white">MockAtom</strong> — when you need to verify
          <em> interaction counts</em>, the <em>full history</em> of values, or when debugging a test failure
          to understand exactly how an atom is being used.</li>
      </ul>
      <Callout type="info">
        Start with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomTestOverride</code>{' '}
        by default. Only reach for{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MockAtom</code>{' '}
        when you need to assert on how the atom was interacted with, not just its final state.
      </Callout>

      {/* ------------------------------------------------------------------ */}
      {/* Effect Testing */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="effect-tracking" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Effect Testing
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Effects are side-effect functions that run when an atom changes. The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">EffectTracker</code>{' '}
        utility records every invocation so you can assert that effects fire at the right times
        with the right data.
      </p>

      <h3 id="effect-tracker-basics" className="text-xl font-semibold mt-8 mb-3">
        EffectTracker Basics
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Create an{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">EffectTracker</code>{' '}
        and pass it as the effect callback. It records each call along with metadata like timestamps:
      </p>
      <CodeBlock
        code={`test('effect fires when atom changes', () {
  final tracker = EffectTracker<int>();
  final store = TestReactonStore(overrides: [
    AtomTestOverride<int>(counterAtom, 0),
  ]);

  store.addEffect(counterAtom, tracker.call);

  store.set(counterAtom, 1);
  store.set(counterAtom, 2);

  expect(tracker.callCount, 2);
  expect(tracker.values, [1, 2]);

  store.dispose();
});`}
      />

      <h3 id="effect-timing" className="text-xl font-semibold mt-8 mb-3">
        Verifying Effect Timing
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Each invocation is recorded with a timestamp, allowing you to assert on timing behavior:
      </p>
      <CodeBlock
        code={`test('effect invocations have timestamps', () {
  final tracker = EffectTracker<int>();
  final store = TestReactonStore(overrides: [
    AtomTestOverride<int>(counterAtom, 0),
  ]);

  store.addEffect(counterAtom, tracker.call);

  store.set(counterAtom, 1);
  store.set(counterAtom, 2);

  // Each invocation has a timestamp
  expect(tracker.invocations, hasLength(2));
  expect(tracker.invocations[0].timestamp, isNotNull);
  expect(tracker.invocations[1].timestamp, isNotNull);

  // Second invocation happened after the first
  expect(
    tracker.invocations[1].timestamp
      .isAfter(tracker.invocations[0].timestamp),
    isTrue,
  );

  // Shorthand for the last invocation
  expect(tracker.lastInvocation.value, 2);
  expect(tracker.lastInvocation.timestamp, isNotNull);

  store.dispose();
});`}
      />

      <h3 id="effect-cleanup" className="text-xl font-semibold mt-8 mb-3">
        Testing Cleanup Functions
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Effects can return cleanup functions that run before the next invocation or when the store disposes.
        Verify cleanup with a separate tracker:
      </p>
      <CodeBlock
        code={`test('effect cleanup runs before next invocation', () {
  var cleanupCount = 0;
  final store = TestReactonStore(overrides: [
    AtomTestOverride<int>(counterAtom, 0),
  ]);

  store.addEffect(counterAtom, (value) {
    // Setup logic here...
    return () {
      // Cleanup logic
      cleanupCount++;
    };
  });

  store.set(counterAtom, 1); // effect runs, no cleanup yet
  expect(cleanupCount, 0);

  store.set(counterAtom, 2); // previous cleanup runs, then new effect
  expect(cleanupCount, 1);

  store.set(counterAtom, 3); // previous cleanup runs, then new effect
  expect(cleanupCount, 2);

  store.dispose(); // final cleanup runs
  expect(cleanupCount, 3);
});`}
      />

      <h3 id="effect-dependencies" className="text-xl font-semibold mt-8 mb-3">
        Testing Effect Dependencies
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When an effect depends on multiple atoms, verify it fires when any dependency changes:
      </p>
      <CodeBlock
        code={`test('effect fires when any dependency changes', () {
  final tracker = EffectTracker<String>();
  final store = TestReactonStore(overrides: [
    AtomTestOverride<String>(firstNameAtom, 'John'),
    AtomTestOverride<String>(lastNameAtom, 'Doe'),
  ]);

  // fullNameAtom is a computed atom: "\$first \$last"
  store.addEffect(fullNameAtom, tracker.call);

  store.set(firstNameAtom, 'Jane');
  expect(tracker.callCount, 1);
  expect(tracker.lastInvocation.value, 'Jane Doe');

  store.set(lastNameAtom, 'Smith');
  expect(tracker.callCount, 2);
  expect(tracker.lastInvocation.value, 'Jane Smith');

  store.dispose();
});`}
      />

      {/* ------------------------------------------------------------------ */}
      {/* Testing Async Operations */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="async-testing" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Testing Async Operations
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Real-world apps are full of async operations — API calls, database reads, file I/O. Testing these
        requires controlling the async timeline and mocking external dependencies. This section covers
        patterns for every async scenario you will encounter.
      </p>

      <h3 id="async-loading-states" className="text-xl font-semibold mt-8 mb-3">
        Testing Loading States
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Override an async atom with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncLoading()</code>{' '}
        to simulate a pending request and verify your UI shows loading indicators:
      </p>
      <CodeBlock
        code={`test('async atom starts in loading state', () {
  final store = TestReactonStore(overrides: [
    AsyncTestOverride<User>(userAtom, AsyncLoading()),
  ]);

  final value = store.get(userAtom);
  expect(value.isLoading, isTrue);
  expect(value.hasData, isFalse);
  expect(value.hasError, isFalse);

  store.dispose();
});`}
      />

      <h3 id="async-error-handling" className="text-xl font-semibold mt-8 mb-3">
        Testing Error Handling
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Override with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncError</code>{' '}
        to simulate failures. Test that your code handles the error gracefully:
      </p>
      <CodeBlock
        code={`test('async atom handles errors', () {
  final store = TestReactonStore(overrides: [
    AsyncTestOverride<User>(userAtom, AsyncError(
      NotFoundException('User not found'),
      StackTrace.current,
    )),
  ]);

  final value = store.get(userAtom);
  expect(value.isLoading, isFalse);
  expect(value.hasError, isTrue);
  expect(value.error, isA<NotFoundException>());

  store.dispose();
});`}
      />

      <h3 id="async-retry" className="text-xl font-semibold mt-8 mb-3">
        Testing Retry Behavior
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        If your atoms support retry logic, simulate the transition from error to loading to data:
      </p>
      <CodeBlock
        code={`test('retry transitions from error to loading to data', () async {
  final store = TestReactonStore(overrides: [
    AsyncTestOverride<List<Post>>(postsAtom, AsyncError(
      Exception('Network error'),
      StackTrace.current,
    )),
  ]);

  // Currently in error state
  expect(store.get(postsAtom).hasError, isTrue);

  // Trigger retry — transitions to loading
  store.set(postsAtom, AsyncLoading());
  expect(store.get(postsAtom).isLoading, isTrue);

  // Simulate successful response
  store.set(postsAtom, AsyncData([Post(id: '1', title: 'Recovered')]));
  expect(store.get(postsAtom).hasData, isTrue);
  expect(store.get(postsAtom).data, hasLength(1));

  store.dispose();
});`}
      />

      <h3 id="async-mock-api" className="text-xl font-semibold mt-8 mb-3">
        Mocking API Responses
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        For atoms that fetch from an API, override the API client atom to inject a mock.
        This completely eliminates network calls from your tests:
      </p>
      <CodeBlock
        code={`// Your app atoms
final apiClientAtom = atom<ApiClient>(ApiClient());
final postsAtom = asyncAtom<List<Post>>((get) async {
  final client = get(apiClientAtom);
  return client.fetchPosts();
});

// In your test
class MockApiClient extends Mock implements ApiClient {}

test('postsAtom fetches from API', () async {
  final mockApi = MockApiClient();
  when(() => mockApi.fetchPosts()).thenAnswer(
    (_) async => [Post(id: '1', title: 'Mock Post')],
  );

  final store = TestReactonStore(overrides: [
    AtomTestOverride<ApiClient>(apiClientAtom, mockApi),
  ]);

  // Wait for the async atom to resolve
  await store.waitForAtom(
    postsAtom,
    predicate: (v) => v.hasData,
    timeout: Duration(seconds: 2),
  );

  expect(store.get(postsAtom).data, hasLength(1));
  expect(store.get(postsAtom).data!.first.title, 'Mock Post');
  verify(() => mockApi.fetchPosts()).called(1);

  store.dispose();
});`}
      />

      <h3 id="async-optimistic" className="text-xl font-semibold mt-8 mb-3">
        Testing Optimistic Updates and Rollback
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Optimistic updates show the expected result immediately, then roll back if the server
        rejects the change. Test both the happy path and the rollback:
      </p>
      <CodeBlock
        code={`test('optimistic update rolls back on failure', () async {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<List<Todo>>(todosAtom, [
      Todo(id: '1', title: 'Existing', done: false),
    ]),
  ]);

  // Capture emissions
  final emissions = store.collectValues(todosAtom, count: 3);

  // Step 1: Optimistic update — mark as done immediately
  store.update(todosAtom, (todos) =>
    todos.map((t) => t.id == '1' ? t.copyWith(done: true) : t).toList(),
  );

  // Step 2: Server rejects the update
  // Step 3: Rollback to original
  store.update(todosAtom, (todos) =>
    todos.map((t) => t.id == '1' ? t.copyWith(done: false) : t).toList(),
  );

  // Verify the sequence: original -> optimistic -> rollback
  expect(emissions[0].first.done, true);  // optimistic
  expect(emissions[1].first.done, false); // rollback

  store.dispose();
});`}
      />

      <h3 id="async-fake-async" className="text-xl font-semibold mt-8 mb-3">
        Using FakeAsync with Reacton
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        For precise control over time-based behavior — debounced atoms, periodic refreshes, timeouts — use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">FakeAsync</code>{' '}
        from the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">fake_async</code>{' '}
        package:
      </p>
      <CodeBlock
        code={`import 'package:fake_async/fake_async.dart';

test('debounced atom waits before emitting', () {
  fakeAsync((async) {
    final store = TestReactonStore(overrides: [
      AtomTestOverride<String>(searchQueryAtom, ''),
    ]);

    // debouncedSearchAtom debounces searchQueryAtom by 300ms
    final emissions = <String>[];
    store.subscribe(debouncedSearchAtom, (v) => emissions.add(v));

    // Type quickly
    store.set(searchQueryAtom, 'f');
    store.set(searchQueryAtom, 'fl');
    store.set(searchQueryAtom, 'flu');
    store.set(searchQueryAtom, 'flut');

    // Before debounce period: no emission
    async.elapse(Duration(milliseconds: 200));
    expect(emissions, isEmpty);

    // After debounce period: only the latest value emits
    async.elapse(Duration(milliseconds: 300));
    expect(emissions, ['flut']);

    store.dispose();
  });
});`}
      />

      <h3 id="async-complete-example" className="text-xl font-semibold mt-8 mb-3">
        Complete Example: Testing an API-Driven Feature
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here is a complete test file for a user profile feature that fetches data from an API,
        supports refresh, and handles errors:
      </p>
      <CodeBlock
        title="test/features/user_profile_test.dart"
        code={`import 'package:reacton_test/reacton_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/atoms/user_atoms.dart';
import 'package:my_app/services/user_service.dart';
import 'package:my_app/widgets/user_profile.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late MockUserService mockService;
  late TestReactonStore store;

  setUp(() {
    mockService = MockUserService();
  });

  tearDown(() => store.dispose());

  group('UserProfile unit tests', () {
    test('userAtom loads user from service', () async {
      when(() => mockService.getUser('1')).thenAnswer(
        (_) async => User(id: '1', name: 'Alice', email: 'a@b.com'),
      );

      store = TestReactonStore(overrides: [
        AtomTestOverride<UserService>(userServiceAtom, mockService),
        AtomTestOverride<String>(selectedUserIdAtom, '1'),
      ]);

      await store.waitForAtom(
        userAtom,
        predicate: (v) => v.hasData,
        timeout: Duration(seconds: 2),
      );

      expect(store.get(userAtom).data!.name, 'Alice');
      verify(() => mockService.getUser('1')).called(1);
    });

    test('userAtom enters error state on failure', () async {
      when(() => mockService.getUser('1')).thenThrow(
        Exception('Server error'),
      );

      store = TestReactonStore(overrides: [
        AtomTestOverride<UserService>(userServiceAtom, mockService),
        AtomTestOverride<String>(selectedUserIdAtom, '1'),
      ]);

      await store.waitForAtom(
        userAtom,
        predicate: (v) => v.hasError,
        timeout: Duration(seconds: 2),
      );

      expect(store.get(userAtom).hasError, isTrue);
    });
  });

  group('UserProfile widget tests', () {
    testWidgets('shows loading indicator', (tester) async {
      store = await tester.pumpReacton(
        const UserProfilePage(),
        overrides: [
          AsyncTestOverride<User>(userAtom, AsyncLoading()),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows user data', (tester) async {
      store = await tester.pumpReacton(
        const UserProfilePage(),
        overrides: [
          AsyncTestOverride<User>(userAtom, AsyncData(
            User(id: '1', name: 'Alice', email: 'a@b.com'),
          )),
        ],
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('a@b.com'), findsOneWidget);
    });

    testWidgets('shows error with retry button', (tester) async {
      store = await tester.pumpReacton(
        const UserProfilePage(),
        overrides: [
          AsyncTestOverride<User>(userAtom, AsyncError(
            Exception('Failed'),
            StackTrace.current,
          )),
        ],
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}`}
      />

      {/* ------------------------------------------------------------------ */}
      {/* Testing State Branching */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="testing-branching" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Testing State Branching
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        State branching creates isolated copies of state that can be modified independently and later merged
        or discarded. Testing branches ensures that isolation works correctly and merges produce the expected
        result.
      </p>

      <h3 id="branching-create" className="text-xl font-semibold mt-8 mb-3">
        Creating and Testing Branches
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Create a branch from a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        and verify that changes in the branch do not affect the parent, and vice versa:
      </p>
      <CodeBlock
        code={`test('branch isolates state from parent', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<String>(themeAtom, 'light'),
    AtomTestOverride<int>(fontSizeAtom, 14),
  ]);

  final branch = store.createBranch('theme-preview');

  // Branch inherits parent values
  expect(branch.get(themeAtom), 'light');
  expect(branch.get(fontSizeAtom), 14);

  // Modify branch — parent is unaffected
  branch.set(themeAtom, 'dark');
  branch.set(fontSizeAtom, 18);

  expect(branch.get(themeAtom), 'dark');
  expect(branch.get(fontSizeAtom), 18);
  expect(store.get(themeAtom), 'light');   // parent unchanged
  expect(store.get(fontSizeAtom), 14);     // parent unchanged

  store.dispose();
});`}
      />

      <h3 id="branching-diff" className="text-xl font-semibold mt-8 mb-3">
        Asserting Branch Diff
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">diff()</code>{' '}
        method returns all atoms that differ between the branch and the parent:
      </p>
      <CodeBlock
        code={`test('branch diff shows only changed atoms', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<String>(themeAtom, 'light'),
    AtomTestOverride<int>(fontSizeAtom, 14),
    AtomTestOverride<String>(localeAtom, 'en'),
  ]);

  final branch = store.createBranch('settings-draft');

  // Modify only some atoms
  branch.set(themeAtom, 'dark');
  branch.set(fontSizeAtom, 18);
  // localeAtom is NOT changed

  final diff = branch.diff();
  expect(diff.changes, hasLength(2));
  expect(diff.changes.containsKey(themeAtom), isTrue);
  expect(diff.changes.containsKey(fontSizeAtom), isTrue);
  expect(diff.changes.containsKey(localeAtom), isFalse); // unchanged

  // Inspect individual changes
  expect(diff.changes[themeAtom]!.oldValue, 'light');
  expect(diff.changes[themeAtom]!.newValue, 'dark');

  store.dispose();
});`}
      />

      <h3 id="branching-merge" className="text-xl font-semibold mt-8 mb-3">
        Testing Merge Behavior
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Verify that merging a branch applies its changes to the parent store:
      </p>
      <CodeBlock
        code={`test('merging branch applies changes to parent', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<String>(themeAtom, 'light'),
    AtomTestOverride<int>(fontSizeAtom, 14),
  ]);

  final branch = store.createBranch('settings-draft');
  branch.set(themeAtom, 'dark');
  branch.set(fontSizeAtom, 18);

  // Before merge — parent unchanged
  expect(store.get(themeAtom), 'light');

  // Merge
  store.mergeBranch(branch);

  // After merge — parent updated
  expect(store.get(themeAtom), 'dark');
  expect(store.get(fontSizeAtom), 18);

  store.dispose();
});

test('discarding branch does not affect parent', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<String>(themeAtom, 'light'),
  ]);

  final branch = store.createBranch('experiment');
  branch.set(themeAtom, 'solarized');

  // Discard instead of merge
  branch.discard();

  expect(store.get(themeAtom), 'light'); // unchanged

  store.dispose();
});`}
      />

      {/* ------------------------------------------------------------------ */}
      {/* Testing Time Travel */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="testing-time-travel" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Testing Time Travel
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Time travel lets users undo and redo atom changes. Testing it ensures your history tracking
        works correctly and that undo/redo produce the expected state at each step.
      </p>

      <h3 id="time-travel-undo-redo" className="text-xl font-semibold mt-8 mb-3">
        Testing Undo and Redo
      </h3>
      <CodeBlock
        code={`test('undo reverts to previous value', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<int>(counterAtom, 0),
  ]);

  final history = store.enableHistory(counterAtom, maxHistory: 10);

  store.set(counterAtom, 1);
  store.set(counterAtom, 2);
  store.set(counterAtom, 3);

  expect(store.get(counterAtom), 3);

  history.undo();
  expect(store.get(counterAtom), 2);

  history.undo();
  expect(store.get(counterAtom), 1);

  history.redo();
  expect(store.get(counterAtom), 2);

  history.redo();
  expect(store.get(counterAtom), 3);

  history.dispose();
  store.dispose();
});`}
      />

      <h3 id="time-travel-history-entries" className="text-xl font-semibold mt-8 mb-3">
        Asserting History Entries
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Verify the history state — entry count, current index, and whether undo/redo is available:
      </p>
      <CodeBlock
        code={`test('history tracks entries and position correctly', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<String>(nameAtom, 'initial'),
  ]);

  final history = store.enableHistory(nameAtom, maxHistory: 50);

  // Initial state — no undo or redo available
  expect(history.canUndo, isFalse);
  expect(history.canRedo, isFalse);
  expect(history.entries, hasLength(1)); // initial value
  expect(history.currentIndex, 0);

  store.set(nameAtom, 'Alice');
  store.set(nameAtom, 'Bob');
  store.set(nameAtom, 'Charlie');

  expect(history.entries, hasLength(4)); // initial + 3 changes
  expect(history.currentIndex, 3);
  expect(history.canUndo, isTrue);
  expect(history.canRedo, isFalse);

  history.undo();
  expect(history.currentIndex, 2);
  expect(history.canUndo, isTrue);
  expect(history.canRedo, isTrue);

  // Jump to specific entry
  history.jumpTo(0);
  expect(store.get(nameAtom), 'initial');
  expect(history.currentIndex, 0);
  expect(history.canUndo, isFalse);
  expect(history.canRedo, isTrue);

  history.dispose();
  store.dispose();
});

test('history respects maxHistory limit', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<int>(counterAtom, 0),
  ]);

  final history = store.enableHistory(counterAtom, maxHistory: 3);

  store.set(counterAtom, 1);
  store.set(counterAtom, 2);
  store.set(counterAtom, 3);
  store.set(counterAtom, 4); // oldest entry (0) is evicted

  expect(history.entries, hasLength(3));
  // Cannot undo all the way back to 0
  history.undo();
  history.undo();
  expect(store.get(counterAtom), 2); // earliest available

  history.dispose();
  store.dispose();
});`}
      />

      <Callout type="info" title="History forks on new changes">
        If you undo two steps and then make a new change, the "future" entries are discarded.
        This mirrors Git behavior: making a new commit after checking out an older commit creates
        a new branch of history.
      </Callout>

      {/* ------------------------------------------------------------------ */}
      {/* Integration Testing */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="integration-testing" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Integration Testing
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Integration tests verify that multiple atoms, effects, and widgets work together correctly
        in realistic flows. While unit tests verify individual atoms in isolation, integration tests
        catch issues that only appear when the full system interacts.
      </p>

      <h3 id="integration-multiple-atoms" className="text-xl font-semibold mt-8 mb-3">
        Testing Multiple Atoms Together
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Create a single{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        with all relevant atoms and verify cross-atom interactions:
      </p>
      <CodeBlock
        code={`test('cart total reflects item changes and discount', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<List<CartItem>>(cartItemsAtom, []),
    AtomTestOverride<double>(discountAtom, 0.0),
    AtomTestOverride<String>(promoCodeAtom, ''),
  ]);

  // Add items
  store.set(cartItemsAtom, [
    CartItem(id: '1', name: 'Shirt', price: 40.0),
    CartItem(id: '2', name: 'Pants', price: 60.0),
  ]);

  // Subtotal computed correctly
  expect(store.get(cartSubtotalAtom), 100.0);
  expect(store.get(cartTotalAtom), 100.0);

  // Apply promo code which sets 20% discount
  store.set(promoCodeAtom, 'SAVE20');
  // Assume promoCodeAtom triggers a computed that sets discountAtom
  store.set(discountAtom, 0.20);

  expect(store.get(cartTotalAtom), 80.0);

  // Remove an item
  store.update(cartItemsAtom, (items) =>
    items.where((i) => i.id != '1').toList(),
  );

  expect(store.get(cartSubtotalAtom), 60.0);
  expect(store.get(cartTotalAtom), 48.0); // 60 * 0.80

  store.dispose();
});`}
      />

      <h3 id="integration-complex-flow" className="text-xl font-semibold mt-8 mb-3">
        Testing a Complex Flow (Login Example)
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        This example tests the entire login flow end-to-end: entering credentials, submitting,
        handling loading state, and verifying the authenticated state:
      </p>
      <CodeBlock
        title="test/features/auth_flow_test.dart"
        code={`import 'package:reacton_test/reacton_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuth;

  setUp(() {
    mockAuth = MockAuthService();
  });

  group('Login flow integration', () {
    testWidgets('successful login navigates to home', (tester) async {
      when(() => mockAuth.login('user@test.com', 'pass123'))
        .thenAnswer((_) async => AuthToken('abc-token'));

      final store = await tester.pumpReacton(
        const LoginPage(),
        overrides: [
          AtomTestOverride<AuthService>(authServiceAtom, mockAuth),
          AtomTestOverride<AuthState>(authStateAtom, AuthState.unauthenticated),
          AtomTestOverride<bool>(isLoadingAtom, false),
        ],
      );

      // Step 1: Enter credentials
      await tester.enterText(
        find.byKey(Key('email-field')),
        'user@test.com',
      );
      await tester.enterText(
        find.byKey(Key('password-field')),
        'pass123',
      );
      await tester.pump();

      // Step 2: Tap login button
      await tester.tap(find.byKey(Key('login-button')));
      await tester.pump();

      // Step 3: Verify loading state
      expect(store.get(isLoadingAtom), isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Step 4: Let the async login complete
      await tester.pumpAndSettle();

      // Step 5: Verify authenticated state
      expect(store.get(authStateAtom), AuthState.authenticated);
      verify(() => mockAuth.login('user@test.com', 'pass123')).called(1);
    });

    testWidgets('failed login shows error message', (tester) async {
      when(() => mockAuth.login(any(), any()))
        .thenThrow(AuthException('Invalid credentials'));

      final store = await tester.pumpReacton(
        const LoginPage(),
        overrides: [
          AtomTestOverride<AuthService>(authServiceAtom, mockAuth),
          AtomTestOverride<AuthState>(authStateAtom, AuthState.unauthenticated),
          AtomTestOverride<bool>(isLoadingAtom, false),
        ],
      );

      await tester.enterText(
        find.byKey(Key('email-field')),
        'wrong@test.com',
      );
      await tester.enterText(
        find.byKey(Key('password-field')),
        'wrongpass',
      );
      await tester.tap(find.byKey(Key('login-button')));
      await tester.pumpAndSettle();

      // Still unauthenticated
      expect(store.get(authStateAtom), AuthState.unauthenticated);

      // Error message shown
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}`}
      />

      <h3 id="integration-performance" className="text-xl font-semibold mt-8 mb-3">
        Performance Testing Tips
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        While Reacton tests run quickly by default, large atom graphs can occasionally reveal
        performance regressions. Use these patterns to catch them:
      </p>
      <CodeBlock
        code={`test('computed atom does not recompute excessively', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<List<int>>(numbersAtom, List.generate(1000, (i) => i)),
  ]);

  var computeCount = 0;
  // Spy on the computed atom
  store.subscribe(expensiveComputedAtom, (_) => computeCount++);

  // Changing an unrelated atom should NOT trigger recomputation
  store.set(unrelatedAtom, 'changed');
  expect(computeCount, 0);

  // Changing a dependency triggers exactly ONE recomputation
  store.set(numbersAtom, [1, 2, 3]);
  expect(computeCount, 1);

  store.dispose();
});

test('batch update with 100 atoms notifies once per subscriber', () {
  final store = TestReactonStore();
  final atoms = List.generate(100, (i) => atom<int>(0));

  var notificationCount = 0;
  store.subscribe(sumAtom, (_) => notificationCount++);

  store.batch(() {
    for (final a in atoms) {
      store.set(a, 1);
    }
  });

  // All 100 changes batched into a single notification
  expect(notificationCount, 1);

  store.dispose();
});`}
      />

      {/* ------------------------------------------------------------------ */}
      {/* Best Practices */}
      {/* ------------------------------------------------------------------ */}
      <h2 id="best-practices" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Best Practices
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Following these guidelines will keep your Reacton tests fast, reliable, and easy to maintain.
      </p>

      <h3 id="best-practices-one-assertion" className="text-xl font-semibold mt-8 mb-3">
        One Assertion per Test
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Each test should verify a single behavior. If a test fails, you should immediately know <em>what</em>{' '}
        broke. Avoid putting multiple unrelated assertions in one test:
      </p>
      <CodeBlock
        code={`// Bad — too many unrelated assertions
test('counter works', () {
  store.set(counterAtom, 5);
  expect(store.get(counterAtom), 5);      // tests set
  store.update(counterAtom, (v) => v + 1);
  expect(store.get(counterAtom), 6);      // tests update
  expect(store.get(doubleCountAtom), 12); // tests computed
});

// Good — each test has a single focus
test('set updates atom value', () {
  store.set(counterAtom, 5);
  store.expectAtom(counterAtom, 5);
});

test('update applies function to current value', () {
  store.set(counterAtom, 5);
  store.update(counterAtom, (v) => v + 1);
  store.expectAtom(counterAtom, 6);
});

test('computed atom derives from dependency', () {
  store.set(counterAtom, 6);
  store.expectAtom(doubleCountAtom, 12);
});`}
      />

      <h3 id="best-practices-dispose" className="text-xl font-semibold mt-8 mb-3">
        Always Dispose in tearDown
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A disposed store cancels all subscriptions, stops all effects, and releases resources.
        Failing to dispose can cause:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Timer leaks</strong> — scheduled microtasks from async atoms</li>
        <li><strong className="text-gray-900 dark:text-white">Cross-test contamination</strong> — subscriptions from a previous test fire during the next</li>
        <li><strong className="text-gray-900 dark:text-white">Memory leaks</strong> — large data retained by unreleased atom references</li>
      </ul>
      <CodeBlock
        code={`// Always pair setUp with tearDown
late TestReactonStore store;

setUp(() {
  store = TestReactonStore(overrides: [/* ... */]);
});

tearDown(() => store.dispose()); // never skip this`}
      />

      <h3 id="best-practices-overrides" className="text-xl font-semibold mt-8 mb-3">
        Use Overrides Instead of Modifying Global Atoms
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Never modify a global atom definition to make a test work. Instead, use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomTestOverride</code>{' '}
        or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncTestOverride</code>{' '}
        to inject test values. This keeps your production atom definitions clean and ensures test isolation:
      </p>
      <CodeBlock
        code={`// Bad — mutating a global default
counterAtom.defaultValue = 10; // pollutes other tests!

// Good — use an override
final store = TestReactonStore(overrides: [
  AtomTestOverride<int>(counterAtom, 10),
]);`}
      />
      <Callout type="danger" title="Never mutate global atom definitions in tests">
        Modifying{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">defaultValue</code>{' '}
        or other properties on global atoms changes shared state between tests. This makes tests
        order-dependent and causes mysterious failures when tests run in different orders or in parallel.
      </Callout>

      <h3 id="best-practices-atom-logic" className="text-xl font-semibold mt-8 mb-3">
        Test Atom Logic Independently from Widgets
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Atom logic (computations, side effects, async operations) should be tested with plain{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TestReactonStore</code>{' '}
        unit tests. Widget tests should only verify that the UI renders the correct output for
        a given atom state. This separation means:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Atom tests</strong> are fast (no widget tree overhead) and cover all logic edge cases</li>
        <li><strong className="text-gray-900 dark:text-white">Widget tests</strong> are focused on rendering and user interaction, not business logic</li>
        <li><strong className="text-gray-900 dark:text-white">Failures are localized</strong> — a failing atom test means the logic is wrong; a failing widget test means the UI is wrong</li>
      </ul>
      <CodeBlock
        code={`// Atom test — verifies logic
test('discount computed correctly', () {
  final store = TestReactonStore(overrides: [
    AtomTestOverride<double>(priceAtom, 100.0),
    AtomTestOverride<double>(discountAtom, 0.25),
  ]);

  store.expectAtom(finalPriceAtom, 75.0);

  store.dispose();
});

// Widget test — verifies rendering (not logic)
testWidgets('displays formatted price', (tester) async {
  await tester.pumpReacton(
    const PriceDisplay(),
    overrides: [
      AtomTestOverride<double>(finalPriceAtom, 75.0),
    ],
  );

  expect(find.text('\$75.00'), findsOneWidget);
});`}
      />

      <h3 id="best-practices-isolation" className="text-xl font-semibold mt-8 mb-3">
        Keep Tests Isolated
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Every test must be able to run independently, in any order, and produce the same result.
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">setUp</code>{' '}
        /{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">tearDown</code>{' '}
        pattern guarantees this because each test gets a completely fresh store. Never rely on
        state from a previous test:
      </p>
      <CodeBlock
        code={`// Bad — tests depend on each other
test('set counter to 5', () {
  store.set(counterAtom, 5);
});

test('counter is 5', () {
  expect(store.get(counterAtom), 5); // fails if run alone!
});

// Good — each test is self-contained
test('set counter to 5', () {
  store.set(counterAtom, 5);
  store.expectAtom(counterAtom, 5);
});

test('counter starts at default override', () {
  // Fresh store from setUp — starts at 0 regardless of other tests
  store.expectAtom(counterAtom, 0);
});`}
      />

      <Callout type="tip" title="Run tests with --shuffle">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter test --test-randomize-ordering-seed=random</code>{' '}
        to run tests in random order. If any test fails, it means that test depends on execution
        order and needs to be fixed.
      </Callout>

      <PageNav
        prev={{ title: 'Advanced Features', path: '/advanced' }}
        next={{ title: 'Tooling', path: '/tooling' }}
      />
    </div>
  )
}
