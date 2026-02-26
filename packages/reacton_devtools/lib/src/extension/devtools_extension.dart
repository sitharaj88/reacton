import 'dart:developer' as developer;
import 'dart:convert';

import 'package:reacton/reacton.dart';

/// A single state change event captured by the DevTools extension.
class _TimelineEvent {
  final int refId;
  final String name;
  final String type;
  final String oldValue;
  final String newValue;
  final DateTime timestamp;
  final int propagationMicros;

  _TimelineEvent({
    required this.refId,
    required this.name,
    required this.type,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    required this.propagationMicros,
  });

  Map<String, dynamic> toJson() => {
        'refId': refId,
        'name': name,
        'type': type,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': timestamp.toIso8601String(),
        'propagationMicros': propagationMicros,
      };
}

/// Per-reacton performance tracking data.
class _PerfTracker {
  int recomputeCount = 0;
  int totalPropagationMicros = 0;
  int get avgPropagationMicros =>
      recomputeCount > 0 ? totalPropagationMicros ~/ recomputeCount : 0;
}

/// Registers Reacton service extensions for DevTools communication.
///
/// Call [ReactonDevToolsExtension.install] to enable DevTools integration.
///
/// ```dart
/// final store = ReactonStore();
/// ReactonDevToolsExtension.install(store);
/// ```
class ReactonDevToolsExtension {
  final ReactonStore _store;
  bool _installed = false;

  /// Ring buffer of recent timeline events (max 500).
  final List<_TimelineEvent> _timeline = [];
  static const _maxTimelineEntries = 500;

  /// Per-reacton performance tracking (keyed by ref id).
  final Map<int, _PerfTracker> _perfTrackers = {};

  /// Whether timeline capture is paused.
  bool _timelinePaused = false;

  ReactonDevToolsExtension(this._store);

  /// Install DevTools service extensions for this store.
  static void install(ReactonStore store) {
    final ext = ReactonDevToolsExtension(store);
    ext._register();
  }

  void _register() {
    if (_installed) return;
    _installed = true;

    // Hook into the store's value change notifications
    _store.setDevToolsListener(_onValueChanged);

    developer.registerExtension(
      'ext.reacton.getGraph',
      _handleGetGraph,
    );

    developer.registerExtension(
      'ext.reacton.getReactonValue',
      _handleGetReactonValue,
    );

    developer.registerExtension(
      'ext.reacton.setReactonValue',
      _handleSetReactonValue,
    );

    developer.registerExtension(
      'ext.reacton.getReactonList',
      _handleGetReactonList,
    );

    developer.registerExtension(
      'ext.reacton.getStats',
      _handleGetStats,
    );

    developer.registerExtension(
      'ext.reacton.getTimeline',
      _handleGetTimeline,
    );

    developer.registerExtension(
      'ext.reacton.clearTimeline',
      _handleClearTimeline,
    );

    developer.registerExtension(
      'ext.reacton.getPerformance',
      _handleGetPerformance,
    );
  }

  /// Called whenever any reacton value changes.
  void _onValueChanged(ReactonRef ref, dynamic oldValue, dynamic newValue) {
    final stopwatch = Stopwatch()..start();
    final node = _store.graph.getNode(ref);
    final nodeType = _resolveNodeType(node);

    // Track performance
    final tracker = _perfTrackers.putIfAbsent(ref.id, () => _PerfTracker());
    tracker.recomputeCount++;

    // Capture timeline event (unless paused)
    if (!_timelinePaused) {
      stopwatch.stop();
      final event = _TimelineEvent(
        refId: ref.id,
        name: ref.toString(),
        type: nodeType,
        oldValue: _safeToString(oldValue),
        newValue: _safeToString(newValue),
        timestamp: DateTime.now(),
        propagationMicros: stopwatch.elapsedMicroseconds,
      );
      _timeline.add(event);

      // Cap buffer size
      if (_timeline.length > _maxTimelineEntries) {
        _timeline.removeRange(0, _timeline.length - _maxTimelineEntries);
      }
    }

    // Update propagation time in perf tracker
    stopwatch.stop();
    tracker.totalPropagationMicros += stopwatch.elapsedMicroseconds;
  }

  /// Resolve a node's type string from the graph node.
  String _resolveNodeType(GraphNode? node) {
    if (node == null) return 'unknown';
    if (!node.isComputed) return 'writable';
    // Computed nodes with sources are computed; those without may be effects
    if (node.sources.isEmpty && node.observers.isEmpty) return 'effect';
    return 'computed';
  }

