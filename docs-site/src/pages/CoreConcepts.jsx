import CodeBlock from '../components/CodeBlock'
import Callout from '../components/Callout'
import PageNav from '../components/PageNav'

export default function CoreConcepts() {
  return (
    <div>
      <h1 id="core-concepts" className="text-4xl font-extrabold tracking-tight mb-4">
        Core Concepts
      </h1>
      <p className="text-lg text-gray-500 dark:text-gray-400 mb-4">
        A deep dive into Reacton's reactive primitives, the graph engine that powers them,
        and the patterns you need to build predictable, high-performance Flutter applications.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-8 leading-relaxed">
        Reacton is built on a small number of composable primitives:{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">selector</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">family</code>, and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">effect</code>.
        Together they form a reactive graph that keeps your UI in sync with your data
        while guaranteeing correctness and minimizing unnecessary work.
      </p>

      {/* ================================================================== */}
      {/* ATOMS                                                              */}
      {/* ================================================================== */}
      <h2 id="atoms" className="text-2xl font-bold mt-12 mb-4">
        Atoms &mdash; The Foundation
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        An <strong>atom</strong> is the smallest unit of reactive state in Reacton.
        Think of it as a single cell in a spreadsheet: it holds one value, it can
        be read and written, and anything that depends on it is automatically
        notified when it changes.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Atoms are created with the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom&lt;T&gt;(initialValue)</code>{' '}
        factory function. The type parameter{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">T</code>{' '}
        can usually be inferred from the initial value, but you should provide it
        explicitly for collections or nullable types to ensure compile-time safety.
      </p>

      <h3 id="atoms-basic" className="text-xl font-semibold mt-8 mb-3">
        Basic Atom Declaration
      </h3>
      <CodeBlock
        title="atoms_basic.dart"
        code={`import 'package:reacton/reacton.dart';

// Integer atom - type inferred as int
final counterAtom = atom(0, name: 'counter');

// String atom
final greetingAtom = atom('Hello, world!', name: 'greeting');

// Boolean atom
final isDarkModeAtom = atom(false, name: 'isDarkMode');

// Double atom
final priceAtom = atom(9.99, name: 'price');

// Nullable atom - explicit type required
final selectedIdAtom = atom<int?>(null, name: 'selectedId');`}
      />

      <h3 id="atoms-typed" className="text-xl font-semibold mt-8 mb-3">
        Typed Atoms with Collections and Custom Objects
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When the initial value is an empty collection, Dart cannot infer the
        element type. Always provide an explicit type parameter in these cases.
      </p>
      <CodeBlock
        title="atoms_typed.dart"
        code={`// List atom - explicit type required for empty list
final todosAtom = atom<List<String>>([], name: 'todos');

// Map atom
final cacheAtom = atom<Map<String, dynamic>>({}, name: 'cache');

// Set atom
final tagsAtom = atom<Set<String>>({}, name: 'tags');

// Custom class atom
final userAtom = atom<User>(
  User(name: 'Alice', age: 30, email: 'alice@example.com'),
  name: 'currentUser',
);

// Enum atom
final themeAtom = atom<ThemeMode>(ThemeMode.system, name: 'themeMode');`}
      />

      <h3 id="atom-ref" className="text-xl font-semibold mt-8 mb-3">
        AtomRef &mdash; Unique Identity
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Every atom is backed by an{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomRef</code>{' '}
        object. The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomRef</code>{' '}
        is the atom's identity within the reactive graph. When you call{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom()</code>,
        you get back an{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomRef&lt;T&gt;</code>{' '}
        &mdash; a lightweight, immutable handle that the store uses to look up the
        atom's current value and its position in the dependency graph.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Because identity is based on the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomRef</code>{' '}
        object instance (reference equality), two calls to{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom(0)</code>{' '}
        produce two completely independent atoms, even if they have the same
        initial value. This is why top-level declarations are so important.
      </p>
      <CodeBlock
        title="atom_ref_identity.dart"
        code={`// These are TWO separate atoms with independent state
final atomA = atom(0, name: 'a');
final atomB = atom(0, name: 'b');

// atomA and atomB have different AtomRef instances,
// so the store treats them as distinct pieces of state.
assert(atomA != atomB); // true - different identities

// Passing atomA to store.get() always returns atomA's value,
// never atomB's, because the store keys on the AtomRef.
store.set(atomA, 10);
store.set(atomB, 20);
print(store.get(atomA)); // 10
print(store.get(atomB)); // 20`}
      />

      <h3 id="atom-options" className="text-xl font-semibold mt-8 mb-3">
        AtomOptions &mdash; Configuration
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The optional{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">options</code>{' '}
        parameter lets you customize an atom's behavior. It accepts an{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomOptions</code>{' '}
        object with the following fields:
      </p>
      <ul className="list-disc list-inside space-y-2 text-gray-600 dark:text-gray-400 mb-6 ml-2">
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">keepAlive</code>{' '}
          &mdash; When{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">true</code>,
          the atom's value is retained even when no widget is watching it.
          By default, atoms are auto-disposed when their last subscriber unsubscribes.
        </li>
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">equals</code>{' '}
          &mdash; A custom equality function{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">bool Function(T prev, T next)</code>{' '}
          used to determine whether the value has actually changed. If this
          function returns{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">true</code>,
          downstream nodes are not notified.
        </li>
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">middleware</code>{' '}
          &mdash; A list of middleware functions that intercept and can transform
          values before they are stored.
        </li>
      </ul>
      <CodeBlock
        title="atom_options.dart"
        code={`import 'package:collection/collection.dart';

// keepAlive: value persists even with no watchers
final settingsAtom = atom<AppSettings>(
  AppSettings.defaults(),
  name: 'settings',
  options: AtomOptions(keepAlive: true),
);

// Custom equality for lists (default == compares by reference)
final todosAtom = atom<List<Todo>>(
  [],
  name: 'todos',
  options: AtomOptions(
    keepAlive: true,
    equals: const ListEquality<Todo>().equals,
  ),
);

// Custom equality for maps
final prefsAtom = atom<Map<String, String>>(
  {},
  name: 'preferences',
  options: AtomOptions(
    equals: const MapEquality<String, String>().equals,
  ),
);

// Middleware for validation / logging
final ageAtom = atom<int>(
  0,
  name: 'age',
  options: AtomOptions(
    middleware: [
      // Clamp to valid range
      (next, prev) => next.clamp(0, 150),
      // Log every change
      (next, prev) {
        print('age: \$prev -> \$next');
        return next;
      },
    ],
  ),
);`}
      />

      <Callout type="warning" title="Collection equality">
        Dart's default{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code>{' '}
        operator compares lists, maps, and sets by <em>reference</em>, not by content.
        If you store a collection in an atom and replace it with a new instance
        containing the same elements, Reacton will consider it "changed" and notify
        all subscribers. Use a custom{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">equals</code>{' '}
        function (e.g., from the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">collection</code>{' '}
        package) to perform deep equality checks and avoid unnecessary rebuilds.
      </Callout>

      <h3 id="atom-naming" className="text-xl font-semibold mt-8 mb-3">
        Naming Conventions and Best Practices
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        While the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">name</code>{' '}
        parameter is optional, providing one is strongly recommended. Names
        appear in devtools, debug logs, and error messages, making it
        dramatically easier to trace issues in a large application.
      </p>
      <ul className="list-disc list-inside space-y-2 text-gray-600 dark:text-gray-400 mb-6 ml-2">
        <li>Suffix the Dart variable with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Atom</code> &mdash; e.g., <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">counterAtom</code>, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">userAtom</code>.</li>
        <li>Use <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">camelCase</code> for the name string &mdash; e.g., <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">name: 'currentUser'</code>.</li>
        <li>Group related atoms in the same file &mdash; e.g., <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">auth_atoms.dart</code>, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">cart_atoms.dart</code>.</li>
        <li>Declare atoms as top-level <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">final</code> variables, never inside widgets or build methods.</li>
      </ul>

      <Callout type="danger" title="Never create atoms inside build()">
        Creating an atom inside a widget's{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>{' '}
        method creates a <em>new</em>{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomRef</code>{' '}
        on every rebuild, meaning you lose all previous state and break the
        dependency graph. Always declare atoms at the top level of a Dart file
        or as static fields on a class.
      </Callout>
      <CodeBlock
        title="atom_placement.dart"
        code={`// CORRECT: top-level declaration
final counterAtom = atom(0, name: 'counter');

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use the atom here - do NOT create one here
    return AtomBuilder(
      atom: counterAtom,
      builder: (context, count) => Text('\$count'),
    );
  }
}

// WRONG: atom created inside build - new identity every rebuild!
class BrokenCounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // BUG: creates a new atom on every build call
    final badAtom = atom(0, name: 'counter');
    return AtomBuilder(
      atom: badAtom,
      builder: (context, count) => Text('\$count'),
    );
  }
}`}
      />

      {/* ================================================================== */}
      {/* COMPUTED                                                           */}
      {/* ================================================================== */}
      <h2 id="computed" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Computed Values
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A <strong>computed</strong> value is derived state. It reads from one or more
        atoms (or other computed values), runs a pure function over them, and
        caches the result. Three key properties define computed values:
      </p>
      <ul className="list-disc list-inside space-y-2 text-gray-600 dark:text-gray-400 mb-6 ml-2">
        <li><strong>Lazy</strong> &mdash; the derivation function does not run until the computed value is first read.</li>
        <li><strong>Cached</strong> &mdash; once computed, the result is stored and reused until a dependency actually changes.</li>
        <li><strong>Auto-tracked</strong> &mdash; dependencies are recorded automatically when the derivation function calls <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>. You never have to declare a dependency list manually.</li>
      </ul>

      <h3 id="computed-basic" className="text-xl font-semibold mt-8 mb-3">
        Basic Computed Declaration
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed&lt;T&gt;((read) =&gt; ...)</code>{' '}
        factory. The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read</code>{' '}
        callback is provided by Reacton and serves two purposes: it returns the
        current value of the atom you pass to it, <em>and</em> it registers that
        atom as a dependency of this computed node.
      </p>
      <CodeBlock
        title="computed_basic.dart"
        code={`final counterAtom = atom(0, name: 'counter');

// Derived value: always 2x the counter
final doubledAtom = computed<int>(
  (read) => read(counterAtom) * 2,
  name: 'doubled',
);

// Usage
store.set(counterAtom, 5);
print(store.get(doubledAtom)); // 10`}
      />

      <Callout type="info" title="Why the type parameter matters">
        Unlike atoms, computed values often require an explicit type parameter.
        When the derivation involves arithmetic or transformations, Dart's type
        inference may not know the result type. For example,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read(counterAtom) * 2</code>{' '}
        returns{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">num</code>{' '}
        unless you annotate the computed as{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed&lt;int&gt;</code>.
        Always provide the type parameter to avoid subtle type errors downstream.
      </Callout>

      <h3 id="computed-read" className="text-xl font-semibold mt-8 mb-3">
        How the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read</code> Function Works
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read</code>{' '}
        function is the key to automatic dependency tracking. Every time your
        derivation calls{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read(someAtom)</code>,
        two things happen simultaneously:
      </p>
      <ol className="list-decimal list-inside space-y-2 text-gray-600 dark:text-gray-400 mb-6 ml-2">
        <li>The current value of <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">someAtom</code> is returned to your function.</li>
        <li>A dependency edge is created from <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">someAtom</code> to this computed node in the reactive graph.</li>
      </ol>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Dependencies are re-evaluated on every recomputation, so conditional reads
        are handled correctly. If a branch of your derivation is not taken, the
        atoms in that branch are not registered as dependencies for this cycle.
      </p>
      <CodeBlock
        title="computed_conditional.dart"
        code={`final showDetailsAtom = atom(false, name: 'showDetails');
final detailsAtom = atom('Detailed info here', name: 'details');
final summaryAtom = atom('Brief summary', name: 'summary');

// Dependencies change based on showDetails value
final displayAtom = computed<String>(
  (read) {
    if (read(showDetailsAtom)) {
      // When showDetails is true, depends on: showDetailsAtom + detailsAtom
      return read(detailsAtom);
    } else {
      // When showDetails is false, depends on: showDetailsAtom + summaryAtom
      return read(summaryAtom);
    }
  },
  name: 'display',
);`}
      />

      <h3 id="computed-chaining" className="text-xl font-semibold mt-8 mb-3">
        Chaining Computed Values
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Computed values can depend on other computed values, forming a chain (or
        more generally, a directed acyclic graph). Reacton handles this correctly:
        when an upstream atom changes, all intermediate computed nodes are
        re-evaluated in topological order before the downstream node runs.
      </p>
      <CodeBlock
        title="computed_chaining.dart"
        code={`final itemsAtom = atom<List<Item>>([], name: 'items');

// Level 1: filter to only completed items
final completedItemsAtom = computed<List<Item>>(
  (read) => read(itemsAtom).where((i) => i.isCompleted).toList(),
  name: 'completedItems',
);

// Level 2: count of completed items (depends on computed, not atom)
final completedCountAtom = computed<int>(
  (read) => read(completedItemsAtom).length,
  name: 'completedCount',
);

// Level 2: total count (depends on the original atom)
final totalCountAtom = computed<int>(
  (read) => read(itemsAtom).length,
  name: 'totalCount',
);

// Level 3: progress string (depends on two other computed values)
final progressAtom = computed<String>(
  (read) {
    final completed = read(completedCountAtom);
    final total = read(totalCountAtom);
    if (total == 0) return 'No items';
    final pct = (completed / total * 100).toStringAsFixed(0);
    return '\$completed / \$total (\$pct%)';
  },
  name: 'progress',
);`}
      />

      <h3 id="computed-multiple-deps" className="text-xl font-semibold mt-8 mb-3">
        Computed with Multiple Dependencies
      </h3>
      <CodeBlock
        title="computed_multi_deps.dart"
        code={`final firstNameAtom = atom('Jane', name: 'firstName');
final lastNameAtom = atom('Doe', name: 'lastName');
final titleAtom = atom<String?>('Dr.', name: 'title');

// Depends on three atoms
final fullNameAtom = computed<String>(
  (read) {
    final title = read(titleAtom);
    final first = read(firstNameAtom);
    final last = read(lastNameAtom);
    if (title != null) return '\$title \$first \$last';
    return '\$first \$last';
  },
  name: 'fullName',
);

// Changing any one of the three atoms triggers recomputation:
store.set(titleAtom, null);
print(store.get(fullNameAtom)); // "Jane Doe"

store.set(firstNameAtom, 'John');
print(store.get(fullNameAtom)); // "John Doe"`}
      />

      <Callout type="tip" title="Lazy evaluation saves work">
        If nothing ever reads a computed value, its derivation function never runs.
        This means you can declare many computed values up front without paying
        any cost until they are actually needed. The first{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.get()</code>{' '}
        or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>{' '}
        call triggers the initial computation; subsequent reads return the cached value
        until a dependency changes.
      </Callout>

      {/* ================================================================== */}
      {/* SELECTORS                                                          */}
      {/* ================================================================== */}
      <h2 id="selectors" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Selectors
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A <strong>selector</strong> extracts a sub-value from an atom and only
        triggers rebuilds when that specific sub-value changes. This is
        critical for performance when you have large state objects but your widget
        only cares about one field.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The factory signature is{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">selector&lt;T, S&gt;(atom, (value) =&gt; subValue)</code>,
        where{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">T</code>{' '}
        is the type of the source atom and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">S</code>{' '}
        is the type of the selected sub-value.
      </p>

      <h3 id="selectors-basic" className="text-xl font-semibold mt-8 mb-3">
        Selecting Fields from Objects
      </h3>
      <CodeBlock
        title="selectors_basic.dart"
        code={`class User {
  final String name;
  final int age;
  final String email;
  final Address address;

  const User({
    required this.name,
    required this.age,
    required this.email,
    required this.address,
  });

  User copyWith({String? name, int? age, String? email, Address? address}) =>
    User(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
      address: address ?? this.address,
    );
}

final userAtom = atom<User>(
  User(name: 'Alice', age: 30, email: 'alice@example.com', address: homeAddr),
  name: 'user',
);

// Only rebuilds widgets watching this when name actually changes
final nameSelector = selector<User, String>(
  userAtom,
  (user) => user.name,
  name: 'userName',
);

// Only rebuilds when age changes
final ageSelector = selector<User, int>(
  userAtom,
  (user) => user.age,
  name: 'userAge',
);

// Only rebuilds when email changes
final emailSelector = selector<User, String>(
  userAtom,
  (user) => user.email,
  name: 'userEmail',
);`}
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Now, if you update only the user's age, only the widget watching{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ageSelector</code>{' '}
        rebuilds. The widgets watching{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">nameSelector</code>{' '}
        and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">emailSelector</code>{' '}
        are not notified because their selected values did not change.
      </p>

      <h3 id="selectors-nested" className="text-xl font-semibold mt-8 mb-3">
        Nested Selectors
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can select deeply nested values. The selector only fires when the
        final extracted value changes, regardless of how deep the path is.
      </p>
      <CodeBlock
        title="selectors_nested.dart"
        code={`class Address {
  final String street;
  final String city;
  final String zipCode;
  const Address({required this.street, required this.city, required this.zipCode});
}

// Deep select: user -> address -> city
final citySelector = selector<User, String>(
  userAtom,
  (user) => user.address.city,
  name: 'userCity',
);

// Changing the user's name does NOT trigger a rebuild of
// widgets watching citySelector, because user.address.city
// hasn't changed.
store.update(userAtom, (u) => u.copyWith(name: 'Bob'));
// citySelector: no notification

// Changing the city DOES trigger it:
store.update(userAtom, (u) => u.copyWith(
  address: Address(street: u.address.street, city: 'Portland', zipCode: u.address.zipCode),
));
// citySelector: notified with 'Portland'`}
      />

      <h3 id="selectors-vs-computed" className="text-xl font-semibold mt-8 mb-3">
        When to Use Selector vs Computed
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Both selectors and computed values produce derived state, but they serve
        different purposes:
      </p>
      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm text-left border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
          <thead className="bg-gray-50 dark:bg-gray-800/50">
            <tr>
              <th className="px-4 py-3 font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">Feature</th>
              <th className="px-4 py-3 font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">Selector</th>
              <th className="px-4 py-3 font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">Computed</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <td className="px-4 py-3 font-medium">Source</td>
              <td className="px-4 py-3">Single atom</td>
              <td className="px-4 py-3">Any number of atoms or computed values</td>
            </tr>
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <td className="px-4 py-3 font-medium">Purpose</td>
              <td className="px-4 py-3">Extract a sub-value (field access)</td>
              <td className="px-4 py-3">Derive a new value (transformation)</td>
            </tr>
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <td className="px-4 py-3 font-medium">Rebuild trigger</td>
              <td className="px-4 py-3">Only when selected sub-value changes</td>
              <td className="px-4 py-3">When any dependency changes</td>
            </tr>
            <tr>
              <td className="px-4 py-3 font-medium">Best for</td>
              <td className="px-4 py-3">Large objects, fine-grained widget access</td>
              <td className="px-4 py-3">Combining state from multiple sources</td>
            </tr>
          </tbody>
        </table>
      </div>

      <Callout type="tip" title="Rule of thumb">
        If you are reading from <em>one</em> atom and plucking out a field, use a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">selector</code>.
        If you are reading from <em>multiple</em> atoms or performing a transformation
        (filtering, sorting, formatting), use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed</code>.
      </Callout>

      {/* ================================================================== */}
      {/* FAMILIES                                                           */}
      {/* ================================================================== */}
      <h2 id="families" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Families
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Families solve the problem of <strong>parameterized state</strong>. When
        you need an atom per entity &mdash; a user profile per user ID, a
        page of results per page number, a form field per field name &mdash;
        you use a family.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The factory signature is{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">family&lt;T, Arg&gt;((arg) =&gt; atom)</code>.
        It accepts a builder function that receives the argument and returns an
        atom. Families <strong>cache instances</strong>: calling the family with
        the same argument always returns the same atom.
      </p>

      <h3 id="families-sync" className="text-xl font-semibold mt-8 mb-3">
        Synchronous Families
      </h3>
      <CodeBlock
        title="families_sync.dart"
        code={`// A family of counter atoms, one per tab
final tabCounterFamily = family<int, String>(
  (tabId) => atom(0, name: 'tabCounter_\$tabId'),
);

// Each call with the same argument returns the same atom
final homeCounter = tabCounterFamily('home');   // atom for 'home'
final searchCounter = tabCounterFamily('search'); // atom for 'search'

// Same argument => same atom instance
assert(identical(tabCounterFamily('home'), homeCounter)); // true

// State is independent per instance
store.set(homeCounter, 5);
store.set(searchCounter, 12);
print(store.get(homeCounter));   // 5
print(store.get(searchCounter)); // 12`}
      />

      <h3 id="families-async" className="text-xl font-semibold mt-8 mb-3">
        Async Families
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Families are especially powerful with async atoms. Each unique parameter
        triggers its own fetch, and the results are cached independently.
      </p>
      <CodeBlock
        title="families_async.dart"
        code={`// Fetch a user profile by ID
final userFamily = family<AsyncValue<User>, int>(
  (userId) => asyncAtom<User>(
    (read) => UserRepository.fetchById(userId),
    name: 'user_\$userId',
  ),
);

// In your widget:
final userAtom = userFamily(42);

// If another widget also calls userFamily(42), it gets
// the SAME atom - no duplicate network request.

// Different ID => different atom => separate fetch
final otherUser = userFamily(99);`}
      />

      <h3 id="families-use-cases" className="text-xl font-semibold mt-8 mb-3">
        Common Use Cases
      </h3>
      <CodeBlock
        title="families_use_cases.dart"
        code={`// Paginated data: one atom per page
final pageFamily = family<AsyncValue<List<Post>>, int>(
  (page) => asyncAtom<List<Post>>(
    (read) => PostApi.getPage(page, perPage: 20),
    name: 'posts_page_\$page',
  ),
);

// Form field state: one atom per field name
final fieldFamily = family<String, String>(
  (fieldName) => atom('', name: 'field_\$fieldName'),
);
final emailField = fieldFamily('email');
final passwordField = fieldFamily('password');

// Feature flags: one atom per flag key
final featureFlagFamily = family<AsyncValue<bool>, String>(
  (flagKey) => asyncAtom<bool>(
    (read) => RemoteConfig.getBool(flagKey),
    name: 'flag_\$flagKey',
    options: AtomOptions(keepAlive: true),
  ),
);`}
      />

      <Callout type="info" title="Instance caching and equality">
        The family uses the argument's{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code>{' '}
        operator and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">hashCode</code>{' '}
        to determine whether to return a cached instance or create a new one.
        For custom argument types, make sure you override{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code>{' '}
        and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">hashCode</code>{' '}
        (or use a value type like a record or freezed class).
      </Callout>

      {/* ================================================================== */}
      {/* EFFECTS                                                            */}
      {/* ================================================================== */}
      <h2 id="effects" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Effects
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        An <strong>effect</strong> is a side-effect function that runs whenever its
        dependencies change. Effects are the bridge between the reactive graph and
        the outside world: logging, persistence, analytics, API calls, and any other
        action that should happen <em>in response to</em> state changes.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Effects are created with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">createEffect(store, (read) =&gt; ...)</code>.
        Like computed, the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read</code>{' '}
        function automatically tracks which atoms the effect depends on.
        Unlike computed, effects are <strong>not cached</strong> and
        <strong> do not return a value</strong> &mdash; they exist solely for
        their side effects.
      </p>

      <h3 id="effects-basic" className="text-xl font-semibold mt-8 mb-3">
        Basic Effect
      </h3>
      <CodeBlock
        title="effects_basic.dart"
        code={`final counterAtom = atom(0, name: 'counter');

// Creates an effect that logs every change
final dispose = createEffect(
  store,
  (read) {
    final count = read(counterAtom);
    print('Counter changed to: \$count');
  },
  name: 'counterLogger',
);

store.set(counterAtom, 1); // prints: Counter changed to: 1
store.set(counterAtom, 2); // prints: Counter changed to: 2

// When you no longer need the effect, dispose it:
dispose();
// Further changes to counterAtom will not trigger the effect`}
      />

      <h3 id="effects-cleanup" className="text-xl font-semibold mt-8 mb-3">
        Cleanup Registration
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Effects can return a cleanup function. This cleanup runs before the effect
        re-executes (when a dependency changes) and when the effect is disposed.
        Use this for cancelling timers, closing streams, or revoking subscriptions.
      </p>
      <CodeBlock
        title="effects_cleanup.dart"
        code={`final queryAtom = atom('', name: 'searchQuery');

final dispose = createEffect(
  store,
  (read) {
    final query = read(queryAtom);

    // Start a debounced search
    final timer = Timer(Duration(milliseconds: 300), () {
      SearchApi.search(query);
    });

    // Return cleanup: cancel the timer if query changes
    // before the 300ms debounce completes
    return () => timer.cancel();
  },
  name: 'searchEffect',
);`}
      />

      <h3 id="effects-persistence" className="text-xl font-semibold mt-8 mb-3">
        Persistence Effect
      </h3>
      <CodeBlock
        title="effects_persistence.dart"
        code={`final themeAtom = atom<ThemeMode>(ThemeMode.system, name: 'theme');

// Persist theme preference to SharedPreferences whenever it changes
final dispose = createEffect(
  store,
  (read) {
    final theme = read(themeAtom);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('theme', theme.name);
    });
  },
  name: 'themePersistence',
);

// On app startup, restore the saved value:
void initializeTheme(ReactonStore store) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme');
  if (saved != null) {
    store.set(themeAtom, ThemeMode.values.byName(saved));
  }
}`}
      />

      <h3 id="effects-api-sync" className="text-xl font-semibold mt-8 mb-3">
        API Synchronization Effect
      </h3>
      <CodeBlock
        title="effects_api_sync.dart"
        code={`final cartItemsAtom = atom<List<CartItem>>([], name: 'cartItems');
final authTokenAtom = atom<String?>(null, name: 'authToken');

// Sync cart to backend whenever items or auth changes
final dispose = createEffect(
  store,
  (read) {
    final items = read(cartItemsAtom);
    final token = read(authTokenAtom);

    // Don't sync if user is not authenticated
    if (token == null) return;

    // Debounce: wait 500ms before syncing
    final timer = Timer(Duration(milliseconds: 500), () async {
      try {
        await CartApi.sync(items, authToken: token);
      } catch (e) {
        print('Cart sync failed: \$e');
      }
    });

    return () => timer.cancel();
  },
  name: 'cartSync',
);`}
      />

      <h3 id="effects-vs-computed" className="text-xl font-semibold mt-8 mb-3">
        Effects vs Computed: When to Use Which
      </h3>
      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm text-left border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
          <thead className="bg-gray-50 dark:bg-gray-800/50">
            <tr>
              <th className="px-4 py-3 font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">Aspect</th>
              <th className="px-4 py-3 font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">Computed</th>
              <th className="px-4 py-3 font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">Effect</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <td className="px-4 py-3 font-medium">Returns a value</td>
              <td className="px-4 py-3">Yes (cached, readable)</td>
              <td className="px-4 py-3">No (fire-and-forget)</td>
            </tr>
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <td className="px-4 py-3 font-medium">Side effects allowed</td>
              <td className="px-4 py-3">No (must be pure)</td>
              <td className="px-4 py-3">Yes (that is their purpose)</td>
            </tr>
            <tr className="border-b border-gray-200 dark:border-gray-700">
              <td className="px-4 py-3 font-medium">Lazy</td>
              <td className="px-4 py-3">Yes (only runs when read)</td>
              <td className="px-4 py-3">No (runs immediately)</td>
            </tr>
            <tr>
              <td className="px-4 py-3 font-medium">Cached</td>
              <td className="px-4 py-3">Yes</td>
              <td className="px-4 py-3">No (re-runs every time)</td>
            </tr>
          </tbody>
        </table>
      </div>

      <Callout type="warning" title="Keep computed functions pure">
        Never perform side effects (HTTP calls, file writes, printing) inside a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed</code>{' '}
        derivation. Computed values may be re-evaluated at any time, and the
        caching logic depends on them being pure functions. Use an{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">effect</code>{' '}
        for side effects instead.
      </Callout>

      {/* ================================================================== */}
      {/* THE REACTIVE GRAPH ENGINE                                          */}
      {/* ================================================================== */}
      <h2 id="reactive-graph" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        The Reactive Graph Engine
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Under the hood, Reacton maintains a <strong>directed acyclic graph (DAG)</strong>{' '}
        of all atoms, computed values, selectors, and effects. This graph is the
        heart of Reacton's reactivity: it knows which nodes depend on which, and it
        uses this information to propagate changes efficiently and correctly.
      </p>

      <h3 id="graph-architecture" className="text-xl font-semibold mt-8 mb-3">
        Architecture Overview
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Every reactive primitive in Reacton becomes a <strong>node</strong> in the graph.
        Edges represent dependencies: if computed{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">B</code>{' '}
        calls{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read(A)</code>,
        there is an edge from{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">A</code>{' '}
        to{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">B</code>.
        Atoms are always <em>source nodes</em> (no incoming edges). Computed values,
        selectors, and effects are <em>derived nodes</em> (they have incoming edges
        from their dependencies).
      </p>

      <h3 id="node-states" className="text-xl font-semibold mt-8 mb-3">
        Node States: Clean, Check, Dirty
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Each derived node in the graph has one of three states at any point in time:
      </p>
      <div className="space-y-4 mb-6">
        <div className="flex gap-4 p-4 rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
          <div className="flex-shrink-0 px-3 py-1 rounded-full bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-sm font-bold font-mono self-start mt-0.5">
            Clean
          </div>
          <p className="text-gray-600 dark:text-gray-400 mb-0 leading-relaxed">
            The node's cached value is up to date. No dependencies have changed since the last computation.
            Reading this node returns the cached value immediately with no work.
          </p>
        </div>
        <div className="flex gap-4 p-4 rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
          <div className="flex-shrink-0 px-3 py-1 rounded-full bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400 text-sm font-bold font-mono self-start mt-0.5">
            Check
          </div>
          <p className="text-gray-600 dark:text-gray-400 mb-0 leading-relaxed">
            A transitive dependency <em>may</em> have changed. The node needs to verify
            whether its <em>direct</em> sources actually produced new values before
            deciding whether to recompute. This is the key to avoiding unnecessary work.
          </p>
        </div>
        <div className="flex gap-4 p-4 rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
          <div className="flex-shrink-0 px-3 py-1 rounded-full bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 text-sm font-bold font-mono self-start mt-0.5">
            Dirty
          </div>
          <p className="text-gray-600 dark:text-gray-400 mb-0 leading-relaxed">
            A direct dependency has definitely changed. The node must recompute its
            value. After recomputation, it transitions back to Clean.
          </p>
        </div>
      </div>

      <h3 id="two-phase-algorithm" className="text-xl font-semibold mt-8 mb-3">
        The Two-Phase Propagation Algorithm
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When an atom's value is set, Reacton does <strong>not</strong> immediately
        recompute all dependents. Instead, it runs a carefully ordered two-phase
        algorithm that guarantees correctness while minimizing work.
      </p>

      <div className="space-y-4 mb-6">
        <div className="flex gap-4 p-4 rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
          <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center text-white text-sm font-bold">
            1
          </div>
          <div>
            <h4 className="text-lg font-semibold mt-0 mb-1 text-gray-900 dark:text-white">Mark Phase</h4>
            <p className="text-gray-600 dark:text-gray-400 mb-2 leading-relaxed">
              Starting from the changed atom, walk the graph downward (toward dependents).
              The direct children of the changed atom are marked <strong>Dirty</strong>.
              All further descendants (grandchildren, great-grandchildren, etc.) are marked <strong>Check</strong>.
            </p>
            <p className="text-gray-600 dark:text-gray-400 mb-0 leading-relaxed">
              This is a fast, shallow traversal. No values are read or computed during
              this phase &mdash; it is purely bookkeeping. The purpose is to record which
              parts of the graph <em>might</em> need updating.
            </p>
          </div>
        </div>
        <div className="flex gap-4 p-4 rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
          <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center text-white text-sm font-bold">
            2
          </div>
          <div>
            <h4 className="text-lg font-semibold mt-0 mb-1 text-gray-900 dark:text-white">Update Phase</h4>
            <p className="text-gray-600 dark:text-gray-400 mb-2 leading-relaxed">
              Process nodes in <strong>topological order</strong> (parents before children).
              For each node:
            </p>
            <ul className="list-disc list-inside space-y-1 text-gray-600 dark:text-gray-400 mb-2 ml-2">
              <li>If the node is <strong>Dirty</strong>: recompute its value unconditionally. If the new value differs from the old value, mark its children as Dirty. Otherwise, mark them back to Clean.</li>
              <li>If the node is <strong>Check</strong>: first, recursively ensure all of its direct sources are up to date. If none of the sources actually produced a new value, transition to Clean without recomputing. If any source did produce a new value, transition to Dirty and recompute.</li>
            </ul>
            <p className="text-gray-600 dark:text-gray-400 mb-0 leading-relaxed">
              After processing, every node in the affected subgraph is back to the Clean state.
            </p>
          </div>
        </div>
      </div>

      <h3 id="diamond-problem" className="text-xl font-semibold mt-8 mb-3">
        The Diamond Problem
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The diamond problem is the classic challenge in reactive systems. Consider
        four nodes with this dependency structure:
      </p>

      <div className="my-6 p-6 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50 font-mono text-sm text-center text-gray-700 dark:text-gray-300">
        <pre className="inline-block text-left leading-relaxed">
{`        A  (atom)
       / \\
      B   C  (computed)
       \\ /
        D  (computed)

  A changes -> B depends on A
               C depends on A
               D depends on B AND C`}
        </pre>
      </div>

      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <strong>The problem:</strong> When{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">A</code>{' '}
        changes, a naive push-based system would first update{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">B</code>,
        which triggers{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">D</code>{' '}
        to recompute. Then it updates{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">C</code>,
        which triggers{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">D</code>{' '}
        to recompute <em>again</em>. This means{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">D</code>{' '}
        computes twice, and worse, the first computation uses a stale value of{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">C</code>{' '}
        (before{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">C</code>{' '}
        has been updated) &mdash; a <em>glitch</em>.
      </p>

      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <strong>How Reacton solves it:</strong>
      </p>
      <ol className="list-decimal list-inside space-y-2 text-gray-600 dark:text-gray-400 mb-6 ml-2">
        <li>
          <strong>Mark phase:</strong>{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">A</code>{' '}
          changes.{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">B</code>{' '}
          and{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">C</code>{' '}
          are marked <strong>Dirty</strong>.{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">D</code>{' '}
          is marked <strong>Check</strong>.
        </li>
        <li>
          <strong>Update phase (topological order):</strong>{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">B</code>{' '}
          is processed first (Dirty, so it recomputes). Then{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">C</code>{' '}
          is processed (Dirty, recomputes). Finally{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">D</code>{' '}
          is processed (Check &rarr; verifies sources changed &rarr; recomputes exactly <strong>once</strong> with fully up-to-date values from both{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">B</code>{' '}
          and{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">C</code>).
        </li>
      </ol>

      <CodeBlock
        title="diamond_example.dart"
        code={`final a = atom(1, name: 'A');

final b = computed<int>(
  (read) => read(a) * 10,
  name: 'B',
);

final c = computed<int>(
  (read) => read(a) + 1,
  name: 'C',
);

// D depends on both B and C - a diamond
final d = computed<String>(
  (read) => 'B=\${read(b)}, C=\${read(c)}',
  name: 'D',
);

print(store.get(d)); // "B=10, C=2"

// Change A: D will compute exactly ONCE, not twice
store.set(a, 5);
print(store.get(d)); // "B=50, C=6" - correct, glitch-free`}
      />

      <Callout type="info" title="Glitch-free guarantee">
        The two-phase algorithm guarantees that every derived node sees a
        <strong> consistent</strong> snapshot of its dependencies. No node ever
        observes a "half-updated" state where some of its sources have been
        updated and others have not. This eliminates an entire class of bugs
        that plague simpler reactive systems.
      </Callout>

      <h3 id="batching" className="text-xl font-semibold mt-8 mb-3">
        Synchronous Batching
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton uses <strong>synchronous batching</strong> rather than microtask-based
        batching. Multiple{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.set()</code>{' '}
        calls within the same synchronous block are automatically batched: the mark
        and update phases run once after all the sets complete, not once per set.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can also use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.batch()</code>{' '}
        for explicit batching when you want to guarantee that multiple mutations
        are treated as a single atomic operation:
      </p>
      <CodeBlock
        title="batching.dart"
        code={`// These three sets produce only ONE notification cycle
store.batch(() {
  store.set(firstNameAtom, 'John');
  store.set(lastNameAtom, 'Doe');
  store.set(ageAtom, 42);
});
// All subscribers and effects fire once here,
// seeing the final state of all three atoms.`}
      />

      <h3 id="epoch-tracking" className="text-xl font-semibold mt-8 mb-3">
        Epoch-Based Change Tracking
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton uses an <strong>epoch counter</strong> to track changes efficiently.
        Every time an atom is set, the store increments a global epoch number and
        stamps the atom with it. When a Check node needs to verify whether its
        source changed, it compares the source's epoch against its own recorded
        epoch &mdash; a single integer comparison instead of a deep value comparison.
        This makes the verification step in the update phase extremely fast.
      </p>

      <h3 id="performance" className="text-xl font-semibold mt-8 mb-3">
        Performance Characteristics
      </h3>
      <ul className="list-disc list-inside space-y-2 text-gray-600 dark:text-gray-400 mb-6 ml-2">
        <li><strong>Mark phase:</strong> O(number of descendants of the changed atom). No recomputation, just flag-setting.</li>
        <li><strong>Update phase:</strong> O(number of nodes that actually need recomputation). Check nodes that discover their sources did not truly change short-circuit immediately.</li>
        <li><strong>Memory:</strong> Each node stores a small fixed overhead (state flag, epoch, dependency list). The graph structure uses adjacency lists.</li>
        <li><strong>No microtask overhead:</strong> Everything runs synchronously in the same event-loop turn. No <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Future.microtask</code> or <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">scheduleMicrotask</code> delays.</li>
      </ul>

      {/* ================================================================== */}
      {/* PULSE STORE                                                        */}
      {/* ================================================================== */}
      <h2 id="store" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        ReactonStore
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonStore</code>{' '}
        is the central runtime container that owns the reactive graph, manages atom
        values, tracks subscriptions, and coordinates batching and snapshots. In most
        applications you create a single store and provide it to the widget tree via{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonProvider</code>.
      </p>

      <h3 id="store-create" className="text-xl font-semibold mt-8 mb-3">
        Creating and Configuring a Store
      </h3>
      <CodeBlock
        title="store_create.dart"
        code={`// Basic store
final store = ReactonStore();

// Store with debug name (appears in devtools)
final store = ReactonStore(name: 'appStore');

// Providing the store to the widget tree
void main() {
  final store = ReactonStore(name: 'app');

  runApp(
    ReactonProvider(
      store: store,
      child: MyApp(),
    ),
  );
}`}
      />

      <h3 id="store-read-write" className="text-xl font-semibold mt-8 mb-3">
        Reading and Writing State
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The store provides three core methods for interacting with atom values:
      </p>
      <CodeBlock
        title="store_read_write.dart"
        code={`final counterAtom = atom(0, name: 'counter');
final store = ReactonStore();

// get: read the current value
final value = store.get(counterAtom); // 0

// set: replace the value entirely
store.set(counterAtom, 42);
print(store.get(counterAtom)); // 42

// update: transform the current value with a function
store.update(counterAtom, (current) => current + 1);
print(store.get(counterAtom)); // 43

// update is especially useful for collections:
final todosAtom = atom<List<String>>([], name: 'todos');
store.update(todosAtom, (list) => [...list, 'New todo']);
store.update(todosAtom, (list) => list.where((t) => t != 'New todo').toList());`}
      />

      <h3 id="store-subscribe" className="text-xl font-semibold mt-8 mb-3">
        Subscribing to Changes
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.subscribe()</code>{' '}
        to listen for changes to any atom, computed value, or selector. It returns
        an unsubscribe function that you should call when the listener is no longer
        needed.
      </p>
      <CodeBlock
        title="store_subscribe.dart"
        code={`final counterAtom = atom(0, name: 'counter');

// Subscribe to changes
final unsubscribe = store.subscribe(counterAtom, (value) {
  print('Counter is now: \$value');
});

store.set(counterAtom, 1); // prints: Counter is now: 1
store.set(counterAtom, 2); // prints: Counter is now: 2

// Stop listening
unsubscribe();
store.set(counterAtom, 3); // nothing printed

// Subscribe to computed values too
final doubledAtom = computed<int>(
  (read) => read(counterAtom) * 2,
  name: 'doubled',
);

final unsub2 = store.subscribe(doubledAtom, (value) {
  print('Doubled is now: \$value');
});`}
      />

      <h3 id="store-batch" className="text-xl font-semibold mt-8 mb-3">
        Explicit Batching
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        While Reacton batches updates automatically within the same synchronous block,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.batch()</code>{' '}
        gives you explicit control. All mutations inside the batch callback are
        collected, and the reactive graph is updated exactly once when the callback
        returns.
      </p>
      <CodeBlock
        title="store_batch.dart"
        code={`// Without batch: each set triggers a separate update cycle
store.set(nameAtom, 'Alice');     // cycle 1
store.set(emailAtom, 'a@b.com'); // cycle 2
store.set(ageAtom, 30);          // cycle 3

// With batch: all three are committed as one atomic update
store.batch(() {
  store.set(nameAtom, 'Alice');
  store.set(emailAtom, 'a@b.com');
  store.set(ageAtom, 30);
}); // single cycle, all subscribers notified once

// batch() returns the value of the callback, so you can use it like:
final result = store.batch(() {
  store.set(atomA, 10);
  store.set(atomB, 20);
  return store.get(atomA) + store.get(atomB);
}); // result == 30`}
      />

      <h3 id="store-snapshots" className="text-xl font-semibold mt-8 mb-3">
        Snapshots and Restoration
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton supports taking <strong>snapshots</strong> of the entire store state
        and restoring them later. This is useful for implementing undo/redo,
        time-travel debugging, or persisting the full application state.
      </p>
      <CodeBlock
        title="store_snapshots.dart"
        code={`final store = ReactonStore();
final counterAtom = atom(0, name: 'counter');
final nameAtom = atom('Alice', name: 'name');

store.set(counterAtom, 5);
store.set(nameAtom, 'Bob');

// Capture the current state
final snapshot = store.snapshot();
// snapshot is a Map<AtomRef, dynamic> of all atom values

// Make further changes
store.set(counterAtom, 100);
store.set(nameAtom, 'Charlie');

print(store.get(counterAtom)); // 100
print(store.get(nameAtom));    // Charlie

// Restore the snapshot: all atoms revert
store.restore(snapshot);

print(store.get(counterAtom)); // 5
print(store.get(nameAtom));    // Bob

// Undo/redo implementation sketch:
class UndoManager {
  final ReactonStore store;
  final List<Map<AtomRef, dynamic>> _history = [];
  int _index = -1;

  UndoManager(this.store);

  void save() {
    _history.removeRange(_index + 1, _history.length);
    _history.add(store.snapshot());
    _index++;
  }

  void undo() {
    if (_index > 0) {
      _index--;
      store.restore(_history[_index]);
    }
  }

  void redo() {
    if (_index < _history.length - 1) {
      _index++;
      store.restore(_history[_index]);
    }
  }
}`}
      />

      <h3 id="store-scoping" className="text-xl font-semibold mt-8 mb-3">
        Hierarchical Scoping
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        For advanced scenarios, you can create <strong>multiple stores</strong> and
        nest them in the widget tree. A child{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonProvider</code>{' '}
        can override specific atoms for its subtree while inheriting everything else
        from the parent store. This is useful for per-page state, modal dialogs with
        their own state scope, or testing.
      </p>
      <CodeBlock
        title="store_scoping.dart"
        code={`// Root store: global app state
final rootStore = ReactonStore(name: 'root');

// Child store: scoped to a specific feature
final featureStore = ReactonStore(name: 'feature');

Widget build(BuildContext context) {
  return ReactonProvider(
    store: rootStore,
    child: MaterialApp(
      home: ReactonProvider(
        store: featureStore,
        // Widgets in this subtree read from featureStore first,
        // falling back to rootStore for atoms not in featureStore.
        child: FeaturePage(),
      ),
    ),
  );
}`}
      />

      <h3 id="store-lifecycle" className="text-xl font-semibold mt-8 mb-3">
        Store Lifecycle and Disposal
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When a store is no longer needed, call{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.dispose()</code>{' '}
        to clean up all subscriptions, cancel all effects, and release all atom values.
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonProvider</code>{' '}
        widget handles this automatically when it is removed from the widget tree.
      </p>
      <CodeBlock
        title="store_dispose.dart"
        code={`final store = ReactonStore(name: 'temp');

// Use the store...
store.set(counterAtom, 1);
final unsub = store.subscribe(counterAtom, (v) => print(v));

// When done, dispose everything:
store.dispose();
// All subscriptions cancelled
// All effects stopped and their cleanup functions invoked
// All atom values released (unless keepAlive)`}
      />

      <Callout type="tip" title="One store per app is usually enough">
        Most Flutter apps only need a single{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonStore</code>.
        Multiple stores add complexity and make it harder to share state across
        features. Only use multiple stores when you have a genuine need for
        state isolation, such as independent feature modules or testing scenarios.
      </Callout>

      {/* ================================================================== */}
      {/* STATE LIFECYCLE                                                    */}
      {/* ================================================================== */}
      <h2 id="state-lifecycle" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        State Lifecycle
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Understanding when atoms are initialized, when their values are retained,
        and when they are disposed is critical for building efficient applications.
        Reacton follows a lifecycle model designed to balance memory efficiency with
        developer convenience.
      </p>

      <h3 id="lifecycle-initialization" className="text-xl font-semibold mt-8 mb-3">
        Atom Initialization (Lazy on First Read)
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Atoms are <strong>lazily initialized</strong>. Declaring an atom at the top
        level of a Dart file does <em>not</em> allocate any memory in the store.
        The atom's initial value is only materialized when the store first encounters
        it &mdash; that is, when{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.get()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.set()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.subscribe()</code>,
        or a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>{' '}
        call inside a computed or effect first references the atom.
      </p>
      <CodeBlock
        title="lifecycle_init.dart"
        code={`// This line runs at import time, but NO state is allocated yet.
// The atom() call just creates an AtomRef descriptor.
final heavyAtom = atom<ExpensiveObject>(
  ExpensiveObject.create(), // constructor runs only on first read!
  name: 'heavy',
);

// Later, when a widget first mounts and reads heavyAtom:
// 1. Store sees this AtomRef for the first time
// 2. Evaluates the initial value (ExpensiveObject.create())
// 3. Stores the value internally
// 4. Returns it to the widget`}
      />

      <Callout type="info" title="Initial value evaluation">
        The initial value expression passed to{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom()</code>{' '}
        is evaluated once when the Dart file is loaded (it is a top-level expression),
        but the store does not intern or track it until the first access. For truly
        lazy initialization of expensive values, consider wrapping the atom in a
        factory or using an async atom.
      </Callout>

      <h3 id="lifecycle-subscriptions" className="text-xl font-semibold mt-8 mb-3">
        Subscription Tracking
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The store maintains a reference count of active subscribers for each atom.
        Subscribers include:
      </p>
      <ul className="list-disc list-inside space-y-2 text-gray-600 dark:text-gray-400 mb-6 ml-2">
        <li>Widgets using <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomBuilder</code>, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomListener</code>, or the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">useAtom</code> hook.</li>
        <li>Manual <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.subscribe()</code> calls.</li>
        <li>Computed values and effects that <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code> the atom.</li>
      </ul>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When a widget unmounts, its subscription is automatically removed. When
        an effect is disposed, its subscription is removed. This reference counting
        drives the auto-dispose behavior described below.
      </p>

      <h3 id="lifecycle-auto-dispose" className="text-xl font-semibold mt-8 mb-3">
        Auto-Dispose Behavior
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        By default, when an atom's subscriber count drops to zero (the last widget
        watching it unmounts and no effects or computed values reference it), the
        atom's value is <strong>disposed</strong> &mdash; removed from the store's
        internal map. The next time something reads the atom, it is re-initialized
        from its initial value, as if it were being read for the first time.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        This automatic cleanup keeps memory usage proportional to the atoms actually
        in use by the current UI, which is important for large applications with
        many possible screens.
      </p>
      <CodeBlock
        title="lifecycle_auto_dispose.dart"
        code={`final pageDataAtom = atom<PageData?>(null, name: 'pageData');

// User navigates to PageA:
//   - AtomBuilder mounts, subscribes to pageDataAtom
//   - Store initializes pageDataAtom with null
//   - Widget loads data, sets pageDataAtom to fetched data

// User navigates away from PageA:
//   - AtomBuilder unmounts, unsubscribes
//   - Subscriber count drops to 0
//   - Store auto-disposes: pageDataAtom value removed from memory

// User navigates back to PageA:
//   - AtomBuilder mounts again, subscribes
//   - Store re-initializes pageDataAtom to null (initial value)
//   - Widget loads data again`}
      />

      <h3 id="lifecycle-keep-alive" className="text-xl font-semibold mt-8 mb-3">
        keepAlive: Preventing Disposal
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Set{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">keepAlive: true</code>{' '}
        in{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomOptions</code>{' '}
        to prevent auto-disposal. The atom's value persists in the store for the
        lifetime of the store, regardless of whether any widget is watching it.
        Use this for state that is expensive to initialize, state that must survive
        navigation, or global configuration.
      </p>
      <CodeBlock
        title="lifecycle_keep_alive.dart"
        code={`// Auth token: must survive screen transitions
final authTokenAtom = atom<String?>(
  null,
  name: 'authToken',
  options: AtomOptions(keepAlive: true),
);

// User preferences: expensive to load from disk
final preferencesAtom = atom<UserPreferences>(
  UserPreferences.defaults(),
  name: 'preferences',
  options: AtomOptions(keepAlive: true),
);

// Shopping cart: must persist across navigation
final cartAtom = atom<List<CartItem>>(
  [],
  name: 'cart',
  options: AtomOptions(
    keepAlive: true,
    equals: const ListEquality<CartItem>().equals,
  ),
);

// Contrast with disposable state:
// Search results for a specific page - can be re-fetched, so no keepAlive
final searchResultsAtom = atom<List<Result>>(
  [],
  name: 'searchResults',
  // keepAlive defaults to false: auto-disposed when unmounted
);`}
      />

      <Callout type="warning" title="Use keepAlive judiciously">
        Every{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">keepAlive</code>{' '}
        atom holds its value in memory for the entire app session. Overusing it
        defeats the purpose of auto-dispose and can lead to increased memory
        consumption. Reserve it for truly global or expensive-to-reconstruct state.
      </Callout>

      <h3 id="lifecycle-summary" className="text-xl font-semibold mt-8 mb-3">
        Lifecycle Summary
      </h3>
      <div className="my-6 p-6 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50 font-mono text-sm text-center text-gray-700 dark:text-gray-300">
        <pre className="inline-block text-left leading-relaxed">
{`  atom() called         AtomRef created (lightweight descriptor)
       |
       v
  First read/subscribe  Value initialized in store
       |
       v
  Active use            Value updated via set()/update()
       |                Subscribers notified on change
       v
  Last unsubscribe      ── keepAlive: true ──> Value retained
       |
       └── keepAlive: false (default) ──> Value disposed
                                              |
                                              v
                                         Next read re-initializes`}
        </pre>
      </div>

      <PageNav
        prev={{ title: 'Getting Started', path: '/getting-started' }}
        next={{ title: 'Flutter Widgets', path: '/flutter-widgets' }}
      />
    </div>
  )
}
