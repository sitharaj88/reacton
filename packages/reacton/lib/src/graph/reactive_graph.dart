import '../core/reacton_base.dart';
import '../core/readonly_reacton.dart';
import '../core/writable_reacton.dart';
import 'node.dart';
import 'scheduler.dart';
import 'topology.dart';

/// Callback for when a node's value changes.
typedef NodeChangeCallback = void Function(ReactonRef ref);

/// The core reactive graph engine.
///
/// This is the heart of Reacton. It maintains a directed acyclic graph (DAG)
/// of reacton dependencies and handles efficient glitch-free propagation
/// of state changes using a two-phase mark/propagate algorithm.
///
/// ## Two-Phase Algorithm
///
/// **Phase 1 (Mark):** When a writable reacton is set, mark it `Dirty`.
/// Walk all descendants: mark immediate children as `Check`, and
/// recursively mark their descendants as `Check`.
///
/// **Phase 2 (Propagate):** Process nodes in topological order (by level).
/// For `Check` nodes, verify whether any source actually changed value.
/// If so, recompute. If not, mark `Clean` without recomputation.
class ReactiveGraph {
  final Map<ReactonRef, GraphNode> _nodes = {};
  final TopologicalSorter _sorter = TopologicalSorter();
  final UpdateScheduler _scheduler = UpdateScheduler();

  /// Global epoch counter, incremented on each mutation round.
  int _globalEpoch = 0;

  /// Callback invoked when a node's value changes (used by ReactonStore).
  NodeChangeCallback? onNodeChanged;

  /// Nodes that have been dirtied in the current batch.
  final Set<GraphNode> _dirtyRoots = {};

  /// The update scheduler for batching.
  UpdateScheduler get scheduler => _scheduler;

  /// All nodes in the graph.
  Iterable<GraphNode> get nodes => _nodes.values;

  /// Get a node by its ref, or null if not registered.
  GraphNode? getNode(ReactonRef ref) => _nodes[ref];

  ReactiveGraph() {
    _scheduler.onFlush = _propagate;
  }

  /// Register a writable (source) reacton in the graph.
  GraphNode registerWritable(WritableReacton reacton) {
    return _nodes.putIfAbsent(
      reacton.ref,
      () => GraphNode(ref: reacton.ref, level: 0, isComputed: false),
    );
  }

  /// Register a computed (derived) reacton with its dependencies.
  GraphNode registerComputed(
    ReadonlyReacton reacton,
    List<ReactonRef> dependencies,
  ) {
    var node = _nodes[reacton.ref];
    if (node == null) {
      node = GraphNode(ref: reacton.ref, isComputed: true);
      _nodes[reacton.ref] = node;
    }

    // Clear old dependencies and set new ones
    node.clearSources();
    for (final depRef in dependencies) {
      final sourceNode = _nodes[depRef];
      if (sourceNode != null) {
        node.addSource(sourceNode);
      }
    }

    node.state = NodeState.clean;
    return node;
  }

  /// Register an effect node.
  GraphNode registerEffect(ReactonRef ref, List<ReactonRef> dependencies) {
    var node = _nodes[ref];
    if (node == null) {
      node = GraphNode(ref: ref, isComputed: true);
      _nodes[ref] = node;
    }

    node.clearSources();
    for (final depRef in dependencies) {
      final sourceNode = _nodes[depRef];
      if (sourceNode != null) {
        node.addSource(sourceNode);
      }
    }

    node.state = NodeState.clean;
    return node;
  }

  /// Mark a writable reacton as dirty (Phase 1 entry point).
  ///
  /// Called by ReactonStore when a writable reacton's value changes.
  void markDirty(ReactonRef ref) {
    final node = _nodes[ref];
    if (node == null) return;

    _globalEpoch++;
    node.state = NodeState.dirty;
    node.epoch = _globalEpoch;
    _dirtyRoots.add(node);

    // Phase 1: Mark all descendants as Check
    _markDescendants(node);

    _scheduler.scheduleFlush();
  }

  /// Phase 1: Walk the observer graph and mark descendants as Check.
  void _markDescendants(GraphNode node) {
    for (final observer in node.observers) {
      if (observer.state == NodeState.clean) {
        observer.state = NodeState.check;
        _markDescendants(observer);
      }
    }
  }

  /// Phase 2: Propagate changes through the graph in topological order.
  void _propagate() {
    if (_dirtyRoots.isEmpty) return;

    // Collect all affected (non-clean) nodes
    final affected = <GraphNode>{};
    for (final root in _dirtyRoots) {
      _collectAffected(root, affected);
    }
    _dirtyRoots.clear();

    // Sort in topological order
    final sorted = _sorter.sort(affected);

    // Process each node
    for (final node in sorted) {
      if (node.state == NodeState.clean) continue;

      if (node.state == NodeState.check) {
        // Verify: did any source actually change in this epoch?
        final sourcesChanged = node.sources.any(
          (s) => s.epoch == _globalEpoch,
        );

        if (!sourcesChanged) {
          // No source changed: skip recomputation
          node.state = NodeState.clean;
          continue;
        }

        // At least one source changed: need to recompute
        node.state = NodeState.dirty;
      }

      if (node.state == NodeState.dirty) {
        if (node.isComputed) {
          // Signal to ReactonStore that this node needs recomputation
          node.epoch = _globalEpoch;
          onNodeChanged?.call(node.ref);
        }
        node.state = NodeState.clean;
      }
    }
  }

  /// Collect all non-clean nodes reachable from [node] (including itself).
  void _collectAffected(GraphNode node, Set<GraphNode> result) {
    if (!result.add(node)) return;
    for (final observer in node.observers) {
      if (observer.state != NodeState.clean) {
        _collectAffected(observer, result);
      }
    }
  }

  /// Unregister a node and remove all its edges.
  void unregister(ReactonRef ref) {
    final node = _nodes.remove(ref);
    if (node != null) {
      // Remove from all sources' observer lists
      for (final source in List.of(node.sources)) {
        source.observers.remove(node);
      }
      // Remove from all observers' source lists
      for (final observer in List.of(node.observers)) {
        observer.sources.remove(node);
      }
    }
  }

  /// Check if a ref is registered.
  bool contains(ReactonRef ref) => _nodes.containsKey(ref);

  /// Get the number of nodes in the graph.
  int get nodeCount => _nodes.length;

  /// Detect if adding an edge from [source] to [target] would create a cycle.
  bool wouldCreateCycle(ReactonRef source, ReactonRef target) {
    final sourceNode = _nodes[source];
    final targetNode = _nodes[target];
    if (sourceNode == null || targetNode == null) return false;

    // Check if target is reachable from source (via observers)
    return _isReachable(targetNode, sourceNode);
  }

  bool _isReachable(GraphNode from, GraphNode to) {
    if (from == to) return true;
    for (final observer in from.observers) {
      if (_isReachable(observer, to)) return true;
    }
    return false;
  }

  /// Dispose the graph and clear all nodes.
  void dispose() {
    _nodes.clear();
    _dirtyRoots.clear();
  }
}
