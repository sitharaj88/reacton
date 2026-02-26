import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  late ReactiveGraph graph;

  setUp(() {
    graph = ReactiveGraph();
  });

  tearDown(() {
    graph.dispose();
  });

  group('ReactiveGraph - Registration', () {
    test('registers writable reactons', () {
      final a = reacton(0, name: 'a');
      graph.registerWritable(a);
      expect(graph.contains(a.ref), isTrue);
      expect(graph.nodeCount, 1);
    });

    test('registers computed reactons with dependencies', () {
      final a = reacton(0, name: 'a');
      final b = computed((read) => read(a) * 2, name: 'b');

      graph.registerWritable(a);
      graph.registerComputed(b, [a.ref]);

      expect(graph.nodeCount, 2);
      final bNode = graph.getNode(b.ref)!;
      expect(bNode.sources.length, 1);
      expect(bNode.sources.first.ref, a.ref);
      expect(bNode.level, 1);
    });

    test('level is computed correctly for deep chains', () {
      final a = reacton(0, name: 'a');
      final b = computed((read) => read(a), name: 'b');
      final c = computed((read) => read(b), name: 'c');
      final d = computed((read) => read(c), name: 'd');

      graph.registerWritable(a);
      graph.registerComputed(b, [a.ref]);
      graph.registerComputed(c, [b.ref]);
      graph.registerComputed(d, [c.ref]);

      expect(graph.getNode(a.ref)!.level, 0);
      expect(graph.getNode(b.ref)!.level, 1);
      expect(graph.getNode(c.ref)!.level, 2);
      expect(graph.getNode(d.ref)!.level, 3);
    });
  });

  group('ReactiveGraph - Mark/Propagate', () {
    test('markDirty marks node as dirty', () {
      final a = reacton(0, name: 'a');
      graph.registerWritable(a);
      graph.markDirty(a.ref);

      // After propagation, node should be clean again
      final node = graph.getNode(a.ref)!;
      expect(node.state, NodeState.clean);
    });

    test('markDirty propagates Check to observers', () {
      final a = reacton(0, name: 'a');
      final b = computed((read) => read(a), name: 'b');
      final c = computed((read) => read(b), name: 'c');

      graph.registerWritable(a);
      graph.registerComputed(b, [a.ref]);
      graph.registerComputed(c, [b.ref]);

      // The onNodeChanged callback tracks recomputations
      final recomputed = <ReactonRef>[];
      graph.onNodeChanged = (ref) => recomputed.add(ref);

      graph.markDirty(a.ref);

      // Both b and c should have been signaled for recomputation
      expect(recomputed, contains(b.ref));
      expect(recomputed, contains(c.ref));
    });
  });

  group('ReactiveGraph - Unregister', () {
    test('unregister removes node and edges', () {
      final a = reacton(0, name: 'a');
      final b = computed((read) => read(a), name: 'b');

      graph.registerWritable(a);
      graph.registerComputed(b, [a.ref]);

      graph.unregister(b.ref);
      expect(graph.contains(b.ref), isFalse);
      expect(graph.getNode(a.ref)!.observers, isEmpty);
    });
  });

  group('ReactiveGraph - Cycle Detection', () {
    test('detects potential cycles', () {
      final a = reacton(0, name: 'a');
      final b = computed((read) => read(a), name: 'b');

      graph.registerWritable(a);
      graph.registerComputed(b, [a.ref]);

      // b -> a would create a cycle
      expect(graph.wouldCreateCycle(b.ref, a.ref), isTrue);

      // a -> b already exists, not a new cycle
      expect(graph.wouldCreateCycle(a.ref, b.ref), isFalse);
    });
  });

  group('ReactiveGraph - Scheduler', () {
    test('batch collects multiple flushes', () {
      final flushCount = <int>[];
      var count = 0;

      graph.scheduler.onFlush = () {
        count++;
        flushCount.add(count);
      };

      graph.scheduler.batch(() {
        graph.scheduler.scheduleFlush();
        graph.scheduler.scheduleFlush();
        graph.scheduler.scheduleFlush();
      });

      // Only one flush should have occurred
      expect(flushCount.length, 1);
    });
  });
}
