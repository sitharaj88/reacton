import 'dart:convert';

/// Client-side service for communicating with the Reacton DevTools extension.
///
/// Used by the DevTools extension UI to fetch state data from the app.
class ReactonDevToolsService {
  final Future<String> Function(String method, Map<String, String> params)
      _callServiceExtension;

  ReactonDevToolsService(this._callServiceExtension);

  /// Get the reactive dependency graph.
  Future<GraphData> getGraph() async {
    final result = await _callServiceExtension('ext.reacton.getGraph', {});
    final json = jsonDecode(result) as Map<String, dynamic>;

    final nodes = (json['nodes'] as List)
        .map((n) => GraphNodeData.fromJson(n as Map<String, dynamic>))
        .toList();
    final edges = (json['edges'] as List)
        .map((e) => GraphEdgeData.fromJson(e as Map<String, dynamic>))
        .toList();

    return GraphData(nodes: nodes, edges: edges);
  }

  /// Get a specific reacton's value.
  Future<ReactonValueData> getReactonValue(int refId) async {
    final result = await _callServiceExtension(
      'ext.reacton.getReactonValue',
      {'refId': '$refId'},
    );
    final json = jsonDecode(result) as Map<String, dynamic>;
    return ReactonValueData.fromJson(json);
  }

  /// Get the list of all reactons.
  Future<List<ReactonListEntry>> getReactonList() async {
    final result = await _callServiceExtension('ext.reacton.getReactonList', {});
    final json = jsonDecode(result) as Map<String, dynamic>;
    return (json['reactons'] as List)
        .map((a) => ReactonListEntry.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Get store statistics.
  Future<StoreStats> getStats() async {
    final result = await _callServiceExtension('ext.reacton.getStats', {});
    final json = jsonDecode(result) as Map<String, dynamic>;
    return StoreStats.fromJson(json);
  }

  /// Get timeline entries (state change history).
  ///
  /// Pass [since] to only fetch entries after that index (for incremental updates).
  Future<TimelineData> getTimeline({int since = 0}) async {
    final result = await _callServiceExtension(
      'ext.reacton.getTimeline',
      {'since': '$since'},
    );
    final json = jsonDecode(result) as Map<String, dynamic>;
    return TimelineData.fromJson(json);
  }

  /// Clear the timeline buffer.
  ///
  /// Optionally [pause] or resume timeline capture.
  Future<void> clearTimeline({bool? pause}) async {
    final params = <String, String>{};
    if (pause != null) params['pause'] = '$pause';
    await _callServiceExtension('ext.reacton.clearTimeline', params);
  }

  /// Get per-reacton performance metrics.
  Future<List<PerformanceEntry>> getPerformance() async {
    final result =
        await _callServiceExtension('ext.reacton.getPerformance', {});
    final json = jsonDecode(result) as Map<String, dynamic>;
    return (json['reactons'] as List)
        .map((e) => PerformanceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// The full reactive dependency graph with nodes and edges.
class GraphData {
  /// All reacton nodes in the graph.
  final List<GraphNodeData> nodes;

  /// All dependency edges between nodes.
  final List<GraphEdgeData> edges;
  const GraphData({required this.nodes, required this.edges});
}

/// A single node in the reactive dependency graph.
class GraphNodeData {
  final int id;
  final String name;
  final String type;
  final String state;
  final int epoch;
  final int level;
  final int subscriberCount;

  const GraphNodeData({
    required this.id,
    required this.name,
    required this.type,
    required this.state,
    required this.epoch,
    required this.level,
    required this.subscriberCount,
  });

  factory GraphNodeData.fromJson(Map<String, dynamic> json) => GraphNodeData(
        id: json['id'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        state: json['state'] as String,
        epoch: json['epoch'] as int,
        level: json['level'] as int,
        subscriberCount: json['subscriberCount'] as int,
      );
}

/// A directed edge representing a dependency between two graph nodes.
class GraphEdgeData {
  /// The source node id.
  final int from;

  /// The target node id.
  final int to;
  const GraphEdgeData({required this.from, required this.to});

  factory GraphEdgeData.fromJson(Map<String, dynamic> json) => GraphEdgeData(
        from: json['from'] as int,
        to: json['to'] as int,
      );
}

/// The current value of a single reacton.
class ReactonValueData {
  final int refId;
  final String value;
  final String type;

  const ReactonValueData({
    required this.refId,
    required this.value,
    required this.type,
  });

  factory ReactonValueData.fromJson(Map<String, dynamic> json) =>
      ReactonValueData(
        refId: json['refId'] as int,
        value: json['value'] as String,
        type: json['type'] as String,
      );
}

/// Summary of a reacton for list display in the inspector.
class ReactonListEntry {
  final int id;
  final String name;
  final String value;
  final String type;
  final int subscribers;

  const ReactonListEntry({
    required this.id,
    required this.name,
    required this.value,
    required this.type,
    required this.subscribers,
  });

  factory ReactonListEntry.fromJson(Map<String, dynamic> json) =>
      ReactonListEntry(
        id: json['id'] as int,
        name: json['name'] as String,
        value: json['value'] as String,
        type: json['type'] as String,
        subscribers: json['subscribers'] as int,
      );
}

/// Aggregate statistics for the reactive store.
class StoreStats {
  final int reactonCount;
  final int nodeCount;
  final int timelineEntries;
  final int trackedReactons;

  const StoreStats({
    required this.reactonCount,
    required this.nodeCount,
    this.timelineEntries = 0,
    this.trackedReactons = 0,
  });

  factory StoreStats.fromJson(Map<String, dynamic> json) => StoreStats(
        reactonCount: json['reactonCount'] as int,
        nodeCount: json['nodeCount'] as int,
        timelineEntries: (json['timelineEntries'] as int?) ?? 0,
        trackedReactons: (json['trackedReactons'] as int?) ?? 0,
      );
}

/// A single timeline entry representing a state change.
class TimelineEntryData {
  final int refId;
  final String name;
  final String type;
  final String oldValue;
  final String newValue;
  final DateTime timestamp;
  final int propagationMicros;

  const TimelineEntryData({
    required this.refId,
    required this.name,
    required this.type,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    required this.propagationMicros,
  });

  factory TimelineEntryData.fromJson(Map<String, dynamic> json) =>
      TimelineEntryData(
        refId: json['refId'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        oldValue: json['oldValue'] as String,
        newValue: json['newValue'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        propagationMicros: json['propagationMicros'] as int,
      );
}

/// Timeline response with entries and metadata.
class TimelineData {
  final List<TimelineEntryData> entries;
  final int total;
  final bool paused;

  const TimelineData({
    required this.entries,
    required this.total,
    required this.paused,
  });

  factory TimelineData.fromJson(Map<String, dynamic> json) => TimelineData(
        entries: (json['entries'] as List)
            .map(
                (e) => TimelineEntryData.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        paused: json['paused'] as bool,
      );
}

/// Per-reacton performance metrics.
class PerformanceEntry {
  final int refId;
  final String name;
  final String type;
  final int recomputeCount;
  final int avgPropagationMicros;
  final int subscriberCount;

  const PerformanceEntry({
    required this.refId,
    required this.name,
    required this.type,
    required this.recomputeCount,
    required this.avgPropagationMicros,
    required this.subscriberCount,
  });

  factory PerformanceEntry.fromJson(Map<String, dynamic> json) =>
      PerformanceEntry(
        refId: json['refId'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        recomputeCount: json['recomputeCount'] as int,
        avgPropagationMicros: json['avgPropagationMicros'] as int,
        subscriberCount: json['subscriberCount'] as int,
      );
}