  /// Safely convert a value to string, handling exceptions.
  String _safeToString(dynamic value) {
    try {
      final str = value.toString();
      // Truncate very long strings
      if (str.length > 200) return '${str.substring(0, 200)}...';
      return str;
    } catch (_) {
      return '<error>';
    }
  }

  // ---------------------------------------------------------------------------
  // Service Extension Handlers
  // ---------------------------------------------------------------------------

  Future<developer.ServiceExtensionResponse> _handleGetGraph(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final graph = _store.graph;
      final nodes = <Map<String, dynamic>>[];
      final edges = <Map<String, dynamic>>[];

      for (final node in graph.nodes) {
        nodes.add({
          'id': node.ref.id,
          'name': node.ref.toString(),
          'type': _resolveNodeType(node),
          'state': node.state.name,
          'epoch': node.epoch,
          'level': node.level,
          'subscriberCount': node.subscriberCount,
        });

        for (final source in node.sources) {
          edges.add({
            'from': source.ref.id,
            'to': node.ref.id,
          });
        }
      }

      return developer.ServiceExtensionResponse.result(
        jsonEncode({'nodes': nodes, 'edges': edges}),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleGetReactonValue(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final refIdStr = parameters['refId'];
      if (refIdStr == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          'Missing required parameter: refId',
        );
      }

      final refId = int.parse(refIdStr);
      final ref = _store.reactonRefs.cast<ReactonRef?>().firstWhere(
            (r) => r!.id == refId,
            orElse: () => null,
          );

      if (ref == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          'No reacton with ref id $refId',
        );
      }

      final value = _store.getByRef(ref);
      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'refId': refId,
          'value': _safeToString(value),
          'type': value.runtimeType.toString(),
        }),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleSetReactonValue(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final refIdStr = parameters['refId'];
      final value = parameters['value'];

      if (refIdStr == null || value == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          'Missing required parameters: refId, value',
        );
      }

      final refId = int.parse(refIdStr);
      _store.setByRefId(refId, value);

      return developer.ServiceExtensionResponse.result(
        jsonEncode({'success': true}),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleGetReactonList(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final reactons = <Map<String, dynamic>>[];
      for (final ref in _store.reactonRefs) {
        final node = _store.graph.getNode(ref);
        reactons.add({
          'id': ref.id,
          'name': ref.toString(),
          'value': _safeToString(_store.getByRef(ref)),
          'type': _resolveNodeType(node),
          'subscribers': node?.subscriberCount ?? 0,
        });
      }

      return developer.ServiceExtensionResponse.result(
        jsonEncode({'reactons': reactons}),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleGetStats(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'reactonCount': _store.reactonCount,
          'nodeCount': _store.graph.nodeCount,
          'timelineEntries': _timeline.length,
          'trackedReactons': _perfTrackers.length,
        }),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleGetTimeline(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      // Support fetching only entries since a given index
      final sinceStr = parameters['since'];
      final since = sinceStr != null ? int.parse(sinceStr) : 0;
      final entries = since < _timeline.length
          ? _timeline.sublist(since)
          : <_TimelineEvent>[];

      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'entries': entries.map((e) => e.toJson()).toList(),
          'total': _timeline.length,
          'paused': _timelinePaused,
        }),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleClearTimeline(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final pause = parameters['pause'];
      if (pause != null) {
        _timelinePaused = pause == 'true';
      }
      _timeline.clear();
      return developer.ServiceExtensionResponse.result(
        jsonEncode({'success': true}),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleGetPerformance(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final perfData = <Map<String, dynamic>>[];

      for (final ref in _store.reactonRefs) {
        final node = _store.graph.getNode(ref);
        final tracker = _perfTrackers[ref.id];

        perfData.add({
          'refId': ref.id,
          'name': ref.toString(),
          'type': _resolveNodeType(node),
          'recomputeCount': tracker?.recomputeCount ?? 0,
          'avgPropagationMicros': tracker?.avgPropagationMicros ?? 0,
          'subscriberCount': node?.subscriberCount ?? 0,
        });
      }

      return developer.ServiceExtensionResponse.result(
        jsonEncode({'reactons': perfData}),
      );
    } catch (e) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        e.toString(),
      );
    }
  }
}
