import 'package:collection/collection.dart';
import 'node.dart';

/// Sorts graph nodes in topological order using level-based ordering.
///
/// Nodes are processed by their level (depth in the graph), ensuring
/// all sources are processed before their observers. Nodes at the
/// same level are processed in insertion order for deterministic behavior.
class TopologicalSorter {
  /// Sort the given nodes by their level (depth in graph).
  ///
  /// Returns a list where all source nodes come before their observer nodes.
  /// This ensures glitch-free propagation: when processing a node, all
  /// its dependencies are already up-to-date.
  List<GraphNode> sort(Iterable<GraphNode> nodes) {
    final list = nodes.toList();
    // Sort by level first, then by ref id for deterministic ordering
    list.sort((a, b) {
      final levelCmp = a.level.compareTo(b.level);
      if (levelCmp != 0) return levelCmp;
      return a.ref.id.compareTo(b.ref.id);
    });
    return list;
  }

  /// Collect all nodes reachable from the given dirty/check nodes.
  ///
  /// Walks the observer graph from the starting nodes and collects
  /// all nodes that are not [NodeState.clean].
  Set<GraphNode> collectAffected(Iterable<GraphNode> startNodes) {
    final affected = <GraphNode>{};
    final queue = QueueList<GraphNode>.from(startNodes);

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      if (affected.add(node)) {
        for (final observer in node.observers) {
          if (observer.state != NodeState.clean) {
            queue.add(observer);
          }
        }
      }
    }

    return affected;
  }
}
