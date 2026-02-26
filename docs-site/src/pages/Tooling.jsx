import CodeBlock from '../components/CodeBlock'
import Callout from '../components/Callout'
import PageNav from '../components/PageNav'

export default function Tooling() {
  return (
    <div>
      <h1 id="developer-tooling" className="text-4xl font-extrabold tracking-tight mb-4">
        Developer Tooling
      </h1>
      <p className="text-lg text-gray-500 dark:text-gray-400 mb-8">
        A complete ecosystem of developer tools for building, debugging, analyzing, and maintaining Reacton applications. This page covers the DevTools extension, CLI, lint rules, VS Code extension, and code generation.
      </p>

      {/* ================================================================== */}
      {/* SECTION 1: DEVTOOLS EXTENSION                                      */}
      {/* ================================================================== */}
      <h2 id="devtools" className="text-2xl font-bold mt-12 mb-4">
        DevTools Extension
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Reacton DevTools Extension integrates directly into Flutter DevTools, providing a rich visual debugging experience for your state management layer. It gives you real-time insight into every atom in your application, their dependencies, values, subscribers, and performance characteristics.
      </p>

      <h3 id="devtools-setup" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Setup
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        To enable the DevTools extension, add the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">DevToolsMiddleware</code>{' '}
        to your store. This middleware registers Reacton service extensions with the Dart VM, which the DevTools panel discovers automatically.
      </p>

      <CodeBlock
        title="lib/main.dart"
        code={`import 'package:reacton/reacton.dart';
import 'package:reacton_devtools/reacton_devtools.dart';

void main() {
  final store = ReactonStore();

  // Enable DevTools integration (only active in debug mode)
  store.addMiddleware(DevToolsMiddleware(
    // Optional: control what gets reported
    trackPerformance: true,    // enable performance profiling
    trackTimeline: true,       // record state change timeline
    maxTimelineEntries: 5000,  // cap timeline buffer size
    enableLiveEdit: true,      // allow editing values from DevTools
  ));

  // Register your atoms
  store.register(counterAtom);
  store.register(userAtom);
  store.register(cartAtom);

  runApp(
    ReactonScope(
      store: store,
      child: const MyApp(),
    ),
  );
}`}
      />

      <Callout type="tip" title="Debug-Only Middleware">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">DevToolsMiddleware</code> automatically disables itself in release builds via{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">kDebugMode</code>, so you can safely leave it in your code without impacting production performance.
      </Callout>

      {/* Graph View */}
      <h3 id="devtools-graph-view" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Graph View
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Graph View renders an interactive force-directed dependency graph of every atom registered in your store. Each node represents an atom, and each directed edge represents a dependency relationship (an arrow from A to B means "A depends on B").
      </p>

      <div className="mb-6 space-y-3">
        <h4 className="text-base font-semibold text-gray-900 dark:text-white">Reading the Graph</h4>
        <ul className="list-disc pl-6 space-y-2 text-gray-600 dark:text-gray-400">
          <li><strong className="text-gray-900 dark:text-white">Nodes</strong> represent individual atoms. The node label shows the atom's name (the <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">name</code> parameter you passed when creating the atom).</li>
          <li><strong className="text-gray-900 dark:text-white">Edges</strong> are directed arrows showing dependency flow. If <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">totalAtom</code> reads from <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">priceAtom</code> and <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">taxAtom</code>, you will see arrows from <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">totalAtom</code> pointing to both.</li>
          <li><strong className="text-gray-900 dark:text-white">Node size</strong> scales with subscriber count -- atoms watched by many widgets appear larger.</li>
        </ul>
      </div>

      <div className="mb-6 space-y-3">
        <h4 className="text-base font-semibold text-gray-900 dark:text-white">Color Coding</h4>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
            <span className="w-4 h-4 rounded-full bg-blue-500 shrink-0"></span>
            <div>
              <span className="text-sm font-semibold text-gray-900 dark:text-white">Blue</span>
              <span className="text-sm text-gray-500 dark:text-gray-400"> -- Writable atoms (basic state)</span>
            </div>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
            <span className="w-4 h-4 rounded-full bg-purple-500 shrink-0"></span>
            <div>
              <span className="text-sm font-semibold text-gray-900 dark:text-white">Purple</span>
              <span className="text-sm text-gray-500 dark:text-gray-400"> -- Computed atoms (derived state)</span>
            </div>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
            <span className="w-4 h-4 rounded-full bg-green-500 shrink-0"></span>
            <div>
              <span className="text-sm font-semibold text-gray-900 dark:text-white">Green</span>
              <span className="text-sm text-gray-500 dark:text-gray-400"> -- Async atoms (futures/streams)</span>
            </div>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
            <span className="w-4 h-4 rounded-full bg-amber-500 shrink-0"></span>
            <div>
              <span className="text-sm font-semibold text-gray-900 dark:text-white">Amber</span>
              <span className="text-sm text-gray-500 dark:text-gray-400"> -- Effects (side-effect handlers)</span>
            </div>
          </div>
        </div>
      </div>

      <div className="mb-6 space-y-3">
        <h4 className="text-base font-semibold text-gray-900 dark:text-white">Interaction Controls</h4>
        <ul className="list-disc pl-6 space-y-2 text-gray-600 dark:text-gray-400">
          <li><strong className="text-gray-900 dark:text-white">Click a node</strong> to select it and open its details in the Atom Inspector panel. The selected node and its immediate dependencies are highlighted while other nodes are dimmed.</li>
          <li><strong className="text-gray-900 dark:text-white">Scroll to zoom</strong> in and out of the graph. Use pinch gestures on trackpads.</li>
          <li><strong className="text-gray-900 dark:text-white">Drag the canvas</strong> to pan the viewport. Drag individual nodes to rearrange them -- the force simulation will re-settle.</li>
          <li><strong className="text-gray-900 dark:text-white">Toolbar buttons</strong>: Fit to screen, zoom to 100%, toggle labels, toggle edge arrows, and export as PNG.</li>
          <li><strong className="text-gray-900 dark:text-white">Search box</strong>: Type to highlight matching atoms in the graph. Non-matching nodes fade to 20% opacity.</li>
        </ul>
      </div>

      {/* Atom Inspector */}
      <h3 id="devtools-atom-inspector" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Atom Inspector
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Atom Inspector provides a live, searchable table of every atom in your store. It updates in real time as state changes occur.
      </p>

      <div className="mb-6 space-y-3">
        <h4 className="text-base font-semibold text-gray-900 dark:text-white">Columns Displayed</h4>
        <div className="overflow-x-auto">
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-800">
                <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Column</th>
                <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
              </tr>
            </thead>
            <tbody className="text-gray-600 dark:text-gray-400">
              <tr className="border-b border-gray-100 dark:border-gray-800/50">
                <td className="py-3 px-4 font-medium text-gray-900 dark:text-white">Name</td>
                <td className="py-3 px-4">The atom's registered name identifier</td>
              </tr>
              <tr className="border-b border-gray-100 dark:border-gray-800/50">
                <td className="py-3 px-4 font-medium text-gray-900 dark:text-white">Type</td>
                <td className="py-3 px-4">The Dart type of the atom's value (e.g., <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">int</code>, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">List&lt;String&gt;</code>, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AsyncValue&lt;User&gt;</code>)</td>
              </tr>
              <tr className="border-b border-gray-100 dark:border-gray-800/50">
                <td className="py-3 px-4 font-medium text-gray-900 dark:text-white">Current Value</td>
                <td className="py-3 px-4">The live value, formatted as a JSON-like tree for complex objects. Primitives show inline.</td>
              </tr>
              <tr className="border-b border-gray-100 dark:border-gray-800/50">
                <td className="py-3 px-4 font-medium text-gray-900 dark:text-white">Subscribers</td>
                <td className="py-3 px-4">Number of active widgets currently watching this atom</td>
              </tr>
              <tr className="border-b border-gray-100 dark:border-gray-800/50">
                <td className="py-3 px-4 font-medium text-gray-900 dark:text-white">Dependencies</td>
                <td className="py-3 px-4">Count of atoms this atom depends on (for computed/async atoms)</td>
              </tr>
              <tr>
                <td className="py-3 px-4 font-medium text-gray-900 dark:text-white">Kind</td>
                <td className="py-3 px-4">Badge showing writable, computed, async, or family</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div className="mb-6 space-y-3">
        <h4 className="text-base font-semibold text-gray-900 dark:text-white">Live Value Editing</h4>
        <p className="text-gray-600 dark:text-gray-400 leading-relaxed">
          When <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">enableLiveEdit: true</code> is set on the middleware, you can double-click any writable atom's value cell to edit it directly. The new value is parsed and applied to the store immediately, triggering all downstream recomputations and widget rebuilds. This is extremely useful for testing edge cases (e.g., setting a counter to <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">int.maxValue</code> or injecting an error string) without writing any code.
        </p>
      </div>

      <div className="mb-6 space-y-3">
        <h4 className="text-base font-semibold text-gray-900 dark:text-white">Search and Filter</h4>
        <p className="text-gray-600 dark:text-gray-400 leading-relaxed">
          The search bar at the top of the inspector supports filtering by atom name, type, or kind. Type{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">kind:computed</code> to show only computed atoms,{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">type:List</code> to find all list-typed atoms, or simply type a name fragment like{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">user</code> to match all atoms containing "user" in their name.
        </p>
      </div>

      {/* Timeline View */}
      <h3 id="devtools-timeline" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Timeline View
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Timeline View provides a chronological log of every state mutation that occurs in your application. Each entry records the atom name, the old value, the new value, and the precise timestamp. This is invaluable for understanding how state evolves over time and debugging sequences of events.
      </p>

      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Chronological log</strong> -- Every mutation is recorded with a monotonically increasing sequence number and a high-resolution timestamp.</li>
        <li><strong className="text-gray-900 dark:text-white">Filter by atom</strong> -- Click an atom name to filter the timeline to only that atom's changes. Use the multi-select dropdown to filter by multiple atoms simultaneously.</li>
        <li><strong className="text-gray-900 dark:text-white">Filter by time range</strong> -- Drag on the mini timeline bar at the top to select a time window. Only entries within that range are displayed.</li>
        <li><strong className="text-gray-900 dark:text-white">Filter by action type</strong> -- Filter entries by type: <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set</code> (direct writes), <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update</code> (functional updates), <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">recompute</code> (computed re-evaluations), or <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">async</code> (async state transitions).</li>
        <li><strong className="text-gray-900 dark:text-white">Expandable entries</strong> -- Click any entry to expand it and see a side-by-side diff of the old and new values. Complex objects are displayed as a collapsible JSON tree with highlighted changes.</li>
        <li><strong className="text-gray-900 dark:text-white">Export timeline</strong> -- Click the export button to download the entire timeline buffer as a JSON file. This file can be shared with teammates or attached to bug reports for offline analysis.</li>
      </ul>

      {/* Branch View */}
      <h3 id="devtools-branch-view" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Branch View
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        If your application uses Reacton's state branching feature, the Branch View visualizes all active branches as a tree. Each branch node shows its label, the number of atoms that differ from the parent, and its creation timestamp.
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Active branches</strong> -- See all branches that currently exist in the store, arranged in a parent-child hierarchy.</li>
        <li><strong className="text-gray-900 dark:text-white">Branch comparison</strong> -- Select any branch to see a diff view showing which atoms have different values compared to the parent branch. Changed atoms are highlighted with their branch-local vs. parent values side by side.</li>
        <li><strong className="text-gray-900 dark:text-white">Merge and discard</strong> -- Right-click a branch node to merge it into its parent (promoting its changes) or discard it entirely. Both actions prompt for confirmation.</li>
      </ul>

      {/* Performance View */}
      <h3 id="devtools-performance" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Performance View
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Performance View provides profiling data for your state management layer. It helps you identify expensive computations, unnecessary recomputations, and propagation bottlenecks.
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Recomputation counts</strong> -- A bar chart showing how many times each computed atom has been re-evaluated. Atoms that recompute far more often than they need to are flagged with a warning icon.</li>
        <li><strong className="text-gray-900 dark:text-white">Propagation times</strong> -- Measures how long it takes for a change to propagate from a source atom through all its dependents. Displayed as a flame chart where each segment represents one atom's recomputation time.</li>
        <li><strong className="text-gray-900 dark:text-white">Hot path detection</strong> -- The performance profiler identifies "hot paths" -- chains of computed atoms that are evaluated most frequently. These are highlighted in red in both the Graph View and the Performance View.</li>
        <li><strong className="text-gray-900 dark:text-white">Memory usage overview</strong> -- Shows estimated memory consumption per atom, including the size of stored values and metadata overhead. Useful for detecting atoms that hold unexpectedly large data structures.</li>
      </ul>

      {/* Service Extensions API */}
      <h3 id="devtools-service-extensions" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Service Extensions API
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The DevToolsMiddleware registers several Dart VM service extensions that can be called programmatically from any DevTools client or script. This is useful for building custom tooling or integrating with CI pipelines.
      </p>

      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Extension</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Returns</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ext.reacton.getGraph</code></td>
              <td className="py-3 px-4">Returns the full dependency graph as JSON</td>
              <td className="py-3 px-4">Nodes and edges arrays</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ext.reacton.getAtomValue</code></td>
              <td className="py-3 px-4">Returns the current value of a specific atom by name</td>
              <td className="py-3 px-4">JSON-encoded value</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ext.reacton.setAtomValue</code></td>
              <td className="py-3 px-4">Sets an atom's value from an external client</td>
              <td className="py-3 px-4">Success/error status</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ext.reacton.getTimeline</code></td>
              <td className="py-3 px-4">Returns the timeline buffer with optional filters</td>
              <td className="py-3 px-4">Array of timeline entries</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ext.reacton.getPerformance</code></td>
              <td className="py-3 px-4">Returns profiling metrics for all atoms</td>
              <td className="py-3 px-4">Recompute counts, timing data</td>
            </tr>
            <tr>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ext.reacton.getBranches</code></td>
              <td className="py-3 px-4">Returns all active branches and their state diffs</td>
              <td className="py-3 px-4">Branch tree with diff data</td>
            </tr>
          </tbody>
        </table>
      </div>

      <CodeBlock
        title="Calling service extensions programmatically"
        code={`// From a Dart script or test, you can invoke extensions via the VM service:
import 'dart:developer';

Future<void> inspectAtom(String atomName) async {
  final response = await developer.postEvent(
    'ext.reacton.getAtomValue',
    {'name': atomName},
  );
  print('Current value of \$atomName: \${response.data}');
}

Future<Map<String, dynamic>> exportGraph() async {
  final response = await developer.postEvent(
    'ext.reacton.getGraph',
    {},
  );
  return response.data as Map<String, dynamic>;
}`}
      />

      {/* ================================================================== */}
      {/* SECTION 2: CLI TOOL                                                */}
      {/* ================================================================== */}
      <h2 id="cli" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        CLI Tool (reacton_cli)
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_cli</code> package provides a powerful command-line interface for scaffolding, analyzing, and diagnosing Reacton projects. It streamlines project setup, generates boilerplate, and provides deep analysis of your atom dependency graph.
      </p>

      <h3 id="cli-installation" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Installation
      </h3>
      <CodeBlock
        language="bash"
        code={`# Install globally from pub.dev
dart pub global activate reacton_cli

# Verify installation
reacton --version
# reacton_cli 0.4.2`}
      />

      <Callout type="info" title="PATH Configuration">
        Make sure the Dart pub global bin directory is in your system PATH. On most systems this is{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">~/.pub-cache/bin</code>. If you see "command not found" after installation, add this directory to your shell profile.
      </Callout>

      {/* reacton init */}
      <h3 id="cli-init" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton init</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Initializes Reacton in an existing Flutter project. This command adds the required dependencies to your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pubspec.yaml</code>, creates a recommended folder structure, and optionally configures lint rules.
      </p>

      <CodeBlock
        language="bash"
        code={`# Basic initialization
reacton init

# With all optional features
reacton init --lint --devtools --codegen

# Skip dependency installation (just scaffold folders)
reacton init --no-install

# Specify a custom atoms directory
reacton init --atoms-dir lib/state`}
      />

      <CodeBlock
        language="bash"
        title="Example output"
        code={`$ reacton init --lint --devtools
✓ Adding reacton: ^0.5.0 to dependencies
✓ Adding flutter_reacton: ^0.5.0 to dependencies
✓ Adding reacton_devtools: ^0.2.0 to dev_dependencies
✓ Adding reacton_lint: ^0.3.0 to dev_dependencies
✓ Adding custom_lint: ^0.6.0 to dev_dependencies
✓ Running dart pub get...
✓ Created lib/atoms/
✓ Created lib/atoms/app_atoms.dart
✓ Created lib/effects/
✓ Created test/atoms/
✓ Updated analysis_options.yaml with reacton_lint rules

Reacton initialized successfully!
Run "reacton create atom <name>" to create your first atom.`}
      />

      {/* reacton create atom */}
      <h3 id="cli-create-atom" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton create atom &lt;name&gt;</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Scaffolds a new atom from a template. The generated file includes the atom declaration, documentation comments, and a corresponding test file.
      </p>

      <CodeBlock
        language="bash"
        code={`# Create a basic writable atom
reacton create atom user_settings

# Create a computed atom
reacton create atom cart_total --type computed

# Create an async atom
reacton create atom user_profile --type async

# Create a family atom
reacton create atom todo_item --type family

# Specify a custom output directory
reacton create atom counter --dir lib/features/counter/atoms`}
      />

      <CodeBlock
        title="Generated: lib/atoms/user_settings_atom.dart"
        code={`import 'package:reacton/reacton.dart';

/// Atom for managing user settings state.
///
/// Usage:
///   final settings = context.watch(userSettingsAtom);
///   context.read(userSettingsAtom).set(newSettings);
final userSettingsAtom = atom<UserSettings>(
  UserSettings.defaults(),
  name: 'userSettings',
);

class UserSettings {
  final String theme;
  final String locale;
  final bool notificationsEnabled;

  const UserSettings({
    this.theme = 'system',
    this.locale = 'en',
    this.notificationsEnabled = true,
  });

  factory UserSettings.defaults() => const UserSettings();

  UserSettings copyWith({
    String? theme,
    String? locale,
    bool? notificationsEnabled,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}`}
      />

      <CodeBlock
        title="Generated: test/atoms/user_settings_atom_test.dart"
        code={`import 'package:flutter_test/flutter_test.dart';
import 'package:reacton_test/reacton_test.dart';
import 'package:my_app/atoms/user_settings_atom.dart';

void main() {
  late TestStore store;

  setUp(() {
    store = TestStore();
  });

  group('userSettingsAtom', () {
    test('has correct default value', () {
      final settings = store.read(userSettingsAtom);
      expect(settings.theme, equals('system'));
      expect(settings.locale, equals('en'));
      expect(settings.notificationsEnabled, isTrue);
    });

    test('can update value', () {
      store.set(userSettingsAtom, UserSettings(theme: 'dark'));
      expect(store.read(userSettingsAtom).theme, equals('dark'));
    });
  });
}`}
      />

      {/* reacton create feature */}
      <h3 id="cli-create-feature" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton create feature &lt;name&gt;</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Generates an entire feature folder following a feature-first architecture. This creates atoms, widgets, effects, and test files all wired together and ready to customize.
      </p>

      <CodeBlock
        language="bash"
        code={`# Generate a feature module
reacton create feature authentication

# With async atoms for API calls
reacton create feature authentication --with-async

# With persistence support
reacton create feature authentication --with-persistence`}
      />

      <CodeBlock
        language="bash"
        title="Generated file structure"
        code={`$ reacton create feature authentication
✓ Created lib/features/authentication/
✓ Created lib/features/authentication/atoms/
✓ Created lib/features/authentication/atoms/auth_state_atom.dart
✓ Created lib/features/authentication/atoms/current_user_atom.dart
✓ Created lib/features/authentication/atoms/auth_loading_atom.dart
✓ Created lib/features/authentication/widgets/
✓ Created lib/features/authentication/widgets/login_form.dart
✓ Created lib/features/authentication/widgets/auth_guard.dart
✓ Created lib/features/authentication/effects/
✓ Created lib/features/authentication/effects/auth_effects.dart
✓ Created lib/features/authentication/authentication.dart  (barrel file)
✓ Created test/features/authentication/
✓ Created test/features/authentication/atoms/auth_state_atom_test.dart
✓ Created test/features/authentication/atoms/current_user_atom_test.dart
✓ Created test/features/authentication/widgets/login_form_test.dart

Feature "authentication" created with 12 files.`}
      />

      {/* reacton graph */}
      <h3 id="cli-graph" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton graph</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Analyzes your source code and prints the atom dependency graph. This works statically (no running app required) by parsing your Dart source files for atom declarations and their{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code> calls.
      </p>

      <CodeBlock
        language="bash"
        code={`# Print as a text tree (default)
reacton graph

# Export as DOT format for GraphViz
reacton graph --format=dot

# Export as JSON for programmatic use
reacton graph --format=json

# Pipe to GraphViz to generate an image
reacton graph --format=dot | dot -Tpng -o graph.png

# Generate an SVG
reacton graph --format=dot | dot -Tsvg -o graph.svg

# Filter to a specific directory
reacton graph --dir lib/features/cart`}
      />

      <CodeBlock
        language="bash"
        title="Text tree output example"
        code={`$ reacton graph
Reacton Dependency Graph (12 atoms)
═══════════════════════════════════

cartTotalAtom (computed)
├── cartItemsAtom (writable)
├── taxRateAtom (writable)
└── discountAtom (computed)
    └── couponCodeAtom (writable)

userDisplayNameAtom (computed)
└── currentUserAtom (async)
    └── authTokenAtom (writable)

themeAtom (writable)
localeAtom (writable)
notificationsEnabledAtom (writable)

Legend: (writable) (computed) (async) (family)`}
      />

      <CodeBlock
        language="json"
        title="JSON output example"
        code={`{
  "nodes": [
    { "name": "cartTotalAtom", "kind": "computed", "file": "lib/atoms/cart_atoms.dart", "line": 14 },
    { "name": "cartItemsAtom", "kind": "writable", "file": "lib/atoms/cart_atoms.dart", "line": 5 },
    { "name": "taxRateAtom", "kind": "writable", "file": "lib/atoms/cart_atoms.dart", "line": 8 },
    { "name": "discountAtom", "kind": "computed", "file": "lib/atoms/cart_atoms.dart", "line": 22 },
    { "name": "couponCodeAtom", "kind": "writable", "file": "lib/atoms/cart_atoms.dart", "line": 11 }
  ],
  "edges": [
    { "from": "cartTotalAtom", "to": "cartItemsAtom" },
    { "from": "cartTotalAtom", "to": "taxRateAtom" },
    { "from": "cartTotalAtom", "to": "discountAtom" },
    { "from": "discountAtom", "to": "couponCodeAtom" }
  ]
}`}
      />

      {/* reacton analyze */}
      <h3 id="cli-analyze" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton analyze</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Performs static analysis on your atom declarations and their usage throughout the codebase. This command identifies potential issues that lint rules alone cannot catch because it analyzes cross-file relationships.
      </p>

      <CodeBlock
        language="bash"
        code={`# Run all analysis checks
reacton analyze

# Only check for dead atoms
reacton analyze --dead-atoms

# Only check for cycles
reacton analyze --cycles

# Machine-readable JSON output
reacton analyze --format=json`}
      />

      <CodeBlock
        language="bash"
        title="Example output"
        code={`$ reacton analyze
Analyzing 47 atoms across 23 files...

DEAD ATOMS (declared but never watched or read):
  ⚠ legacyThemeAtom  lib/atoms/theme_atoms.dart:12
  ⚠ debugFlagAtom    lib/atoms/debug_atoms.dart:3

CYCLE DETECTION:
  ✓ No circular dependencies detected.

COMPLEXITY ANALYSIS:
  ⚠ cartTotalAtom has a dependency depth of 5 (threshold: 4)
    Chain: cartTotalAtom → discountAtom → couponValidAtom
           → apiStatusAtom → authAtom → tokenAtom
  ✓ All other atoms are within complexity thresholds.

Summary: 2 warnings, 0 errors
Run with --fix to remove dead atom declarations.`}
      />

      {/* reacton doctor */}
      <h3 id="cli-doctor" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton doctor</code>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Diagnoses common configuration and setup issues. This is the first command to run when something is not working as expected.
      </p>

      <CodeBlock
        language="bash"
        code={`reacton doctor`}
      />

      <CodeBlock
        language="bash"
        title="Example output"
        code={`$ reacton doctor
Reacton Doctor
════════════

[✓] Dart SDK 3.2.6
[✓] Flutter SDK 3.19.3
[✓] reacton: 0.5.0 (latest: 0.5.0)
[✓] flutter_reacton: 0.5.0 (latest: 0.5.0)
[✓] reacton_lint: 0.3.0 (latest: 0.3.1)
    ⚠ Update available: run "dart pub upgrade reacton_lint"
[✓] reacton_test: 0.2.0 (latest: 0.2.0)
[✗] reacton_devtools: not installed
    → Add to dev_dependencies or run "reacton init --devtools"
[✓] analysis_options.yaml includes custom_lint
[✓] analysis_options.yaml has reacton lint rules configured
[✓] No conflicting state management packages detected
[✓] ReactonScope found in lib/main.dart

Summary: 8 passed, 1 warning, 1 issue
Run "reacton init --devtools" to fix the missing devtools package.`}
      />

      {/* ================================================================== */}
      {/* SECTION 3: LINT RULES                                              */}
      {/* ================================================================== */}
      <h2 id="lint" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Lint Rules (reacton_lint)
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_lint</code> package provides a set of custom lint rules that catch common mistakes and enforce best practices for Reacton. These rules integrate with the Dart analyzer via the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">custom_lint</code> package and surface errors, warnings, and suggestions directly in your IDE.
      </p>

      <h3 id="lint-setup" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Setup
      </h3>

      <CodeBlock
        language="yaml"
        title="pubspec.yaml"
        code={`dev_dependencies:
  reacton_lint: ^0.3.0
  custom_lint: ^0.6.0`}
      />

      <CodeBlock
        language="yaml"
        title="analysis_options.yaml"
        code={`analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    # Error-level rules (must fix)
    - reacton_avoid_atom_in_build
    - reacton_cyclic_dependency

    # Warning-level rules (should fix)
    - reacton_avoid_read_in_build
    - reacton_unused_atom

    # Info-level rules (suggestions)
    - reacton_prefer_computed
    - reacton_prefer_selector`}
      />

      <h3 id="lint-rule-reference" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Complete Rule Reference
      </h3>

      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Rule</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Severity</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Has Quick Fix</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_avoid_atom_in_build</code></td>
              <td className="py-3 px-4"><span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-400">Error</span></td>
              <td className="py-3 px-4">Do not create atoms inside build methods</td>
              <td className="py-3 px-4">Yes</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_cyclic_dependency</code></td>
              <td className="py-3 px-4"><span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-400">Error</span></td>
              <td className="py-3 px-4">Circular atom dependency detected</td>
              <td className="py-3 px-4">No</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_avoid_read_in_build</code></td>
              <td className="py-3 px-4"><span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400">Warning</span></td>
              <td className="py-3 px-4">Prefer watch() over read() in build methods</td>
              <td className="py-3 px-4">Yes</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_unused_atom</code></td>
              <td className="py-3 px-4"><span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400">Warning</span></td>
              <td className="py-3 px-4">Atom is declared but never watched or read</td>
              <td className="py-3 px-4">No</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_prefer_computed</code></td>
              <td className="py-3 px-4"><span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400">Info</span></td>
              <td className="py-3 px-4">Extract 3+ watch calls to a computed atom</td>
              <td className="py-3 px-4">Yes</td>
            </tr>
            <tr>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_prefer_selector</code></td>
              <td className="py-3 px-4"><span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400">Info</span></td>
              <td className="py-3 px-4">Use a selector when accessing a field after watch</td>
              <td className="py-3 px-4">Yes</td>
            </tr>
          </tbody>
        </table>
      </div>

      {/* reacton_avoid_atom_in_build */}
      <h3 id="lint-avoid-atom-in-build" className="text-lg font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_avoid_atom_in_build</code>{' '}
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-400">Error</span>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        This rule flags any call to{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed()</code>, or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">asyncAtom()</code>{' '}
        that appears inside a <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code> method. Creating atoms inside build is a critical mistake because the build method runs on every widget rebuild. This means a brand-new atom is created each time, losing all previous state and triggering an infinite loop of rebuilds.
      </p>

      <CodeBlock
        title="BAD -- atom created inside build()"
        code={`class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ERROR: reacton_avoid_atom_in_build
    // A new atom is created on every rebuild!
    final counterAtom = atom<int>(0, name: 'counter');

    return Text('\${context.watch(counterAtom)}');
  }
}`}
      />

      <CodeBlock
        title="GOOD -- atom declared at top level"
        code={`// Atoms are declared once, outside of any build method
final counterAtom = atom<int>(0, name: 'counter');

class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('\${context.watch(counterAtom)}');
  }
}`}
      />

      {/* reacton_avoid_read_in_build */}
      <h3 id="lint-avoid-read-in-build" className="text-lg font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_avoid_read_in_build</code>{' '}
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400">Warning</span>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        This rule catches uses of{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read(atom)</code>{' '}
        inside build methods. While <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code> returns the current value, it does <strong className="text-gray-900 dark:text-white">not</strong> subscribe the widget to future changes. This means the UI will not update when the atom's value changes, which is almost always a bug when reading values for display in the build method.
      </p>

      <CodeBlock
        title="BAD -- read() in build won't react to changes"
        code={`class UserGreeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // WARNING: reacton_avoid_read_in_build
    // This will show the initial name but never update
    final name = context.read(userNameAtom);

    return Text('Hello, \$name!');
  }
}`}
      />

      <CodeBlock
        title="GOOD -- watch() subscribes to changes"
        code={`class UserGreeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // watch() subscribes this widget to userNameAtom changes
    final name = context.watch(userNameAtom);

    return Text('Hello, \$name!');
  }
}

// Use read() in callbacks, not in build:
class IncrementButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // read() is correct here -- callbacks don't need subscriptions
        context.read(counterAtom).update((n) => n + 1);
      },
      child: const Text('Increment'),
    );
  }
}`}
      />

      {/* reacton_prefer_computed */}
      <h3 id="lint-prefer-computed" className="text-lg font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_prefer_computed</code>{' '}
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400">Info</span>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When a build method calls <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code> on three or more atoms and combines their values, this rule suggests extracting that logic into a computed atom. Computed atoms are reusable across widgets, independently testable, and benefit from automatic memoization.
      </p>

      <CodeBlock
        title="BEFORE -- multiple watches combined in build"
        code={`class OrderSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // INFO: reacton_prefer_computed
    // Consider extracting to a computed atom
    final items = context.watch(cartItemsAtom);
    final taxRate = context.watch(taxRateAtom);
    final discount = context.watch(discountAtom);
    final shipping = context.watch(shippingCostAtom);

    final subtotal = items.fold(0.0, (sum, i) => sum + i.price);
    final tax = subtotal * taxRate;
    final total = subtotal + tax + shipping - discount;

    return Text('Total: \\\$\${total.toStringAsFixed(2)}');
  }
}`}
      />

      <CodeBlock
        title="AFTER -- logic extracted to a computed atom"
        code={`// Computed atom: reusable, testable, memoized
final orderTotalAtom = computed<double>((read) {
  final items = read(cartItemsAtom);
  final taxRate = read(taxRateAtom);
  final discount = read(discountAtom);
  final shipping = read(shippingCostAtom);

  final subtotal = items.fold(0.0, (sum, i) => sum + i.price);
  final tax = subtotal * taxRate;
  return subtotal + tax + shipping - discount;
}, name: 'orderTotal');

// Widget is now simple and focused
class OrderSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total = context.watch(orderTotalAtom);
    return Text('Total: \\\$\${total.toStringAsFixed(2)}');
  }
}`}
      />

      {/* reacton_cyclic_dependency */}
      <h3 id="lint-cyclic-dependency" className="text-lg font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_cyclic_dependency</code>{' '}
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-400">Error</span>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Detects circular dependencies between atoms. If atom A depends on atom B, and atom B depends on atom A (directly or through a chain), Reacton will throw at runtime. This lint rule catches the cycle at analysis time so you can fix it before running the app.
      </p>

      <CodeBlock
        title="BAD -- circular dependency"
        code={`// ERROR: reacton_cyclic_dependency
// atomA depends on atomB, and atomB depends on atomA
final atomA = computed<int>((read) {
  return read(atomB) + 1;  // atomA reads atomB
}, name: 'atomA');

final atomB = computed<int>((read) {
  return read(atomA) * 2;  // atomB reads atomA -- CYCLE!
}, name: 'atomB');`}
      />

      <CodeBlock
        title="GOOD -- break the cycle with a shared source"
        code={`// Introduce a base atom that both depend on
final baseValueAtom = atom<int>(0, name: 'baseValue');

final atomA = computed<int>((read) {
  return read(baseValueAtom) + 1;
}, name: 'atomA');

final atomB = computed<int>((read) {
  return read(baseValueAtom) * 2;
}, name: 'atomB');`}
      />

      {/* reacton_prefer_selector */}
      <h3 id="lint-prefer-selector" className="text-lg font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_prefer_selector</code>{' '}
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400">Info</span>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you watch an atom and then immediately access a single field from the result (e.g.,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch(userAtom).name</code>), this rule suggests using a selector instead. Selectors prevent unnecessary rebuilds when other fields of the object change but the selected field remains the same.
      </p>

      <CodeBlock
        title="BEFORE -- rebuilds on any user field change"
        code={`// INFO: reacton_prefer_selector
// Only using .name but rebuilding when .email, .avatar, etc. change
final name = context.watch(userAtom).name;`}
      />

      <CodeBlock
        title="AFTER -- only rebuilds when name changes"
        code={`// Selector: rebuilds only when the selected value changes
final name = context.watch(userAtom.select((u) => u.name));`}
      />

      {/* reacton_unused_atom */}
      <h3 id="lint-unused-atom" className="text-lg font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_unused_atom</code>{' '}
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400">Warning</span>
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Flags atoms that are declared but never referenced by any{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>, or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed()</code> call anywhere in the project. Dead atoms add mental overhead and should be removed.
      </p>

      <CodeBlock
        title="Example"
        code={`// WARNING: reacton_unused_atom
// This atom is never watched or read anywhere
final legacyCounterAtom = atom<int>(0, name: 'legacyCounter');`}
      />

      {/* Suppressing and configuring rules */}
      <h3 id="lint-configuration" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Suppressing and Configuring Rules
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can suppress individual lint diagnostics using standard Dart ignore comments:
      </p>

      <CodeBlock
        code={`// Suppress a single line
// ignore: reacton_avoid_read_in_build
final value = context.read(myAtom);

// Suppress for the entire file
// ignore_for_file: reacton_prefer_computed`}
      />

      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        To change the severity of a rule, configure it in your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">analysis_options.yaml</code>:
      </p>

      <CodeBlock
        language="yaml"
        title="analysis_options.yaml"
        code={`custom_lint:
  rules:
    - reacton_avoid_atom_in_build          # default: error
    - reacton_avoid_read_in_build          # default: warning
    - reacton_prefer_computed:
        severity: warning                # upgrade from info to warning
    - reacton_prefer_selector:
        severity: warning                # upgrade from info to warning
    - reacton_unused_atom:
        severity: error                  # upgrade from warning to error
    # Disable a rule entirely by omitting it from the list`}
      />

      {/* ================================================================== */}
      {/* SECTION 4: VS CODE EXTENSION                                       */}
      {/* ================================================================== */}
      <h2 id="vscode" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        VS Code Extension
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Reacton VS Code extension supercharges your development workflow with intelligent code snippets, an Atom Explorer sidebar, CodeLens annotations, an interactive dependency graph viewer, and widget wrapping commands. Install it from the VS Code marketplace by searching for{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Reacton for Flutter</code>{' '}
        or run:
      </p>

      <CodeBlock
        language="bash"
        code={`code --install-extension reacton-team.reacton-flutter`}
      />

      {/* Code Snippets */}
      <h3 id="vscode-snippets" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Code Snippets
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Type any snippet prefix in a Dart file and press Tab to expand. All snippets use tab stops for quick customization of names, types, and default values.
      </p>

      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Prefix</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Expansion</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">patom</code></td>
              <td className="py-3 px-4">Writable atom</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">final nameAtom = atom&lt;Type&gt;(value, name: 'name');</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pcomputed</code></td>
              <td className="py-3 px-4">Computed atom</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">final nameAtom = computed&lt;Type&gt;((read) =&gt; ..., name: 'name');</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pasync</code></td>
              <td className="py-3 px-4">Async atom</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">final nameAtom = asyncAtom&lt;Type&gt;((read) async =&gt; ..., name: 'name');</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pfamily</code></td>
              <td className="py-3 px-4">Family atom</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">final nameFamily = atomFamily&lt;Type, Param&gt;((param) =&gt; value, name: 'name');</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">peffect</code></td>
              <td className="py-3 px-4">Effect</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">final nameEffect = effect&lt;Type&gt;((context, payload) async {'{'} ... {'}'});</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pbuilder</code></td>
              <td className="py-3 px-4">ReactonBuilder widget</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">ReactonBuilder&lt;Type&gt;(atom: ..., builder: (ctx, val) {'{'} ... {'}'})</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pconsumer</code></td>
              <td className="py-3 px-4">ReactonConsumer widget</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">ReactonConsumer(builder: (ctx, ref) {'{'} ... {'}'})</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pscope</code></td>
              <td className="py-3 px-4">ReactonScope wrapper</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">ReactonScope(store: store, child: ...)</code></td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">plistener</code></td>
              <td className="py-3 px-4">ReactonListener widget</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">ReactonListener&lt;Type&gt;(atom: ..., onChanged: (val) {'{'} ... {'}'}, child: ...)</code></td>
            </tr>
            <tr>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pselector</code></td>
              <td className="py-3 px-4">ReactonSelector widget</td>
              <td className="py-3 px-4"><code className="text-xs font-mono text-gray-500 dark:text-gray-400">ReactonSelector&lt;T, S&gt;(atom: ..., selector: (val) =&gt; ..., builder: (ctx, sel) {'{'} ... {'}'})</code></td>
            </tr>
          </tbody>
        </table>
      </div>

      <h4 className="text-base font-semibold mb-3 text-gray-900 dark:text-white">Full Snippet Expansions</h4>

      <CodeBlock
        title="patom expansion"
        code={`// Type: patom → Tab
final counterAtom = atom<int>(0, name: 'counter');`}
      />

      <CodeBlock
        title="pcomputed expansion"
        code={`// Type: pcomputed → Tab
final totalAtom = computed<double>((read) {
  final items = read(cartItemsAtom);
  return items.fold(0.0, (sum, item) => sum + item.price);
}, name: 'total');`}
      />

      <CodeBlock
        title="pasync expansion"
        code={`// Type: pasync → Tab
final userProfileAtom = asyncAtom<UserProfile>((read) async {
  final userId = read(currentUserIdAtom);
  return await apiClient.fetchProfile(userId);
}, name: 'userProfile');`}
      />

      <CodeBlock
        title="pfamily expansion"
        code={`// Type: pfamily → Tab
final todoFamily = atomFamily<Todo, String>((id) {
  return Todo(id: id, title: '', completed: false);
}, name: 'todo');`}
      />

      <CodeBlock
        title="peffect expansion"
        code={`// Type: peffect → Tab
final submitFormEffect = effect<FormData>((context, formData) async {
  context.read(loadingAtom).set(true);
  try {
    await apiClient.submit(formData);
    context.read(successAtom).set(true);
  } finally {
    context.read(loadingAtom).set(false);
  }
});`}
      />

      <CodeBlock
        title="pbuilder expansion"
        code={`// Type: pbuilder → Tab
ReactonBuilder<int>(
  atom: counterAtom,
  builder: (context, value) {
    return Text('Count: \$value');
  },
)`}
      />

      <CodeBlock
        title="pconsumer expansion"
        code={`// Type: pconsumer → Tab
ReactonConsumer(
  builder: (context, ref) {
    final count = ref.watch(counterAtom);
    final user = ref.watch(userAtom);
    return Column(
      children: [
        Text('Count: \$count'),
        Text('User: \${user.name}'),
      ],
    );
  },
)`}
      />

      <CodeBlock
        title="pscope expansion"
        code={`// Type: pscope → Tab
ReactonScope(
  store: store,
  child: const MaterialApp(
    home: HomeScreen(),
  ),
)`}
      />

      <CodeBlock
        title="plistener expansion"
        code={`// Type: plistener → Tab
ReactonListener<String>(
  atom: errorMessageAtom,
  onChanged: (value) {
    if (value.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value)),
      );
    }
  },
  child: const HomeScreen(),
)`}
      />

      <CodeBlock
        title="pselector expansion"
        code={`// Type: pselector → Tab
ReactonSelector<User, String>(
  atom: userAtom,
  selector: (user) => user.displayName,
  builder: (context, displayName) {
    return Text('Hello, \$displayName!');
  },
)`}
      />

      {/* Atom Explorer Sidebar */}
      <h3 id="vscode-atom-explorer" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Atom Explorer Sidebar
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Atom Explorer appears as a panel in the VS Code sidebar (look for the Reacton icon in the activity bar). It scans your workspace for all atom declarations and organizes them into categories:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Writable Atoms</strong> -- All atoms created with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom()</code>. Each entry shows the atom name, its Dart type, and the file where it is declared.</li>
        <li><strong className="text-gray-900 dark:text-white">Computed Atoms</strong> -- All atoms created with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed()</code>. Each entry shows the dependency count as a badge (e.g., "3 deps").</li>
        <li><strong className="text-gray-900 dark:text-white">Async Atoms</strong> -- All atoms created with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">asyncAtom()</code>.</li>
        <li><strong className="text-gray-900 dark:text-white">Family Atoms</strong> -- All atom families created with <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atomFamily()</code>.</li>
      </ul>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Click any atom in the explorer to navigate directly to its declaration in the source file. The explorer automatically refreshes when files are saved.
      </p>

      {/* Code Lens */}
      <h3 id="vscode-codelens" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Code Lens
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The extension adds CodeLens annotations above every atom declaration in your Dart files. These annotations provide at-a-glance information without you needing to leave the editor:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Type information</strong> -- Displays the resolved Dart type above the atom declaration (e.g., <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Atom&lt;int&gt;</code> or <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Computed&lt;double&gt;</code>).</li>
        <li><strong className="text-gray-900 dark:text-white">Dependency count</strong> -- For computed and async atoms, shows how many atoms this atom reads from (e.g., "3 dependencies"). Click to see the list of dependency names.</li>
        <li><strong className="text-gray-900 dark:text-white">Subscriber count</strong> -- When a Flutter app is running in debug mode and connected, the CodeLens shows the live subscriber count for each atom (e.g., "2 subscribers"). This updates in real time as widgets mount and unmount.</li>
      </ul>

      <CodeBlock
        title="What CodeLens looks like in the editor"
        code={`// Atom<int> | 0 dependencies | 3 subscribers
final counterAtom = atom<int>(0, name: 'counter');

// Computed<double> | 4 dependencies | 1 subscriber
final orderTotalAtom = computed<double>((read) {
  // ...
}, name: 'orderTotal');`}
      />

      {/* Interactive Dependency Graph */}
      <h3 id="vscode-graph" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Interactive Dependency Graph
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Open the dependency graph by running the command{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Reacton: Show Dependency Graph</code>{' '}
        from the command palette (<code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Cmd+Shift+P</code> / <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Ctrl+Shift+P</code>). This opens a webview panel inside VS Code with a force-directed layout of all your atoms and their dependencies.
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li><strong className="text-gray-900 dark:text-white">Force-directed layout</strong> -- Nodes automatically arrange themselves based on their connections. Highly connected atoms cluster together, making architectural patterns visible.</li>
        <li><strong className="text-gray-900 dark:text-white">Click to navigate</strong> -- Click any node in the graph to open the corresponding source file and jump to the atom's declaration line.</li>
        <li><strong className="text-gray-900 dark:text-white">Color-coded by type</strong> -- Uses the same color scheme as the DevTools graph (blue for writable, purple for computed, green for async, amber for effects).</li>
        <li><strong className="text-gray-900 dark:text-white">Auto-refresh</strong> -- The graph updates automatically when you save a file that contains atom declarations.</li>
      </ul>

      {/* Wrap Widget Commands */}
      <h3 id="vscode-wrap-commands" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Wrap Widget Commands
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Quickly wrap existing widgets with Reacton wrappers using right-click context menu actions or the command palette:
      </p>

      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Command</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Context Menu</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">What It Does</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Reacton: Wrap with ReactonBuilder</code></td>
              <td className="py-3 px-4">Right-click &gt; "Wrap with ReactonBuilder"</td>
              <td className="py-3 px-4">Wraps the selected widget with a <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>, adding tab stops for atom and type</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Reacton: Wrap with ReactonConsumer</code></td>
              <td className="py-3 px-4">Right-click &gt; "Wrap with ReactonConsumer"</td>
              <td className="py-3 px-4">Wraps the selected widget tree with a <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code> for multi-atom access</td>
            </tr>
            <tr>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Reacton: Wrap with ReactonScope</code></td>
              <td className="py-3 px-4">Right-click &gt; "Wrap with ReactonScope"</td>
              <td className="py-3 px-4">Wraps the selected widget with a <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code> for scoped store overrides</td>
            </tr>
          </tbody>
        </table>
      </div>

      <CodeBlock
        title="Before wrapping"
        code={`// Select this widget, then right-click → "Wrap with ReactonBuilder"
Text('Hello, World!')`}
      />

      <CodeBlock
        title="After wrapping"
        code={`ReactonBuilder<Type>(
  atom: myAtom,
  builder: (context, value) {
    return Text('Hello, World!');
  },
)`}
      />

      {/* ================================================================== */}
      {/* SECTION 5: CODE GENERATION                                         */}
      {/* ================================================================== */}
      <h2 id="codegen" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Code Generation (reacton_generator)
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_generator</code> package integrates with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build_runner</code> to automatically generate serialization code and dependency graph metadata from your Dart source files. This eliminates boilerplate and enables advanced static analysis tooling.
      </p>

      <h3 id="codegen-setup" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Setup
      </h3>

      <CodeBlock
        language="yaml"
        title="pubspec.yaml"
        code={`dependencies:
  reacton: ^0.5.0
  reacton_annotations: ^0.1.0    # Provides @ReactonSerializable

dev_dependencies:
  reacton_generator: ^0.1.0      # Code generator
  build_runner: ^2.4.0         # Build system`}
      />

      <h3 id="codegen-serializable" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        @ReactonSerializable() Annotation
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Annotate your data classes with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">@ReactonSerializable()</code>{' '}
        to auto-generate <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">toJson()</code> and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">fromJson()</code> methods. These integrate seamlessly with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">PersistenceMiddleware</code> for automatic state persistence.
      </p>

      <div className="mb-6">
        <h4 className="text-base font-semibold mb-2 text-gray-900 dark:text-white">Supported Types</h4>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
          {['int', 'double', 'String', 'bool', 'DateTime', 'Duration', 'List<T>', 'Set<T>', 'Map<K,V>', 'enum values', 'Nested @ReactonSerializable', 'Nullable types (T?)'].map((type) => (
            <div key={type} className="px-3 py-2 rounded-lg bg-gray-50 dark:bg-gray-800/50 text-sm text-gray-700 dark:text-gray-300 font-mono">
              {type}
            </div>
          ))}
        </div>
      </div>

      <CodeBlock
        title="lib/models/user_settings.dart (source)"
        code={`import 'package:reacton_annotations/reacton_annotations.dart';

part 'user_settings.reacton.dart';

@ReactonSerializable()
class UserSettings {
  final String theme;
  final int fontSize;
  final bool notificationsEnabled;
  final DateTime lastUpdated;
  final List<String> favoriteCategories;
  final Map<String, bool> featureFlags;

  const UserSettings({
    required this.theme,
    required this.fontSize,
    required this.notificationsEnabled,
    required this.lastUpdated,
    this.favoriteCategories = const [],
    this.featureFlags = const {},
  });

  // Generated methods come from the part file
  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _\$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _\$UserSettingsToJson(this);
}`}
      />

      <CodeBlock
        title="lib/models/user_settings.reacton.dart (generated)"
        code={`// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated by reacton_generator

part of 'user_settings.dart';

UserSettings _\$UserSettingsFromJson(Map<String, dynamic> json) {
  return UserSettings(
    theme: json['theme'] as String,
    fontSize: json['fontSize'] as int,
    notificationsEnabled: json['notificationsEnabled'] as bool,
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    favoriteCategories: (json['favoriteCategories'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ??
        const [],
    featureFlags: (json['featureFlags'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as bool)) ??
        const {},
  );
}

Map<String, dynamic> _\$UserSettingsToJson(UserSettings instance) {
  return {
    'theme': instance.theme,
    'fontSize': instance.fontSize,
    'notificationsEnabled': instance.notificationsEnabled,
    'lastUpdated': instance.lastUpdated.toIso8601String(),
    'favoriteCategories': instance.favoriteCategories,
    'featureFlags': instance.featureFlags,
  };
}`}
      />

      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Once the serialization is generated, you can use it with the PersistenceMiddleware:
      </p>

      <CodeBlock
        title="Using generated code with PersistenceMiddleware"
        code={`final userSettingsAtom = atom<UserSettings>(
  UserSettings(
    theme: 'system',
    fontSize: 14,
    notificationsEnabled: true,
    lastUpdated: DateTime.now(),
  ),
  name: 'userSettings',
  persist: PersistConfig(
    toJson: (settings) => settings.toJson(),
    fromJson: (json) => UserSettings.fromJson(json),
  ),
);`}
      />

      {/* Graph Analyzer Builder */}
      <h3 id="codegen-graph-analyzer" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Graph Analyzer Builder
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        In addition to serialization, <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_generator</code> includes a Graph Analyzer builder that scans your entire source tree for atom declarations (calls to{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">asyncAtom()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atomFamily()</code>) and generates a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.reacton_graph.json</code> file at the project root.
      </p>

      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        This JSON file contains the complete dependency graph and is consumed by:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>The <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton analyze</code> CLI command for dead atom detection and cycle detection</li>
        <li>The VS Code extension for the Atom Explorer and CodeLens</li>
        <li>The DevTools extension for the static graph view (before the app is running)</li>
        <li>CI pipelines that want to enforce graph-level constraints</li>
      </ul>

      {/* Running Code Generation */}
      <h3 id="codegen-running" className="text-xl font-semibold mt-10 mb-3 text-gray-900 dark:text-white">
        Running Code Generation
      </h3>

      <CodeBlock
        language="bash"
        title="One-time build"
        code={`# Generate all files once
dart run build_runner build

# Delete previously generated files and rebuild from scratch
dart run build_runner build --delete-conflicting-outputs`}
      />

      <CodeBlock
        language="bash"
        title="Watch mode (auto-regenerate on save)"
        code={`# Start the watcher -- regenerates when source files change
dart run build_runner watch

# Watch with conflict resolution
dart run build_runner watch --delete-conflicting-outputs`}
      />

      <Callout type="info" title="Generated File Naming">
        All generated files follow the convention{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">*.reacton.dart</code> (e.g.,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">user_settings.reacton.dart</code>). Add{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">*.reacton.dart</code> to your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">.gitignore</code> if you prefer not to commit generated files, or commit them for faster CI builds.
      </Callout>

      {/* ================================================================== */}
      {/* SECTION 6: ECOSYSTEM OVERVIEW                                      */}
      {/* ================================================================== */}
      <h2 id="ecosystem" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Ecosystem Overview
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The Reacton ecosystem consists of multiple packages that work together. Here is a complete overview of every package, its purpose, and when you need it.
      </p>

      <h3 id="ecosystem-packages" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Package Reference
      </h3>

      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Package</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Version</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Type</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton</code></td>
              <td className="py-3 px-4">^0.5.0</td>
              <td className="py-3 px-4">dependency</td>
              <td className="py-3 px-4">Core library: atoms, computed, effects, middleware, store</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter_reacton</code></td>
              <td className="py-3 px-4">^0.5.0</td>
              <td className="py-3 px-4">dependency</td>
              <td className="py-3 px-4">Flutter bindings: ReactonScope, ReactonBuilder, ReactonConsumer, context extensions</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_annotations</code></td>
              <td className="py-3 px-4">^0.1.0</td>
              <td className="py-3 px-4">dependency</td>
              <td className="py-3 px-4">Annotation classes for code generation (@ReactonSerializable)</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_test</code></td>
              <td className="py-3 px-4">^0.2.0</td>
              <td className="py-3 px-4">dev_dependency</td>
              <td className="py-3 px-4">Testing utilities: TestStore, mock atoms, matchers</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_devtools</code></td>
              <td className="py-3 px-4">^0.2.0</td>
              <td className="py-3 px-4">dev_dependency</td>
              <td className="py-3 px-4">DevTools extension middleware and panel</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_lint</code></td>
              <td className="py-3 px-4">^0.3.0</td>
              <td className="py-3 px-4">dev_dependency</td>
              <td className="py-3 px-4">Custom lint rules for Reacton best practices</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_generator</code></td>
              <td className="py-3 px-4">^0.1.0</td>
              <td className="py-3 px-4">dev_dependency</td>
              <td className="py-3 px-4">Code generator for serialization and graph analysis</td>
            </tr>
            <tr>
              <td className="py-3 px-4"><code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton_cli</code></td>
              <td className="py-3 px-4">^0.4.0</td>
              <td className="py-3 px-4">global tool</td>
              <td className="py-3 px-4">CLI for scaffolding, graph visualization, analysis, and diagnostics</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 id="ecosystem-use-cases" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Which Packages to Install
      </h3>

      <div className="space-y-4 mb-6">
        <div className="p-4 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">Basic App</h4>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">The minimum packages needed to build a Flutter app with Reacton.</p>
          <CodeBlock
            language="yaml"
            code={`dependencies:
  reacton: ^0.5.0
  flutter_reacton: ^0.5.0`}
          />
        </div>

        <div className="p-4 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">With Testing</h4>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">Add testing utilities for unit and widget tests.</p>
          <CodeBlock
            language="yaml"
            code={`dependencies:
  reacton: ^0.5.0
  flutter_reacton: ^0.5.0

dev_dependencies:
  reacton_test: ^0.2.0`}
          />
        </div>

        <div className="p-4 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">With Tooling</h4>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">Add lint rules and DevTools for better developer experience.</p>
          <CodeBlock
            language="yaml"
            code={`dependencies:
  reacton: ^0.5.0
  flutter_reacton: ^0.5.0

dev_dependencies:
  reacton_test: ^0.2.0
  reacton_lint: ^0.3.0
  reacton_devtools: ^0.2.0
  custom_lint: ^0.6.0

# Also install the CLI globally:
# dart pub global activate reacton_cli`}
          />
        </div>

        <div className="p-4 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">Full Ecosystem</h4>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">Everything: core, Flutter bindings, testing, linting, DevTools, and code generation.</p>
          <CodeBlock
            language="yaml"
            code={`dependencies:
  reacton: ^0.5.0
  flutter_reacton: ^0.5.0
  reacton_annotations: ^0.1.0

dev_dependencies:
  reacton_test: ^0.2.0
  reacton_lint: ^0.3.0
  reacton_devtools: ^0.2.0
  reacton_generator: ^0.1.0
  custom_lint: ^0.6.0
  build_runner: ^2.4.0

# Also install the CLI globally:
# dart pub global activate reacton_cli

# And install the VS Code extension:
# code --install-extension reacton-team.reacton-flutter`}
          />
        </div>
      </div>

      <Callout type="tip" title="Quick Start">
        The fastest way to get started with the full ecosystem is to run{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton init --lint --devtools --codegen</code>{' '}
        in your project directory. This will add all dependencies, configure lint rules, and create the recommended folder structure in a single command.
      </Callout>

      <PageNav
        prev={{ title: 'Testing', path: '/testing' }}
      />
    </div>
  )
}
