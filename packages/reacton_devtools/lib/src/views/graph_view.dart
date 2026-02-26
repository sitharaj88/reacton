import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/reacton_service.dart';

/// Interactive dependency graph visualization.
///
/// Displays reactons as nodes and dependencies as edges using a
/// force-directed layout. Nodes are colored by type:
/// - Blue: Writable reactons
/// - Green: Computed reactons
/// - Orange: Async reactons
/// - Red: Effect nodes
class GraphView extends StatefulWidget {
  final ReactonDevToolsService service;

  const GraphView({super.key, required this.service});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  GraphData? _graph;
  bool _loading = true;
  String? _error;
  int? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  Future<void> _loadGraph() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final graph = await widget.service.getGraph();
      setState(() {
        _graph = graph;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Failed to load graph: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGraph,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final graph = _graph!;
    if (graph.nodes.isEmpty) {
      return const Center(
        child: Text('No reactons registered yet. Create reactons to see the graph.'),
      );
    }

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Text(
                'Dependency Graph',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text('${graph.nodes.length} reactons'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadGraph,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _LegendItem(color: Colors.blue, label: 'Writable'),
              const SizedBox(width: 12),
              _LegendItem(color: Colors.green, label: 'Computed'),
              const SizedBox(width: 12),
              _LegendItem(color: Colors.orange, label: 'Async'),
            ],
          ),
        ),

        // Graph canvas
        Expanded(
          child: CustomPaint(
            painter: _GraphPainter(
              nodes: graph.nodes,
              edges: graph.edges,
              selectedNodeId: _selectedNodeId,
            ),
            child: GestureDetector(
              onTapDown: (details) => _handleTap(details, graph),
            ),
          ),
        ),

        // Selected node details
        if (_selectedNodeId != null)
          _NodeDetailPanel(
            node: graph.nodes.firstWhere((n) => n.id == _selectedNodeId),
          ),
      ],
    );
  }

  void _handleTap(TapDownDetails details, GraphData graph) {
    // Simple hit-testing against node positions
    final positions = _calculatePositions(graph.nodes);
    const nodeRadius = 24.0;

    for (final entry in positions.entries) {
      final dx = details.localPosition.dx - entry.value.dx;
      final dy = details.localPosition.dy - entry.value.dy;
      if (dx * dx + dy * dy < nodeRadius * nodeRadius) {
        setState(() => _selectedNodeId = entry.key);
        return;
      }
    }
    setState(() => _selectedNodeId = null);
  }

  Map<int, Offset> _calculatePositions(List<GraphNodeData> nodes) {
    // Simple level-based layout
    final positions = <int, Offset>{};
    final byLevel = <int, List<GraphNodeData>>{};

    for (final node in nodes) {
      byLevel.putIfAbsent(node.level, () => []).add(node);
    }

    for (final entry in byLevel.entries) {
      final y = 80.0 + entry.key * 100.0;
      final count = entry.value.length;
      for (var i = 0; i < count; i++) {
        final x = 100.0 + i * 120.0;
        positions[entry.value[i].id] = Offset(x, y);
      }
    }

    return positions;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _NodeDetailPanel extends StatelessWidget {
  final GraphNodeData node;

  const _NodeDetailPanel({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: const Border(top: BorderSide(width: 1, color: Colors.grey)),
      ),
      child: Row(
        children: [
          Icon(
            node.type == 'writable' ? Icons.edit : Icons.functions,
            color: _getNodeColor(node.type),
          ),
          const SizedBox(width: 8),
          Text(node.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 16),
          Chip(label: Text(node.type)),
          const SizedBox(width: 8),
          Chip(label: Text('Level ${node.level}')),
          const SizedBox(width: 8),
          Chip(label: Text('${node.subscriberCount} subscribers')),
          const Spacer(),
          Chip(
            label: Text(node.state),
            backgroundColor: node.state == 'clean' ? Colors.green.shade100 : Colors.orange.shade100,
          ),
        ],
      ),
    );
  }
}

Color _getNodeColor(String type) {
  return switch (type) {
    'writable' => Colors.blue,
    'computed' => Colors.green,
    'async' => Colors.orange,
    'effect' => Colors.red,
    _ => Colors.grey,
  };
}

class _GraphPainter extends CustomPainter {
  final List<GraphNodeData> nodes;
  final List<GraphEdgeData> edges;
  final int? selectedNodeId;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    // Calculate positions using level-based layout
    final positions = <int, Offset>{};
    final byLevel = <int, List<GraphNodeData>>{};

    for (final node in nodes) {
      byLevel.putIfAbsent(node.level, () => []).add(node);
    }

    for (final entry in byLevel.entries) {
      final y = 60.0 + entry.key * 90.0;
      final count = entry.value.length;
      final spacing = size.width / (count + 1);
      for (var i = 0; i < count; i++) {
        positions[entry.value[i].id] = Offset(spacing * (i + 1), y);
      }
    }

    // Draw edges
    final edgePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = positions[edge.from];
      final to = positions[edge.to];
      if (from != null && to != null) {
        _drawArrow(canvas, from, to, edgePaint);
      }
    }

    // Draw nodes
    for (final node in nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;

      final isSelected = node.id == selectedNodeId;
      final color = _getNodeColor(node.type);
      final radius = isSelected ? 28.0 : 22.0;

      // Shadow
      canvas.drawCircle(
        pos + const Offset(2, 2),
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.1),
      );

      // Fill
      canvas.drawCircle(pos, radius, Paint()..color = color);

      // Selection ring
      if (isSelected) {
        canvas.drawCircle(
          pos,
          radius + 3,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke,
        );
      }

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _truncate(node.name, 8),
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: 60);
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final direction = (to - from);
    final length = direction.distance;
    if (length == 0) return;

    final unit = direction / length;
    final adjustedTo = to - unit * 24; // stop at node edge

    canvas.drawLine(from + unit * 24, adjustedTo, paint);

    // Arrowhead
    final arrowSize = 8.0;
    final angle = math.atan2(unit.dy, unit.dx);
    final path = Path()
      ..moveTo(adjustedTo.dx, adjustedTo.dy)
      ..lineTo(
        adjustedTo.dx - arrowSize * math.cos(angle - 0.4),
        adjustedTo.dy - arrowSize * math.sin(angle - 0.4),
      )
      ..lineTo(
        adjustedTo.dx - arrowSize * math.cos(angle + 0.4),
        adjustedTo.dy - arrowSize * math.sin(angle + 0.4),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.grey.shade400);
  }

  String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen - 1)}...';
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.edges != edges ||
      oldDelegate.selectedNodeId != selectedNodeId;
}
