import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reacton/reacton.dart';
import 'package:reacton_devtools/reacton_devtools.dart';

void main() {
  // ===========================================================================
  // 1. Data Class fromJson Tests
  // ===========================================================================

  group('GraphNodeData.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 1,
        'name': 'counter',
        'type': 'writable',
        'state': 'clean',
        'epoch': 5,
        'level': 0,
        'subscriberCount': 3,
      };
      final node = GraphNodeData.fromJson(json);

      expect(node.id, 1);
      expect(node.name, 'counter');
      expect(node.type, 'writable');
      expect(node.state, 'clean');
      expect(node.epoch, 5);
      expect(node.level, 0);
      expect(node.subscriberCount, 3);
    });

    test('handles zero values', () {
      final json = {
        'id': 0,
        'name': '',
        'type': 'computed',
        'state': 'dirty',
        'epoch': 0,
        'level': 0,
        'subscriberCount': 0,
      };
      final node = GraphNodeData.fromJson(json);

      expect(node.id, 0);
      expect(node.name, '');
      expect(node.type, 'computed');
      expect(node.state, 'dirty');
      expect(node.epoch, 0);
      expect(node.level, 0);
      expect(node.subscriberCount, 0);
    });

    test('handles large numeric values', () {
      final json = {
        'id': 999999,
        'name': 'large_reacton',
        'type': 'writable',
        'state': 'check',
        'epoch': 1000000,
        'level': 50,
        'subscriberCount': 10000,
      };
      final node = GraphNodeData.fromJson(json);

      expect(node.id, 999999);
      expect(node.epoch, 1000000);
      expect(node.level, 50);
      expect(node.subscriberCount, 10000);
    });
  });

  group('GraphEdgeData.fromJson', () {
    test('parses from and to fields', () {
      final json = {'from': 1, 'to': 2};
      final edge = GraphEdgeData.fromJson(json);

      expect(edge.from, 1);
      expect(edge.to, 2);
    });

    test('handles same source and target id', () {
      final json = {'from': 5, 'to': 5};
      final edge = GraphEdgeData.fromJson(json);

      expect(edge.from, 5);
      expect(edge.to, 5);
    });
  });

  group('ReactonValueData.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'refId': 42,
        'value': '100',
        'type': 'int',
      };
      final data = ReactonValueData.fromJson(json);

      expect(data.refId, 42);
      expect(data.value, '100');
      expect(data.type, 'int');
    });

    test('handles complex value strings', () {
      final json = {
        'refId': 10,
        'value': '[1, 2, 3]',
        'type': 'List<int>',
      };
      final data = ReactonValueData.fromJson(json);

      expect(data.refId, 10);
      expect(data.value, '[1, 2, 3]');
      expect(data.type, 'List<int>');
    });

    test('handles empty string value', () {
      final json = {
        'refId': 0,
        'value': '',
        'type': 'String',
      };
      final data = ReactonValueData.fromJson(json);

      expect(data.value, '');
      expect(data.type, 'String');
    });
  });

  group('ReactonListEntry.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 7,
        'name': 'username',
        'value': 'Alice',
        'type': 'writable',
        'subscribers': 2,
      };
      final entry = ReactonListEntry.fromJson(json);

      expect(entry.id, 7);
      expect(entry.name, 'username');
      expect(entry.value, 'Alice');
      expect(entry.type, 'writable');
      expect(entry.subscribers, 2);
    });

    test('handles computed type with zero subscribers', () {
      final json = {
        'id': 20,
        'name': 'derived',
        'value': '42',
        'type': 'computed',
        'subscribers': 0,
      };
      final entry = ReactonListEntry.fromJson(json);

      expect(entry.type, 'computed');
      expect(entry.subscribers, 0);
    });
  });

  group('StoreStats.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'reactonCount': 10,
        'nodeCount': 15,
        'timelineEntries': 100,
        'trackedReactons': 8,
      };
      final stats = StoreStats.fromJson(json);

      expect(stats.reactonCount, 10);
      expect(stats.nodeCount, 15);
      expect(stats.timelineEntries, 100);
      expect(stats.trackedReactons, 8);
    });

    test('defaults timelineEntries to 0 when absent', () {
      final json = {
        'reactonCount': 5,
        'nodeCount': 5,
      };
      final stats = StoreStats.fromJson(json);

      expect(stats.timelineEntries, 0);
    });

    test('defaults trackedReactons to 0 when absent', () {
      final json = {
        'reactonCount': 3,
        'nodeCount': 3,
      };
      final stats = StoreStats.fromJson(json);

      expect(stats.trackedReactons, 0);
    });

    test('defaults both optional fields to 0 when absent', () {
      final json = {
        'reactonCount': 1,
        'nodeCount': 1,
      };
      final stats = StoreStats.fromJson(json);

      expect(stats.timelineEntries, 0);
      expect(stats.trackedReactons, 0);
    });
  });

  group('TimelineEntryData.fromJson', () {
    test('parses all fields including timestamp', () {
      final now = DateTime(2026, 2, 25, 12, 0, 0);
      final json = {
        'refId': 3,
        'name': 'counter',
        'type': 'writable',
        'oldValue': '0',
        'newValue': '1',
        'timestamp': now.toIso8601String(),
        'propagationMicros': 150,
      };
      final entry = TimelineEntryData.fromJson(json);

      expect(entry.refId, 3);
      expect(entry.name, 'counter');
      expect(entry.type, 'writable');
      expect(entry.oldValue, '0');
      expect(entry.newValue, '1');
      expect(entry.timestamp, now);
      expect(entry.propagationMicros, 150);
    });

    test('handles ISO 8601 timestamp with timezone', () {
      final json = {
        'refId': 1,
        'name': 'x',
        'type': 'writable',
        'oldValue': 'a',
        'newValue': 'b',
        'timestamp': '2026-01-15T10:30:00.000Z',
        'propagationMicros': 0,
      };
      final entry = TimelineEntryData.fromJson(json);

      expect(entry.timestamp.year, 2026);
      expect(entry.timestamp.month, 1);
      expect(entry.timestamp.day, 15);
    });

    test('handles zero propagation micros', () {
      final json = {
        'refId': 1,
        'name': 'fast',
        'type': 'writable',
        'oldValue': '0',
        'newValue': '1',
        'timestamp': DateTime.now().toIso8601String(),
        'propagationMicros': 0,
      };
      final entry = TimelineEntryData.fromJson(json);

      expect(entry.propagationMicros, 0);
    });
  });

  group('TimelineData.fromJson', () {
    test('parses entries, total, and paused', () {
      final json = {
        'entries': [
          {
            'refId': 1,
            'name': 'counter',
            'type': 'writable',
            'oldValue': '0',
            'newValue': '1',
            'timestamp': DateTime.now().toIso8601String(),
            'propagationMicros': 50,
          },
        ],
        'total': 1,
        'paused': false,
      };
      final data = TimelineData.fromJson(json);

      expect(data.entries, hasLength(1));
      expect(data.entries.first.name, 'counter');
      expect(data.total, 1);
      expect(data.paused, false);
    });

    test('parses empty entries list', () {
      final json = {
        'entries': <Map<String, dynamic>>[],
        'total': 0,
        'paused': true,
      };
      final data = TimelineData.fromJson(json);

      expect(data.entries, isEmpty);
      expect(data.total, 0);
      expect(data.paused, true);
    });

    test('parses multiple entries', () {
      final ts = DateTime.now().toIso8601String();
      final json = {
        'entries': [
          {
            'refId': 1,
            'name': 'a',
            'type': 'writable',
            'oldValue': '0',
            'newValue': '1',
            'timestamp': ts,
            'propagationMicros': 10,
          },
          {
            'refId': 2,
            'name': 'b',
            'type': 'computed',
            'oldValue': '1',
            'newValue': '2',
            'timestamp': ts,
            'propagationMicros': 20,
          },
          {
            'refId': 3,
            'name': 'c',
            'type': 'writable',
            'oldValue': 'x',
            'newValue': 'y',
            'timestamp': ts,
            'propagationMicros': 30,
          },
        ],
        'total': 10,
        'paused': false,
      };
      final data = TimelineData.fromJson(json);

      expect(data.entries, hasLength(3));
      expect(data.entries[0].refId, 1);
      expect(data.entries[1].refId, 2);
      expect(data.entries[2].refId, 3);
      expect(data.total, 10);
    });
  });

  group('PerformanceEntry.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'refId': 5,
        'name': 'expensiveComputed',
        'type': 'computed',
        'recomputeCount': 42,
        'avgPropagationMicros': 350,
        'subscriberCount': 3,
      };
      final entry = PerformanceEntry.fromJson(json);

      expect(entry.refId, 5);
      expect(entry.name, 'expensiveComputed');
      expect(entry.type, 'computed');
      expect(entry.recomputeCount, 42);
      expect(entry.avgPropagationMicros, 350);
      expect(entry.subscriberCount, 3);
    });

    test('handles zero metrics for untracked reacton', () {
      final json = {
        'refId': 1,
        'name': 'idle',
        'type': 'writable',
        'recomputeCount': 0,
        'avgPropagationMicros': 0,
        'subscriberCount': 0,
      };
      final entry = PerformanceEntry.fromJson(json);

      expect(entry.recomputeCount, 0);
      expect(entry.avgPropagationMicros, 0);
      expect(entry.subscriberCount, 0);
    });
  });

  // ===========================================================================
  // 2. ReactonDevToolsService Tests
  // ===========================================================================

  group('ReactonDevToolsService', () {
    test('getGraph() calls correct extension and parses graph data', () async {
      String? capturedMethod;
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedMethod = method;
        capturedParams = params;
        return jsonEncode({
          'nodes': [
            {
              'id': 1,
              'name': 'counter',
              'type': 'writable',
              'state': 'clean',
              'epoch': 3,
              'level': 0,
              'subscriberCount': 1,
            },
            {
              'id': 2,
              'name': 'double',
              'type': 'computed',
              'state': 'clean',
              'epoch': 3,
              'level': 1,
              'subscriberCount': 0,
            },
          ],
          'edges': [
            {'from': 1, 'to': 2},
          ],
        });
      });

      final result = await service.getGraph();

      expect(capturedMethod, 'ext.reacton.getGraph');
      expect(capturedParams, isEmpty);
      expect(result.nodes, hasLength(2));
      expect(result.nodes[0].name, 'counter');
      expect(result.nodes[1].name, 'double');
      expect(result.edges, hasLength(1));
      expect(result.edges[0].from, 1);
      expect(result.edges[0].to, 2);
    });

    test('getGraph() returns empty graph when no nodes', () async {
      final service = ReactonDevToolsService((method, params) async {
        return jsonEncode({'nodes': [], 'edges': []});
      });

      final result = await service.getGraph();

      expect(result.nodes, isEmpty);
      expect(result.edges, isEmpty);
    });

    test('getReactonValue() passes correct refId parameter', () async {
      String? capturedMethod;
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedMethod = method;
        capturedParams = params;
        return jsonEncode({
          'refId': 42,
          'value': '100',
          'type': 'int',
        });
      });

      final result = await service.getReactonValue(42);

      expect(capturedMethod, 'ext.reacton.getReactonValue');
      expect(capturedParams, {'refId': '42'});
      expect(result.refId, 42);
      expect(result.value, '100');
      expect(result.type, 'int');
    });

    test('getReactonValue() converts refId to string in params', () async {
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedParams = params;
        return jsonEncode({'refId': 0, 'value': 'x', 'type': 'String'});
      });

      await service.getReactonValue(0);

      expect(capturedParams!['refId'], '0');
    });

    test('getReactonList() parses list of reactons correctly', () async {
      String? capturedMethod;

      final service = ReactonDevToolsService((method, params) async {
        capturedMethod = method;
        return jsonEncode({
          'reactons': [
            {
              'id': 1,
              'name': 'counter',
              'value': '0',
              'type': 'writable',
              'subscribers': 2,
            },
            {
              'id': 2,
              'name': 'doubleCount',
              'value': '0',
              'type': 'computed',
              'subscribers': 1,
            },
          ],
        });
      });

      final result = await service.getReactonList();

      expect(capturedMethod, 'ext.reacton.getReactonList');
      expect(result, hasLength(2));
      expect(result[0].name, 'counter');
      expect(result[0].type, 'writable');
      expect(result[0].subscribers, 2);
      expect(result[1].name, 'doubleCount');
      expect(result[1].type, 'computed');
    });

    test('getReactonList() returns empty list when no reactons', () async {
      final service = ReactonDevToolsService((method, params) async {
        return jsonEncode({'reactons': []});
      });

      final result = await service.getReactonList();

      expect(result, isEmpty);
    });

    test('getStats() calls correct extension and parses stats', () async {
      String? capturedMethod;

      final service = ReactonDevToolsService((method, params) async {
        capturedMethod = method;
        return jsonEncode({
          'reactonCount': 10,
          'nodeCount': 15,
          'timelineEntries': 200,
          'trackedReactons': 8,
        });
      });

      final result = await service.getStats();

      expect(capturedMethod, 'ext.reacton.getStats');
      expect(result.reactonCount, 10);
      expect(result.nodeCount, 15);
      expect(result.timelineEntries, 200);
      expect(result.trackedReactons, 8);
    });

    test('getTimeline() passes since parameter as string', () async {
      String? capturedMethod;
      Map<String, String>? capturedParams;

      final ts = DateTime.now().toIso8601String();
      final service = ReactonDevToolsService((method, params) async {
        capturedMethod = method;
        capturedParams = params;
        return jsonEncode({
          'entries': [
            {
              'refId': 1,
              'name': 'counter',
              'type': 'writable',
              'oldValue': '0',
              'newValue': '1',
              'timestamp': ts,
              'propagationMicros': 50,
            },
          ],
          'total': 5,
          'paused': false,
        });
      });

      final result = await service.getTimeline(since: 3);

      expect(capturedMethod, 'ext.reacton.getTimeline');
      expect(capturedParams, {'since': '3'});
      expect(result.entries, hasLength(1));
      expect(result.total, 5);
      expect(result.paused, false);
    });

    test('getTimeline() defaults since to 0', () async {
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedParams = params;
        return jsonEncode({
          'entries': [],
          'total': 0,
          'paused': false,
        });
      });

      await service.getTimeline();

      expect(capturedParams, {'since': '0'});
    });

    test('getTimeline() returns paused state correctly', () async {
      final service = ReactonDevToolsService((method, params) async {
        return jsonEncode({
          'entries': [],
          'total': 50,
          'paused': true,
        });
      });

      final result = await service.getTimeline();

      expect(result.paused, true);
      expect(result.total, 50);
    });

    test('clearTimeline() calls correct extension with no params', () async {
      String? capturedMethod;
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedMethod = method;
        capturedParams = params;
        return jsonEncode({'success': true});
      });

      await service.clearTimeline();

      expect(capturedMethod, 'ext.reacton.clearTimeline');
      expect(capturedParams, isEmpty);
    });

    test('clearTimeline() passes pause=true as string param', () async {
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedParams = params;
        return jsonEncode({'success': true});
      });

      await service.clearTimeline(pause: true);

      expect(capturedParams, {'pause': 'true'});
    });

    test('clearTimeline() passes pause=false as string param', () async {
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedParams = params;
        return jsonEncode({'success': true});
      });

      await service.clearTimeline(pause: false);

      expect(capturedParams, {'pause': 'false'});
    });

    test('clearTimeline() omits pause param when null', () async {
      Map<String, String>? capturedParams;

      final service = ReactonDevToolsService((method, params) async {
        capturedParams = params;
        return jsonEncode({'success': true});
      });

      await service.clearTimeline(pause: null);

      expect(capturedParams!.containsKey('pause'), false);
    });

    test('getPerformance() calls correct extension and parses data', () async {
      String? capturedMethod;

      final service = ReactonDevToolsService((method, params) async {
        capturedMethod = method;
        return jsonEncode({
          'reactons': [
            {
              'refId': 1,
              'name': 'counter',
              'type': 'writable',
              'recomputeCount': 10,
              'avgPropagationMicros': 200,
              'subscriberCount': 2,
            },
            {
              'refId': 2,
              'name': 'derived',
              'type': 'computed',
              'recomputeCount': 5,
              'avgPropagationMicros': 400,
              'subscriberCount': 1,
            },
          ],
        });
      });

      final result = await service.getPerformance();

      expect(capturedMethod, 'ext.reacton.getPerformance');
      expect(result, hasLength(2));
      expect(result[0].name, 'counter');
      expect(result[0].recomputeCount, 10);
      expect(result[0].avgPropagationMicros, 200);
      expect(result[1].name, 'derived');
      expect(result[1].recomputeCount, 5);
    });

    test('getPerformance() returns empty list when no metrics', () async {
      final service = ReactonDevToolsService((method, params) async {
        return jsonEncode({'reactons': []});
      });

      final result = await service.getPerformance();

      expect(result, isEmpty);
    });
  });

  // ===========================================================================
  // 3. Store DevTools Listener Integration Tests
  // ===========================================================================

  group('Store DevTools listener integration', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    tearDown(() {
      store.dispose();
    });

    test('setDevToolsListener installs a listener on the store', () {
      var callCount = 0;
      store.setDevToolsListener((ref, oldVal, newVal) {
        callCount++;
      });

      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 1);

      expect(callCount, 1);
    });

    test('listener receives correct old and new values', () {
      dynamic capturedOld;
      dynamic capturedNew;

      store.setDevToolsListener((ref, oldVal, newVal) {
        capturedOld = oldVal;
        capturedNew = newVal;
      });

      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 5);

      expect(capturedOld, 0);
      expect(capturedNew, 5);
    });

    test('listener receives correct ref', () {
      ReactonRef? capturedRef;

      store.setDevToolsListener((ref, oldVal, newVal) {
        capturedRef = ref;
      });

      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 1);

      expect(capturedRef, isNotNull);
      expect(capturedRef!.id, counter.ref.id);
    });

    test('listener is called on each value change', () {
      final changes = <Map<String, dynamic>>[];

      store.setDevToolsListener((ref, oldVal, newVal) {
        changes.add({'old': oldVal, 'new': newVal});
      });

      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 1);
      store.set(counter, 2);
      store.set(counter, 3);

      expect(changes, hasLength(3));
      expect(changes[0], {'old': 0, 'new': 1});
      expect(changes[1], {'old': 1, 'new': 2});
      expect(changes[2], {'old': 2, 'new': 3});
    });

    test('listener is not called when value does not change', () {
      var callCount = 0;

      store.setDevToolsListener((ref, oldVal, newVal) {
        callCount++;
      });

      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 0); // same as initial value

      expect(callCount, 0);
    });

    test('removing listener stops notifications', () {
      var callCount = 0;

      store.setDevToolsListener((ref, oldVal, newVal) {
        callCount++;
      });

      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 1);
      expect(callCount, 1);

      // Remove the listener
      store.setDevToolsListener(null);
      store.set(counter, 2);
      expect(callCount, 1); // should not have increased
    });

    test('listener tracks changes across multiple reactons', () {
      final capturedNames = <String>[];

      store.setDevToolsListener((ref, oldVal, newVal) {
        capturedNames.add(ref.toString());
      });

      final a = reacton<int>(0, name: 'alpha');
      final b = reacton<String>('', name: 'beta');

      store.set(a, 10);
      store.set(b, 'hello');

      expect(capturedNames, contains('alpha'));
      expect(capturedNames, contains('beta'));
    });

    test('listener is called for computed reacton changes', () {
      final changes = <Map<String, dynamic>>[];

      store.setDevToolsListener((ref, oldVal, newVal) {
        changes.add({
          'name': ref.toString(),
          'old': oldVal,
          'new': newVal,
        });
      });

      final counter = reacton<int>(0, name: 'counter');
      final doubled = computed<int>(
        (read) => read(counter) * 2,
        name: 'doubled',
      );

      // Initialize computed by reading it
      store.get(doubled);

      store.set(counter, 5);

      // Should have captured both the writable change and the computed recomputation
      final writableChange =
          changes.where((c) => c['name'] == 'counter').toList();
      final computedChange =
          changes.where((c) => c['name'] == 'doubled').toList();

      expect(writableChange, hasLength(1));
      expect(writableChange.first['old'], 0);
      expect(writableChange.first['new'], 5);

      expect(computedChange, hasLength(1));
      expect(computedChange.first['old'], 0);
      expect(computedChange.first['new'], 10);
    });

    test('replacing listener replaces previous one', () {
      var firstListenerCalls = 0;
      var secondListenerCalls = 0;

      store.setDevToolsListener((ref, oldVal, newVal) {
        firstListenerCalls++;
      });

      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 1);
      expect(firstListenerCalls, 1);

      // Replace with a new listener
      store.setDevToolsListener((ref, oldVal, newVal) {
        secondListenerCalls++;
      });

      store.set(counter, 2);
      expect(firstListenerCalls, 1); // should not increase
      expect(secondListenerCalls, 1);
    });
  });

  // ===========================================================================
  // 4. GraphData Tests
  // ===========================================================================

  group('GraphData', () {
    test('stores nodes and edges', () {
      final nodes = [
        const GraphNodeData(
          id: 1,
          name: 'a',
          type: 'writable',
          state: 'clean',
          epoch: 0,
          level: 0,
          subscriberCount: 0,
        ),
      ];
      final edges = [
        const GraphEdgeData(from: 1, to: 2),
      ];
      final data = GraphData(nodes: nodes, edges: edges);

      expect(data.nodes, hasLength(1));
      expect(data.edges, hasLength(1));
    });

    test('can be empty', () {
      final data = GraphData(nodes: [], edges: []);

      expect(data.nodes, isEmpty);
      expect(data.edges, isEmpty);
    });
  });

  // ===========================================================================
  // 5. Service Method Sequencing Tests
  // ===========================================================================

  group('Service method call tracking', () {
    test('multiple service calls are independent', () async {
      final calls = <String>[];

      final service = ReactonDevToolsService((method, params) async {
        calls.add(method);
        if (method == 'ext.reacton.getStats') {
          return jsonEncode({
            'reactonCount': 1,
            'nodeCount': 1,
            'timelineEntries': 0,
            'trackedReactons': 0,
          });
        }
        if (method == 'ext.reacton.getReactonList') {
          return jsonEncode({'reactons': []});
        }
        return jsonEncode({});
      });

      await service.getStats();
      await service.getReactonList();

      expect(calls, ['ext.reacton.getStats', 'ext.reacton.getReactonList']);
    });

    test('service forwards parameters correctly for getReactonValue', () async {
      final capturedCalls = <Map<String, dynamic>>[];

      final service = ReactonDevToolsService((method, params) async {
        capturedCalls.add({'method': method, 'params': Map.of(params)});
        return jsonEncode({'refId': 99, 'value': 'test', 'type': 'String'});
      });

      await service.getReactonValue(99);

      expect(capturedCalls, hasLength(1));
      expect(capturedCalls[0]['method'], 'ext.reacton.getReactonValue');
      expect(capturedCalls[0]['params'], {'refId': '99'});
    });
  });

  // ===========================================================================
  // 6. Store-level DevTools Capability Tests
  // ===========================================================================

  group('Store reacton enumeration for DevTools', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    tearDown(() {
      store.dispose();
    });

    test('reactonRefs returns all initialized reactons', () {
      final a = reacton<int>(0, name: 'a');
      final b = reacton<String>('hello', name: 'b');

      store.get(a);
      store.get(b);

      final refs = store.reactonRefs.toList();
      expect(refs, hasLength(2));
    });

    test('reactonCount reflects number of initialized reactons', () {
      expect(store.reactonCount, 0);

      final a = reacton<int>(0, name: 'a');
      store.get(a);
      expect(store.reactonCount, 1);

      final b = reacton<int>(10, name: 'b');
      store.get(b);
      expect(store.reactonCount, 2);
    });

    test('getByRef returns current value', () {
      final counter = reacton<int>(42, name: 'counter');
      store.get(counter); // initialize

      final value = store.getByRef(counter.ref);
      expect(value, 42);
    });

    test('getByRef returns updated value after set', () {
      final counter = reacton<int>(0, name: 'counter');
      store.set(counter, 99);

      final value = store.getByRef(counter.ref);
      expect(value, 99);
    });

    test('setByRefId updates value via ref id', () {
      final counter = reacton<int>(0, name: 'counter');
      store.get(counter); // initialize

      store.setByRefId(counter.ref.id, 77);
      final value = store.get(counter);
      expect(value, 77);
    });
  });
}
