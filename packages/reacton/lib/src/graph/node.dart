import '../core/reacton_base.dart';

/// The reactivity state of a graph node.
///
/// Inspired by the Leptos/Reactively model:
/// - [clean]: Value is current and valid.
/// - [check]: A dependency might have changed; needs verification.
/// - [dirty]: Value is known to be stale; must recompute.
enum NodeState {
  /// Value is current and valid.
  clean,

  /// A dependency might have changed; needs verification before use.
  check,

  /// Value is known to be stale and must be recomputed.
  dirty,
}

/// Internal representation of a node in the reactive dependency graph.
///
/// Each reacton (writable, computed, async, effect) becomes a [GraphNode]
/// when registered with the [ReactiveGraph].
class GraphNode<T> {
  /// The reacton reference this node represents.
  final ReactonRef ref;

  /// Nodes this depends on (parents in the DAG).
  final List<GraphNode> sources;

  /// Nodes that depend on this (children in the DAG).
  final List<GraphNode> observers;

  /// Current reactivity state.
  NodeState state;

  /// Version counter - incremented each time the value changes.
  int epoch;

  /// The depth level in the graph (for topological ordering).
  /// Writable reactons (no sources) are level 0.
  int level;

  /// Whether this is a computed/derived node (needs recomputation).
  final bool isComputed;

  /// Whether this node has active subscribers (widgets/effects watching it).
  bool get hasActiveSubscribers => _subscriberCount > 0;

  int _subscriberCount = 0;

  /// Increment the subscriber count.
  void addSubscriber() => _subscriberCount++;

  /// Decrement the subscriber count.
  void removeSubscriber() {
    _subscriberCount--;
    assert(_subscriberCount >= 0, 'Subscriber count went negative');
  }

  /// Current subscriber count.
  int get subscriberCount => _subscriberCount;

  GraphNode({
    required this.ref,
    this.state = NodeState.clean,
    this.epoch = 0,
    this.level = 0,
    this.isComputed = false,
  })  : sources = [],
        observers = [];

  /// Add a dependency on another node.
  void addSource(GraphNode source) {
    if (!sources.contains(source)) {
      sources.add(source);
      source.observers.add(this);
      // Update level to be deeper than all sources
      _updateLevel();
    }
  }

  /// Remove a dependency on another node.
  void removeSource(GraphNode source) {
    sources.remove(source);
    source.observers.remove(this);
    _updateLevel();
  }

  /// Remove all dependencies.
  void clearSources() {
    for (final source in List.of(sources)) {
      source.observers.remove(this);
    }
    sources.clear();
    level = 0;
  }

  /// Recalculate the level based on sources.
  void _updateLevel() {
    if (sources.isEmpty) {
      level = 0;
    } else {
      level = sources.fold<int>(0, (max, s) => s.level > max ? s.level : max) + 1;
    }
  }

  @override
  int get hashCode => ref.hashCode;

  @override
  bool operator ==(Object other) => other is GraphNode && other.ref == ref;

  @override
  String toString() => 'GraphNode($ref, state: $state, level: $level)';
}
