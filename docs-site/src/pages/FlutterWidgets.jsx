import CodeBlock from '../components/CodeBlock'
import Callout from '../components/Callout'
import PageNav from '../components/PageNav'

export default function FlutterWidgets() {
  return (
    <div>
      <h1 className="text-4xl font-extrabold tracking-tight mb-4">Flutter Widgets</h1>
      <p className="text-lg text-gray-500 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton provides a rich set of reactive widgets and context extensions that integrate
        seamlessly with Flutter's widget tree. Every piece of UI that depends on state is
        automatically tracked, efficiently rebuilt, and cleanly disposed when no longer needed.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-8 leading-relaxed">
        This page is your comprehensive guide to every widget and extension Reacton offers. You will
        learn when to reach for each one, how they differ in rebuild scope and performance
        characteristics, and how to combine them in real-world applications.
      </p>

      {/* ================================================================ */}
      {/* SECTION 1 - ReactonScope                                          */}
      {/* ================================================================ */}
      <h2 id="reacton-scope" className="text-2xl font-bold mt-12 mb-4">
        ReactonScope
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code> is
        the root of every Reacton-powered application. It is an{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">InheritedWidget</code> that
        holds a reference to a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonStore</code> and
        exposes it to every descendant in the widget tree. Without a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code> above
        your widgets, calls like{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code> and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read()</code> will
        throw a runtime error because there is no store to subscribe to.
      </p>

      <h3 id="reacton-scope-basic-setup" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Basic Setup
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The most common pattern is wrapping your entire{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MaterialApp</code> (or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">CupertinoApp</code>)
        inside a single{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>.
        This gives every route and widget access to the same store instance.
      </p>
      <CodeBlock
        title="main.dart"
        code={`import 'package:flutter/material.dart';
import 'package:reacton/reacton.dart';

// Define atoms at the top level
final counterAtom = atom(0);
final nameAtom = atom('Guest');

void main() {
  runApp(
    ReactonScope(
      store: ReactonStore(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Demo',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}`}
      />

      <h3 id="reacton-scope-accessing-store" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Accessing the Store Directly
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        While context extensions (covered below) are the recommended way to read and write atoms,
        you can also grab the raw{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonStore</code> instance
        via{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope.of(context)</code>.
        This is useful when you need to call store-level APIs such as{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.dispatch()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.batch()</code>, or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.reset()</code>.
      </p>
      <CodeBlock
        title="Accessing the store"
        code={`class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Grab the raw store for advanced operations
        final store = ReactonScope.of(context);

        // Batch multiple updates into a single notification cycle
        store.batch(() {
          store.set(counterAtom, 0);
          store.set(nameAtom, 'Guest');
        });
      },
      child: const Text('Reset All'),
    );
  }
}`}
      />

      <h3 id="reacton-scope-nested" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Nested Scopes for Module Isolation
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        In large applications you may want separate stores for independent feature modules. You can
        nest{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code> widgets
        to create isolated state boundaries. Descendant widgets always resolve the nearest{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code> above
        them in the tree.
      </p>
      <CodeBlock
        title="Nested scopes"
        code={`// Root scope - global state (auth, theme, locale)
ReactonScope(
  store: globalStore,
  child: MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          // This widget reads from globalStore
          const GlobalHeader(),

          // Nested scope - chat feature has its own store
          ReactonScope(
            store: chatStore,
            child: const ChatModule(),
            // ChatModule and its descendants read from chatStore.
            // If ChatModule needs global state, it must use a
            // different mechanism (e.g. pass it down or use a
            // service locator).
          ),
        ],
      ),
    ),
  ),
)`}
      />
      <Callout type="info" title="When to create multiple stores">
        Most applications only need a <strong>single store</strong>. Consider multiple stores only
        when you have a truly independent feature module (e.g., an embedded mini-app, a plugin
        system, or a multi-tenant setup). Using a single store keeps cross-feature derived atoms
        simple and avoids the complexity of passing data between stores.
      </Callout>

      {/* ================================================================ */}
      {/* SECTION 2 - Context Extensions                                   */}
      {/* ================================================================ */}
      <h2 id="context-extensions" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Context Extensions
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton extends{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">BuildContext</code> with
        four ergonomic methods that cover 90% of state interactions in Flutter. These extensions are
        the simplest and most idiomatic way to work with Reacton. No special wrapper widgets are
        required -- just call the method on your existing{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context</code>.
      </p>

      {/* --- context.watch --- */}
      <h3 id="context-watch" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch(atom)</code> -- Reactive Reads
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch(atom)</code> returns
        the atom's current value <strong>and</strong> subscribes the enclosing widget to future
        changes. Whenever the atom's value changes (determined by value equality,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code>), Flutter
        marks the widget as dirty and schedules a rebuild.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Key characteristics:
      </p>
      <ul className="list-disc pl-6 space-y-2 text-gray-600 dark:text-gray-400 mb-4">
        <li>
          <strong className="text-gray-900 dark:text-white">Fine-grained subscriptions.</strong>{' '}
          Only widgets that call{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch(counterAtom)</code> rebuild
          when{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">counterAtom</code> changes.
          Sibling widgets watching different atoms are unaffected.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Value equality check.</strong>{' '}
          If you set an atom to a value that is{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code> to its
          current value, no rebuild is triggered.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Multiple watches per build.</strong>{' '}
          You can call{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch()</code> on
          multiple atoms in the same{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code> method.
          Each call creates a separate subscription. The widget rebuilds when <em>any</em> of
          its watched atoms change.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Automatic cleanup.</strong>{' '}
          When the widget is disposed, all subscriptions created by{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch()</code> are
          removed. You never need to manually unsubscribe.
        </li>
      </ul>
      <CodeBlock
        title="context.watch() example"
        code={`class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribes this widget to counterAtom.
    // Whenever counterAtom changes, only this widget rebuilds.
    final count = context.watch(counterAtom);

    // You can watch multiple atoms in the same build.
    final label = context.watch(labelAtom);

    return Text('$label: $count');
  }
}`}
      />

      <Callout type="tip" title="Performance">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code> rebuilds
        the <em>entire</em> widget that calls it (i.e., the nearest{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">StatelessWidget</code> or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">State.build()</code>).
        If you need to confine rebuilds to a smaller subtree, use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code> instead.
      </Callout>

      {/* --- context.read --- */}
      <h3 id="context-read" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read(atom)</code> -- One-Time Reads
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read(atom)</code> returns
        the atom's current value <strong>without</strong> subscribing. The widget will{' '}
        <strong>not</strong> rebuild when this atom changes.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code> inside
        event handlers, callbacks, and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onPressed</code> /
        {' '}<code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onTap</code> closures
        where you need the value at the moment the user interacts, but you do not want the
        widget to re-render every time that atom changes.
      </p>
      <CodeBlock
        title="context.read() example"
        code={`class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    // DO NOT use read() here -- the button label would never update.
    // Use watch() for anything that should appear in the UI.
    final isLoading = context.watch(isLoadingAtom);

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              // CORRECT: read() inside a callback.
              // We need the current value at tap time, not a subscription.
              final formData = context.read(formDataAtom);
              final store = ReactonScope.of(context);
              store.dispatch(SubmitFormAction(formData));
            },
      child: isLoading
          ? const CircularProgressIndicator()
          : const Text('Submit'),
    );
  }
}`}
      />
      <Callout type="danger" title="Common mistake: read() in build()">
        Calling{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read(atom)</code> directly
        inside{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code> to
        render UI text is a bug. Because{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code> does
        not subscribe, the widget will display a stale value after the atom changes. Always
        use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code> for
        any value that is rendered on screen.
      </Callout>

      {/* --- context.set --- */}
      <h3 id="context-set" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set(atom, value)</code> -- Direct Value Setting
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set(atom, value)</code> replaces
        the atom's current value entirely. After the value is set, all widgets that are watching
        this atom (and any derived/computed atoms that depend on it) are notified and will rebuild
        on the next frame.
      </p>
      <CodeBlock
        title="context.set() example"
        code={`ElevatedButton(
  onPressed: () {
    // Replace the counter's value with 0
    context.set(counterAtom, 0);

    // Replace the user's name
    context.set(nameAtom, 'Alice');

    // Replace an entire list (creates a new list reference)
    context.set(todosAtom, <Todo>[]);
  },
  child: const Text('Reset'),
)`}
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Because Reacton uses value equality ({' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code>{' '}
        ), calling{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set(counterAtom, 5)</code> when
        the counter is already{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">5</code> is a
        no-op -- no notifications are sent and no rebuilds occur.
      </p>

      {/* --- context.update --- */}
      <h3 id="context-update" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update(atom, fn)</code> -- Functional Updates
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update(atom, (current) =&gt; newValue)</code> reads
        the current value, passes it to your transformation function, and sets the atom to the
        returned value. This is the preferred approach when the new value depends on the old value
        because it avoids stale-closure bugs -- you always operate on the latest state.
      </p>
      <CodeBlock
        title="context.update() example"
        code={`// Increment a counter
context.update(counterAtom, (n) => n + 1);

// Toggle a boolean
context.update(isDarkModeAtom, (dark) => !dark);

// Add an item to an immutable list
context.update(todosAtom, (todos) => [
  ...todos,
  Todo(title: 'Buy groceries', done: false),
]);

// Remove completed items
context.update(todosAtom, (todos) =>
  todos.where((t) => !t.done).toList(),
);`}
      />
      <Callout type="tip" title="Why update() instead of read() + set()?">
        You <em>could</em> write{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set(atom, context.read(atom) + 1)</code>,
        but{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update()</code> is
        safer. In rapid-fire scenarios (e.g., fast button taps), the closure passed to{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update()</code> always
        receives the latest committed value, eliminating race conditions caused by stale reads.
      </Callout>

      {/* Summary table for context extensions */}
      <h3 id="context-extensions-summary" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Context Extensions at a Glance
      </h3>
      <div className="my-6 overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Method</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Returns</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Subscribes?</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Use In</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch(atom)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Current value</td>
              <td className="px-4 py-3 text-green-600 dark:text-green-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code></td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read(atom)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Current value</td>
              <td className="px-4 py-3 text-red-600 dark:text-red-400">No</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Callbacks, event handlers</td>
            </tr>
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set(atom, val)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">void</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">N/A</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Anywhere</td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update(atom, fn)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">void</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">N/A</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Anywhere (best for derived updates)</td>
            </tr>
          </tbody>
        </table>
      </div>

      {/* ================================================================ */}
      {/* SECTION 3 - ReactonBuilder                                         */}
      {/* ================================================================ */}
      <h2 id="reacton-builder" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        ReactonBuilder
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> is
        a single-atom scoped-rebuild widget. It watches exactly one atom and only rebuilds the
        subtree returned by its{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">builder</code> callback.
        The parent widget that contains the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> is <strong>not</strong> rebuilt.
      </p>

      <h3 id="reacton-builder-props" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Props
      </h3>
      <div className="my-6 overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Prop</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Type</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Required</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Atom&lt;T&gt;</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">The atom to watch.</td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">builder</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Widget Function(BuildContext, T)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Builds the subtree with the current atom value.</td>
            </tr>
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">buildWhen</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">bool Function(T prev, T next)?</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">No</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">When provided, the builder only re-executes if this returns <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">true</code>.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 id="reacton-builder-when-to-use" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        When to Use ReactonBuilder
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> when
        you want to isolate rebuilds to a small portion of a larger widget tree. With{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>,
        the entire{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code> method
        reruns. With{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>,
        only the builder callback reruns, leaving the rest of the parent widget untouched. This
        matters in performance-sensitive screens where the parent builds an expensive layout
        (e.g., a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Scaffold</code> with
        an{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AppBar</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Drawer</code>, and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">BottomNavigationBar</code>).
      </p>
      <CodeBlock
        title="ReactonBuilder basic usage"
        code={`class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This build() does NOT watch any atoms, so it never
    // rebuilds due to state changes. Only the ReactonBuilder
    // subtrees below will rebuild.

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Column(
        children: [
          // Only this Text rebuilds when counterAtom changes
          ReactonBuilder<int>(
            atom: counterAtom,
            builder: (context, count) {
              return Text(
                'Count: \$count',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            },
          ),

          const SizedBox(height: 16),

          // Only this Text rebuilds when nameAtom changes
          ReactonBuilder<String>(
            atom: nameAtom,
            builder: (context, name) {
              return Text('Hello, \$name');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.update(counterAtom, (n) => n + 1),
        child: const Icon(Icons.add),
      ),
    );
  }
}`}
      />

      <h3 id="reacton-builder-build-when" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Conditional Rebuilds with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">buildWhen</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The optional{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">buildWhen</code> callback
        receives the previous and next values. If it returns{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">false</code>, the
        builder is not re-invoked and the previous widget tree is reused. This is useful
        when you only care about certain transitions.
      </p>
      <CodeBlock
        title="buildWhen example"
        code={`// Only rebuild when the count crosses a multiple of 10
ReactonBuilder<int>(
  atom: counterAtom,
  buildWhen: (prev, next) => (next ~/ 10) != (prev ~/ 10),
  builder: (context, count) {
    return Text('Milestone: \${(count ~/ 10) * 10}');
  },
)

// Only rebuild when the status changes, not the message
ReactonBuilder<RequestState>(
  atom: requestAtom,
  buildWhen: (prev, next) => prev.status != next.status,
  builder: (context, state) {
    return switch (state.status) {
      Status.idle => const SizedBox.shrink(),
      Status.loading => const CircularProgressIndicator(),
      Status.success => const Icon(Icons.check, color: Colors.green),
      Status.error => const Icon(Icons.error, color: Colors.red),
    };
  },
)`}
      />
      <Callout type="warning" title="When NOT to use ReactonBuilder">
        If you need to watch <strong>multiple atoms</strong> in the same builder, use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code> instead.{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> accepts
        only a single atom. Nesting multiple{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> widgets
        works but quickly becomes hard to read.
      </Callout>

      {/* ================================================================ */}
      {/* SECTION 4 - ReactonConsumer                                        */}
      {/* ================================================================ */}
      <h2 id="reacton-consumer" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        ReactonConsumer
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code> is
        the multi-atom counterpart to{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>.
        Its builder receives a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ref</code> object
        that lets you{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch()</code> and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code> any
        number of atoms. Like{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>,
        rebuilds are scoped to the builder subtree only.
      </p>

      <h3 id="reacton-consumer-props" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Props
      </h3>
      <div className="my-6 overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Prop</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Type</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Required</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">builder</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Widget Function(BuildContext, ReactonRef)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Builds the subtree. The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ref</code> parameter provides <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch()</code> and <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 id="reacton-consumer-ref" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ref</code> Object
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Inside the builder callback, the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ref</code> parameter
        exposes two methods:
      </p>
      <ul className="list-disc pl-6 space-y-2 text-gray-600 dark:text-gray-400 mb-4">
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ref.watch(atom)</code> --
          Returns the current value and subscribes. The consumer rebuilds when this atom changes.
        </li>
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ref.read(atom)</code> --
          Returns the current value without subscribing. Use this for values you only need once
          during the build (e.g., a configuration atom that never changes).
        </li>
      </ul>
      <CodeBlock
        title="ReactonConsumer example"
        code={`class CartSummary extends StatelessWidget {
  const CartSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonConsumer(
      builder: (context, ref) {
        // Watch multiple atoms -- rebuilds if ANY of them change
        final items = ref.watch(cartItemsAtom);
        final discount = ref.watch(discountAtom);
        final taxRate = ref.read(taxRateAtom); // static config, no subscription

        final subtotal = items.fold<double>(
          0,
          (sum, item) => sum + item.price * item.quantity,
        );
        final total = (subtotal - discount) * (1 + taxRate);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items: \${items.length}'),
                Text('Subtotal: \\\$\${subtotal.toStringAsFixed(2)}'),
                if (discount > 0)
                  Text(
                    'Discount: -\\\$\${discount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                const Divider(),
                Text(
                  'Total: \\\$\${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}`}
      />
      <Callout type="tip" title="ReactonConsumer vs multiple context.watch()">
        Both approaches let you watch multiple atoms. The difference is rebuild scope.
        With{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>,
        the entire widget's{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code> re-runs.
        With{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code>,
        only the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">builder</code> subtree
        re-runs. Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code> when
        you want to protect an expensive parent widget from unnecessary rebuilds.
      </Callout>

      {/* ================================================================ */}
      {/* SECTION 5 - ReactonSelector                                        */}
      {/* ================================================================ */}
      <h2 id="reacton-selector" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        ReactonSelector
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonSelector</code> solves
        a common performance problem: an atom holds a complex object (e.g., a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">User</code> model
        with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">name</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">email</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">age</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">avatarUrl</code>),
        but your widget only cares about one field. Without a selector, the widget rebuilds
        every time <em>any</em> field on the object changes.{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonSelector</code> extracts
        a sub-value and only triggers a rebuild when <em>that specific sub-value</em> changes.
      </p>

      <h3 id="reacton-selector-props" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Props
      </h3>
      <div className="my-6 overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Prop</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Type</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Required</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Atom&lt;T&gt;</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">The source atom containing the full object.</td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">selector</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">S Function(T)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Extracts the sub-value from the atom's full value.</td>
            </tr>
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">builder</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Widget Function(BuildContext, S)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Builds the subtree with the selected sub-value.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 id="reacton-selector-how-it-works" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        How Equality Is Checked
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Every time the source atom changes, Reacton re-runs your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">selector</code> function
        and compares the result to the previously selected value using{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code>.
        If they are equal, the builder is <strong>not</strong> called. This means your selected
        value should be a type with meaningful equality -- primitives ({' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">int</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">String</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">bool</code>),
        enums, or classes that override{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">==</code> and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">hashCode</code> (such
        as Freezed or Equatable classes).
      </p>

      <CodeBlock
        title="ReactonSelector with a User model"
        code={`class User {
  final String name;
  final String email;
  final int age;
  final String avatarUrl;

  const User({
    required this.name,
    required this.email,
    required this.age,
    required this.avatarUrl,
  });
}

final userAtom = atom(const User(
  name: 'Alice',
  email: 'alice@example.com',
  age: 30,
  avatarUrl: 'https://example.com/alice.png',
));

// This widget ONLY rebuilds when user.name changes.
// Changing user.age or user.email has no effect.
ReactonSelector<User, String>(
  atom: userAtom,
  selector: (user) => user.name,
  builder: (context, name) {
    return Text(
      'Hello, \$name!',
      style: Theme.of(context).textTheme.titleLarge,
    );
  },
)

// Another widget that only cares about the avatar
ReactonSelector<User, String>(
  atom: userAtom,
  selector: (user) => user.avatarUrl,
  builder: (context, url) {
    return CircleAvatar(
      backgroundImage: NetworkImage(url),
    );
  },
)`}
      />
      <Callout type="info" title="ReactonSelector vs computed + ReactonBuilder">
        You can achieve a similar result by creating a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed</code> atom
        that derives the sub-value and then watching it with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>.
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonSelector</code> when
        the selection is local to a single widget. Use a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed</code> atom
        when multiple widgets need the same derived value -- it is cached and shared across all
        subscribers.
      </Callout>

      {/* ================================================================ */}
      {/* SECTION 6 - ReactonListener                                        */}
      {/* ================================================================ */}
      <h2 id="reacton-listener" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        ReactonListener
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonListener</code> runs
        side effects in response to atom changes <strong>without rebuilding</strong> its child.
        This is the right choice whenever you need to perform imperative actions such as showing
        a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">SnackBar</code>,
        navigating to a different route, playing a sound, triggering an animation controller, or
        logging analytics events.
      </p>

      <h3 id="reacton-listener-props" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Props
      </h3>
      <div className="my-6 overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Prop</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Type</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Required</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Atom&lt;T&gt;</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">The atom to listen to.</td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onChanged</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">void Function(BuildContext, T)</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Called after every qualifying change with the new value.</td>
            </tr>
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">listenWhen</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">bool Function(T prev, T next)?</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">No</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">When provided, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onChanged</code> is only called if this returns <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">true</code>.</td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">child</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Widget</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Yes</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">The child widget. It is <strong>never</strong> rebuilt by the listener.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 id="reacton-listener-vs-builder" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        How It Differs from ReactonBuilder
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> rebuilds
        a widget subtree.{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonListener</code> never
        rebuilds its child -- it only fires the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onChanged</code> callback.
        If you need <em>both</em> a rebuild and a side effect, nest a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonListener</code> around
        a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code> (or
        use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code> in
        the child and let the listener handle the imperative part).
      </p>

      <h3 id="reacton-listener-snackbar" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Example: Showing a SnackBar
      </h3>
      <CodeBlock
        title="SnackBar on error"
        code={`enum AuthStatus { idle, loading, success, error }

final authStatusAtom = atom(AuthStatus.idle);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonListener<AuthStatus>(
      atom: authStatusAtom,
      listenWhen: (prev, next) => next == AuthStatus.error,
      onChanged: (context, status) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: const LoginForm(), // Never rebuilt by the listener
    );
  }
}`}
      />

      <h3 id="reacton-listener-navigation" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Example: Navigation on State Change
      </h3>
      <CodeBlock
        title="Navigate on auth success"
        code={`class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonListener<AuthStatus>(
      atom: authStatusAtom,
      listenWhen: (prev, next) =>
          prev != AuthStatus.success && next == AuthStatus.success,
      onChanged: (context, status) {
        Navigator.of(context).pushReplacementNamed('/home');
      },
      child: const LoginScreen(),
    );
  }
}`}
      />

      <h3 id="reacton-listener-analytics" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Example: Analytics Tracking
      </h3>
      <CodeBlock
        title="Track page views"
        code={`ReactonListener<String>(
  atom: currentRouteAtom,
  onChanged: (context, route) {
    analytics.logPageView(route);
  },
  child: const AppRouter(),
)`}
      />
      <Callout type="warning" title="Do not modify state inside onChanged">
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onChanged</code> callback
        is intended for imperative side effects. Avoid calling{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set()</code> or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update()</code> inside
        it, as this can create infinite loops. If you need a state change in response to another
        state change, use a derived atom or middleware instead.
      </Callout>

      {/* ================================================================ */}
      {/* SECTION 7 - Auto-Dispose                                         */}
      {/* ================================================================ */}
      <h2 id="auto-dispose" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Auto-Dispose
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton includes an automatic disposal mechanism for atoms. When the last widget watching
        an atom is unmounted (i.e., the atom has zero active subscribers), Reacton can automatically
        reset the atom's value back to its initial state and release any resources associated
        with it. This prevents memory leaks in long-lived applications where features are
        dynamically loaded and unloaded.
      </p>

      <h3 id="auto-dispose-grace-period" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Grace Period
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Disposal does not happen instantly. Reacton waits for a configurable grace period (default:
        5 seconds) after the last subscriber is removed. If a new widget subscribes within that
        window (e.g., the user navigates away and back), the atom is kept alive and the new
        widget receives the existing value. This eliminates unnecessary refetches during quick
        navigation.
      </p>
      <CodeBlock
        title="Configuring auto-dispose"
        code={`// Auto-dispose is enabled by default for atoms.
// The atom resets to its initial value 5 seconds after the
// last widget unsubscribes.
final searchResultsAtom = atom<List<Result>>(
  [],
  autoDispose: true,       // default: true
  disposeDuration: const Duration(seconds: 10), // custom grace period
);

// Auto-dispose is triggered when:
// 1. A widget watching searchResultsAtom is unmounted
// 2. No other widget is watching searchResultsAtom
// 3. 10 seconds pass without a new subscriber
// Then: searchResultsAtom resets to []`}
      />

      <h3 id="auto-dispose-keep-alive" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Keeping Atoms Alive with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">keepAlive</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Some atoms represent global state that should persist for the entire application
        lifetime -- user authentication, theme preferences, locale settings, etc. Mark these
        atoms with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">keepAlive: true</code> to
        prevent auto-dispose entirely.
      </p>
      <CodeBlock
        title="keepAlive example"
        code={`// This atom is NEVER auto-disposed, even if no widget watches it.
final authTokenAtom = atom<String?>(
  null,
  keepAlive: true,
);

final themeAtom = atom<ThemeMode>(
  ThemeMode.system,
  keepAlive: true,
);

// Feature-scoped atoms can still auto-dispose normally
final chatMessagesAtom = atom<List<Message>>(
  [],
  // autoDispose: true (default)
  // When the user leaves the chat screen and no widget watches
  // this atom, it resets after the grace period.
);`}
      />

      <h3 id="auto-dispose-lifecycle" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Disposal Lifecycle
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here is the full sequence of events during auto-dispose:
      </p>
      <ol className="list-decimal pl-6 space-y-2 text-gray-600 dark:text-gray-400 mb-4">
        <li>Widget calls{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch(atom)</code> --
          subscription is created, subscriber count goes to 1.
        </li>
        <li>Widget is unmounted -- subscription is removed, subscriber count goes to 0.</li>
        <li>Grace period timer starts (default 5 seconds).</li>
        <li>If a new widget watches the atom within the grace period, the timer is cancelled and the atom continues normally.</li>
        <li>If no new subscriber appears, the atom's value is reset to its initial value, and any associated resources (async subscriptions, stream listeners) are cleaned up.</li>
      </ol>
      <Callout type="tip" title="Auto-dispose and async atoms">
        Auto-dispose is especially useful for async atoms (e.g., API fetch atoms). When the user
        navigates away from a screen, the atom's in-flight request can be cancelled and the
        cached data released. When the user returns, a fresh fetch is triggered automatically.
      </Callout>

      {/* ================================================================ */}
      {/* SECTION 8 - Choosing the Right Widget                            */}
      {/* ================================================================ */}
      <h2 id="choosing" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Choosing the Right Widget
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        With several reactive primitives available, it helps to have a clear decision framework.
        The table below compares every option across the dimensions that matter most.
      </p>

      <h3 id="choosing-comparison" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Comparison Table
      </h3>
      <div className="my-6 overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Widget / API</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Use Case</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Rebuilds</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Multi-Atom</th>
              <th className="px-4 py-3 font-semibold text-gray-900 dark:text-white">Performance</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Simple reactive reads</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Entire widget</td>
              <td className="px-4 py-3 text-green-600 dark:text-green-400">Yes (multiple calls)</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Good for leaf widgets</td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Scoped single-atom rebuild</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Builder subtree only</td>
              <td className="px-4 py-3 text-red-600 dark:text-red-400">No (single atom)</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Best for isolating hot paths</td>
            </tr>
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Scoped multi-atom rebuild</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Builder subtree only</td>
              <td className="px-4 py-3 text-green-600 dark:text-green-400">Yes (via ref.watch)</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Best for combined state</td>
            </tr>
            <tr className="bg-gray-50/50 dark:bg-gray-800/25">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonSelector</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Sub-value optimization</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Only when selected value changes</td>
              <td className="px-4 py-3 text-red-600 dark:text-red-400">No (single atom)</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Best for large objects</td>
            </tr>
            <tr className="bg-white dark:bg-gray-900">
              <td className="px-4 py-3"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonListener</code></td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Side effects (snackbars, nav, analytics)</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Never (child is untouched)</td>
              <td className="px-4 py-3 text-red-600 dark:text-red-400">No (single atom)</td>
              <td className="px-4 py-3 text-gray-600 dark:text-gray-400">Zero rebuild overhead</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 id="choosing-decision-tree" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Decision Tree
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Follow this flowchart to pick the right tool for each situation:
      </p>
      <div className="my-6 p-6 rounded-xl bg-gray-50 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 font-mono text-sm text-gray-700 dark:text-gray-300 leading-loose">
        <p className="mb-1">Do you need to <strong className="text-gray-900 dark:text-white">rebuild UI</strong> when state changes?</p>
        <p className="ml-4 mb-1">NO  --&gt;  Do you need a side effect?</p>
        <p className="ml-8 mb-1">YES --&gt;  <span className="text-indigo-600 dark:text-indigo-400 font-bold">ReactonListener</span></p>
        <p className="ml-8 mb-3">NO  --&gt;  <span className="text-indigo-600 dark:text-indigo-400 font-bold">context.read()</span> (one-time read)</p>
        <p className="ml-4 mb-1">YES --&gt;  How many atoms?</p>
        <p className="ml-8 mb-1">ONE atom --&gt;  Do you need sub-value filtering?</p>
        <p className="ml-12 mb-1">YES --&gt;  <span className="text-indigo-600 dark:text-indigo-400 font-bold">ReactonSelector</span></p>
        <p className="ml-12 mb-1">NO  --&gt;  Do you need scoped rebuild (protect parent)?</p>
        <p className="ml-16 mb-1">YES --&gt;  <span className="text-indigo-600 dark:text-indigo-400 font-bold">ReactonBuilder</span></p>
        <p className="ml-16 mb-3">NO  --&gt;  <span className="text-indigo-600 dark:text-indigo-400 font-bold">context.watch()</span> (simplest)</p>
        <p className="ml-8 mb-1">MULTIPLE atoms --&gt;  Do you need scoped rebuild?</p>
        <p className="ml-12 mb-1">YES --&gt;  <span className="text-indigo-600 dark:text-indigo-400 font-bold">ReactonConsumer</span></p>
        <p className="ml-12">NO  --&gt;  Multiple <span className="text-indigo-600 dark:text-indigo-400 font-bold">context.watch()</span> calls</p>
      </div>

      <h3 id="choosing-performance-tips" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Performance Optimization Tips
      </h3>
      <ul className="list-disc pl-6 space-y-3 text-gray-600 dark:text-gray-400 mb-4">
        <li>
          <strong className="text-gray-900 dark:text-white">Push watches down the tree.</strong>{' '}
          The lower in the widget tree a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch()</code> call
          lives, the fewer widgets rebuild. Extract small{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">StatelessWidget</code> classes
          that watch a single atom rather than watching in a large parent.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Use <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">const</code> constructors.</strong>{' '}
          Widgets that are{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">const</code> are
          skipped during rebuild, so mark all statically-configured widgets as{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">const</code>.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Prefer computed atoms over in-build derivation.</strong>{' '}
          If multiple widgets need the same derived value, create a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed</code> atom
          once rather than recalculating in every widget's build method.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Use <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">buildWhen</code> / <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">listenWhen</code> liberally.</strong>{' '}
          Conditional callbacks are cheap to evaluate and can prevent significant unnecessary work
          in the builder or listener.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Batch related mutations.</strong>{' '}
          When updating multiple atoms together, use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.batch()</code> to
          coalesce notifications into a single rebuild cycle.
        </li>
      </ul>

      {/* ================================================================ */}
      {/* SECTION 9 - Real-World Patterns                                  */}
      {/* ================================================================ */}
      <h2 id="real-world-patterns" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Real-World Patterns
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Below are complete, copy-pasteable patterns that demonstrate how the widgets above come
        together in typical application scenarios.
      </p>

      {/* --- Todo App --- */}
      <h3 id="pattern-todo" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Todo App -- List and Detail
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A classic pattern: a list screen watches the full list, while the detail screen uses a
        selector to watch only the selected item. Mutations go through{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update()</code>.
      </p>
      <CodeBlock
        title="todo_atoms.dart"
        code={`class Todo {
  final String id;
  final String title;
  final bool done;

  const Todo({required this.id, required this.title, this.done = false});

  Todo copyWith({String? title, bool? done}) =>
      Todo(id: id, title: title ?? this.title, done: done ?? this.done);
}

final todosAtom = atom<List<Todo>>([]);
final selectedTodoIdAtom = atom<String?>(null);

// Derived: the currently selected todo
final selectedTodoAtom = computed((read) {
  final id = read(selectedTodoIdAtom);
  if (id == null) return null;
  final todos = read(todosAtom);
  return todos.where((t) => t.id == id).firstOrNull;
});`}
      />
      <CodeBlock
        title="todo_list_screen.dart"
        code={`class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: ReactonBuilder<List<Todo>>(
        atom: todosAtom,
        builder: (context, todos) {
          if (todos.isEmpty) {
            return const Center(child: Text('No todos yet.'));
          }
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                leading: Checkbox(
                  value: todo.done,
                  onChanged: (_) {
                    context.update(todosAtom, (list) => [
                      for (final t in list)
                        if (t.id == todo.id) t.copyWith(done: !t.done) else t,
                    ]);
                  },
                ),
                title: Text(todo.title),
                onTap: () {
                  context.set(selectedTodoIdAtom, todo.id);
                  Navigator.pushNamed(context, '/todo-detail');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}`}
      />

      {/* --- Form with Validation --- */}
      <h3 id="pattern-form" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Form with Validation
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        This pattern shows how to keep form state in atoms, derive validation errors with
        computed atoms, and use a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code> to
        watch both the field values and the error messages in one builder.
      </p>
      <CodeBlock
        title="form_atoms.dart"
        code={`final emailAtom = atom('');
final passwordAtom = atom('');

final emailErrorAtom = computed((read) {
  final email = read(emailAtom);
  if (email.isEmpty) return null;
  if (!email.contains('@')) return 'Invalid email address';
  return null;
});

final passwordErrorAtom = computed((read) {
  final password = read(passwordAtom);
  if (password.isEmpty) return null;
  if (password.length < 8) return 'Must be at least 8 characters';
  return null;
});

final isFormValidAtom = computed((read) {
  final email = read(emailAtom);
  final password = read(passwordAtom);
  return email.contains('@') && password.length >= 8;
});`}
      />
      <CodeBlock
        title="login_form.dart"
        code={`class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ReactonConsumer(
        builder: (context, ref) {
          final emailError = ref.watch(emailErrorAtom);
          final passwordError = ref.watch(passwordErrorAtom);
          final isValid = ref.watch(isFormValidAtom);

          return Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: emailError,
                ),
                onChanged: (value) => context.set(emailAtom, value),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: passwordError,
                ),
                onChanged: (value) => context.set(passwordAtom, value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isValid
                      ? () {
                          final email = context.read(emailAtom);
                          final password = context.read(passwordAtom);
                          context.set(authStatusAtom, AuthStatus.loading);
                          // dispatch login action...
                        }
                      : null,
                  child: const Text('Sign In'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}`}
      />

      {/* --- Infinite Scroll List --- */}
      <h3 id="pattern-infinite-scroll" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Infinite Scroll List
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Pagination state is modeled with atoms for the current page, loading status, and
        accumulated items. A{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonListener</code> triggers
        a snackbar on error, while a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code> renders
        the list and the loading indicator.
      </p>
      <CodeBlock
        title="infinite_scroll.dart"
        code={`final postsAtom = atom<List<Post>>([]);
final currentPageAtom = atom(1);
final isLoadingMoreAtom = atom(false);
final hasMoreAtom = atom(true);
final feedErrorAtom = atom<String?>(null);

class InfinitePostList extends StatelessWidget {
  const InfinitePostList({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonListener<String?>(
      atom: feedErrorAtom,
      listenWhen: (prev, next) => next != null,
      onChanged: (context, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error!)),
        );
      },
      child: ReactonConsumer(
        builder: (context, ref) {
          final posts = ref.watch(postsAtom);
          final isLoading = ref.watch(isLoadingMoreAtom);
          final hasMore = ref.watch(hasMoreAtom);

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200 &&
                  !isLoading &&
                  hasMore) {
                _loadNextPage(context);
              }
              return false;
            },
            child: ListView.builder(
              itemCount: posts.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return PostCard(post: posts[index]);
              },
            ),
          );
        },
      ),
    );
  }

  void _loadNextPage(BuildContext context) {
    context.set(isLoadingMoreAtom, true);
    final page = context.read(currentPageAtom);
    // Dispatch an async action to fetch the next page...
    // On success: append to postsAtom, increment currentPageAtom
    // On failure: set feedErrorAtom
    // Always: set isLoadingMoreAtom to false
  }
}`}
      />

      {/* --- Theme Switching --- */}
      <h3 id="pattern-theme" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Theme Switching
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A global theme atom drives the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MaterialApp</code>'s
        theme mode. Because the watch happens at the app root, the entire tree re-themes
        instantly. Marking the atom with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">keepAlive: true</code> ensures
        the theme persists even if no widget is actively rendering.
      </p>
      <CodeBlock
        title="theme_switching.dart"
        code={`final themeModeAtom = atom<ThemeMode>(
  ThemeMode.system,
  keepAlive: true,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch at the root so the entire app rebuilds on theme change
    final mode = context.watch(themeModeAtom);

    return MaterialApp(
      themeMode: mode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// Anywhere in the app: toggle the theme
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch(themeModeAtom);

    return IconButton(
      icon: Icon(
        mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () {
        context.update(themeModeAtom, (current) =>
          current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
        );
      },
    );
  }
}`}
      />

      <Callout type="tip" title="Combining patterns">
        These patterns are composable. A real application might use the theme atom from the theme
        switching pattern, the form atoms from the form validation pattern, and the infinite scroll
        pattern all in the same app. Because atoms are independent and decoupled, combining them
        is as simple as importing the atom definitions and using the appropriate widget.
      </Callout>

      <PageNav
        prev={{ title: 'Core Concepts', path: '/core-concepts' }}
        next={{ title: 'Async & Middleware', path: '/async-middleware' }}
      />
    </div>
  )
}
