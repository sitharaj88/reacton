import 'package:build/build.dart';
import 'package:reacton_generator/src/builders/reacton_collector.dart';
import 'package:test/test.dart';

/// Replicates the private `_buildGraph` logic from [ReactonCollectorBuilder]
/// so we can test it in isolation without needing a real [BuildStep].
Map<String, dynamic> buildGraph(List<Map<String, dynamic>> reactons) {
  final nodes = <Map<String, dynamic>>[];
  final edges = <Map<String, dynamic>>[];

  for (final reacton in reactons) {
    nodes.add({
      'name': reacton['name'],
      'type': reacton['type'],
      'kind': reacton['reactonKind'],
      'source': reacton['source'],
    });

    final deps = (reacton['dependencies'] as List?)?.cast<String>() ?? [];
    for (final dep in deps) {
      edges.add({
        'from': dep,
        'to': reacton['name'],
      });
    }
  }

  return {
    'version': 1,
    'generatedAt': DateTime.now().toIso8601String(),
    'nodes': nodes,
    'edges': edges,
    'stats': {
      'totalReactons': nodes.length,
      'writableReactons':
          reactons.where((a) => a['reactonKind'] == 'reacton').length,
      'computedReactons':
          reactons.where((a) => a['reactonKind'] == 'computed').length,
      'asyncReactons':
          reactons.where((a) => a['reactonKind'] == 'asyncReacton').length,
      'selectors':
          reactons.where((a) => a['reactonKind'] == 'selector').length,
      'families':
          reactons.where((a) => a['reactonKind'] == 'family').length,
    },
  };
}

/// Replicates the private `_findDeadReactons` logic from [ReactonCollectorBuilder]
/// so we can test it in isolation without needing a real [BuildStep].
List<Map<String, dynamic>> findDeadReactons(
    List<Map<String, dynamic>> reactons) {
  final allDeps = <String>{};
  for (final reacton in reactons) {
    final deps = (reacton['dependencies'] as List?)?.cast<String>() ?? [];
    allDeps.addAll(deps);
  }

  return reactons
      .where(
          (a) => a['reactonKind'] != 'reacton' && !allDeps.contains(a['name']))
      .toList();
}

// ---------------------------------------------------------------------------
// Test data factories
// ---------------------------------------------------------------------------

Map<String, dynamic> _writable(
  String name, {
  String type = 'int',
  String source = 'lib/src/state.dart',
  List<String>? dependencies,
}) =>
    {
      'name': name,
      'type': type,
      'reactonKind': 'reacton',
      'source': source,
      if (dependencies != null) 'dependencies': dependencies,
    };

Map<String, dynamic> _computed(
  String name, {
  String type = 'int',
  String source = 'lib/src/state.dart',
  List<String>? dependencies,
}) =>
    {
      'name': name,
      'type': type,
      'reactonKind': 'computed',
      'source': source,
      if (dependencies != null) 'dependencies': dependencies,
    };

Map<String, dynamic> _asyncReacton(
  String name, {
  String type = 'Future<int>',
  String source = 'lib/src/state.dart',
  List<String>? dependencies,
}) =>
    {
      'name': name,
      'type': type,
      'reactonKind': 'asyncReacton',
      'source': source,
      if (dependencies != null) 'dependencies': dependencies,
    };

Map<String, dynamic> _selector(
  String name, {
  String type = 'String',
  String source = 'lib/src/state.dart',
  List<String>? dependencies,
}) =>
    {
      'name': name,
      'type': type,
      'reactonKind': 'selector',
      'source': source,
      if (dependencies != null) 'dependencies': dependencies,
    };

Map<String, dynamic> _family(
  String name, {
  String type = 'int',
  String source = 'lib/src/state.dart',
  List<String>? dependencies,
}) =>
    {
      'name': name,
      'type': type,
      'reactonKind': 'family',
      'source': source,
      if (dependencies != null) 'dependencies': dependencies,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ===================================================================
  // Builder structure tests
  // ===================================================================

  group('ReactonCollectorBuilder structure', () {
    test('reactonCollectorBuilder() returns a Builder', () {
      final builder = reactonCollectorBuilder(BuilderOptions.empty);
      expect(builder, isA<Builder>());
    });

    test('reactonCollectorBuilder() returns a ReactonCollectorBuilder', () {
      final builder = reactonCollectorBuilder(BuilderOptions.empty);
      expect(builder, isA<ReactonCollectorBuilder>());
    });

    test('ReactonCollectorBuilder implements Builder', () {
      final builder = ReactonCollectorBuilder();
      expect(builder, isA<Builder>());
    });

    test('buildExtensions uses synthetic \$lib\$ input', () {
      final builder = ReactonCollectorBuilder();
      expect(builder.buildExtensions, contains(r'$lib$'));
    });

    test('buildExtensions outputs reacton_graph.json', () {
      final builder = ReactonCollectorBuilder();
      final outputs = builder.buildExtensions[r'$lib$'];
      expect(outputs, isNotNull);
      expect(outputs, contains('reacton_graph.json'));
    });

    test('buildExtensions has exactly one entry', () {
      final builder = ReactonCollectorBuilder();
      expect(builder.buildExtensions.length, 1);
    });

    test('buildExtensions output list has exactly one element', () {
      final builder = ReactonCollectorBuilder();
      final outputs = builder.buildExtensions[r'$lib$']!;
      expect(outputs.length, 1);
    });
  });

  // ===================================================================
  // Graph building – empty and minimal inputs
  // ===================================================================

  group('buildGraph – basic', () {
    test('empty input produces empty nodes and edges', () {
      final graph = buildGraph([]);
      expect(graph['nodes'], isEmpty);
      expect(graph['edges'], isEmpty);
    });

    test('empty input stats are all zero', () {
      final graph = buildGraph([]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['totalReactons'], 0);
      expect(stats['writableReactons'], 0);
      expect(stats['computedReactons'], 0);
      expect(stats['asyncReactons'], 0);
      expect(stats['selectors'], 0);
      expect(stats['families'], 0);
    });

    test('graph version is 1', () {
      final graph = buildGraph([]);
      expect(graph['version'], 1);
    });

    test('generatedAt is a valid ISO 8601 string', () {
      final graph = buildGraph([]);
      final raw = graph['generatedAt'] as String;
      expect(() => DateTime.parse(raw), returnsNormally);
    });

    test('graph contains all required top-level keys', () {
      final graph = buildGraph([]);
      expect(graph, containsPair('version', isNotNull));
      expect(graph, containsPair('generatedAt', isNotNull));
      expect(graph, containsPair('nodes', isNotNull));
      expect(graph, containsPair('edges', isNotNull));
      expect(graph, containsPair('stats', isNotNull));
    });
  });

  // ===================================================================
  // Graph building – nodes
  // ===================================================================

  group('buildGraph – nodes', () {
    test('single writable reacton produces 1 node', () {
      final graph = buildGraph([_writable('counter')]);
      final nodes = graph['nodes'] as List;
      expect(nodes, hasLength(1));
    });

    test('node carries correct name, type, kind, and source', () {
      final graph = buildGraph([
        _writable('counter', type: 'int', source: 'lib/counter.dart'),
      ]);
      final node = (graph['nodes'] as List).first as Map<String, dynamic>;
      expect(node['name'], 'counter');
      expect(node['type'], 'int');
      expect(node['kind'], 'reacton');
      expect(node['source'], 'lib/counter.dart');
    });

    test('multiple reactons produce correct node count', () {
      final graph = buildGraph([
        _writable('a'),
        _computed('b', dependencies: ['a']),
        _selector('c', dependencies: ['b']),
      ]);
      final nodes = graph['nodes'] as List;
      expect(nodes, hasLength(3));
    });

    test('node kind maps from reactonKind field', () {
      final graph = buildGraph([_asyncReacton('fetchData')]);
      final node = (graph['nodes'] as List).first as Map<String, dynamic>;
      expect(node['kind'], 'asyncReacton');
    });
  });

  // ===================================================================
  // Graph building – edges
  // ===================================================================

  group('buildGraph – edges', () {
    test('single writable reacton with no deps produces 0 edges', () {
      final graph = buildGraph([_writable('counter')]);
      final edges = graph['edges'] as List;
      expect(edges, isEmpty);
    });

    test('computed with one dependency produces 1 edge', () {
      final graph = buildGraph([
        _writable('counter'),
        _computed('doubled', dependencies: ['counter']),
      ]);
      final edges = graph['edges'] as List;
      expect(edges, hasLength(1));
    });

    test('edge maps from dependency to dependent', () {
      final graph = buildGraph([
        _writable('counter'),
        _computed('doubled', dependencies: ['counter']),
      ]);
      final edge = (graph['edges'] as List).first as Map<String, dynamic>;
      expect(edge['from'], 'counter');
      expect(edge['to'], 'doubled');
    });

    test('multiple dependencies produce multiple edges', () {
      final graph = buildGraph([
        _writable('a'),
        _writable('b'),
        _computed('sum', dependencies: ['a', 'b']),
      ]);
      final edges = graph['edges'] as List;
      expect(edges, hasLength(2));
    });

    test('edges from multiple dependencies point to the same target', () {
      final graph = buildGraph([
        _writable('a'),
        _writable('b'),
        _computed('sum', dependencies: ['a', 'b']),
      ]);
      final edges = (graph['edges'] as List).cast<Map<String, dynamic>>();
      expect(edges.every((e) => e['to'] == 'sum'), isTrue);
      final sources = edges.map((e) => e['from']).toSet();
      expect(sources, containsAll(['a', 'b']));
    });

    test('chain of dependencies produces correct edges', () {
      final graph = buildGraph([
        _writable('a'),
        _computed('b', dependencies: ['a']),
        _selector('c', dependencies: ['b']),
      ]);
      final edges = (graph['edges'] as List).cast<Map<String, dynamic>>();
      expect(edges, hasLength(2));
      expect(edges, contains(predicate<Map<String, dynamic>>(
          (e) => e['from'] == 'a' && e['to'] == 'b')));
      expect(edges, contains(predicate<Map<String, dynamic>>(
          (e) => e['from'] == 'b' && e['to'] == 'c')));
    });

    test('reacton with null dependencies produces no edges', () {
      final reacton = {
        'name': 'orphan',
        'type': 'int',
        'reactonKind': 'computed',
        'source': 'lib/src/state.dart',
        // 'dependencies' key intentionally omitted
      };
      final graph = buildGraph([reacton]);
      final edges = graph['edges'] as List;
      expect(edges, isEmpty);
    });

    test('reacton with empty dependencies list produces no edges', () {
      final graph = buildGraph([
        _computed('empty', dependencies: []),
      ]);
      final edges = graph['edges'] as List;
      expect(edges, isEmpty);
    });
  });

  // ===================================================================
  // Graph building – stats
  // ===================================================================

  group('buildGraph – stats', () {
    test('totalReactons matches node count', () {
      final graph = buildGraph([_writable('a'), _computed('b')]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['totalReactons'], 2);
    });

    test('stats correctly count writable reactons', () {
      final graph = buildGraph([
        _writable('a'),
        _writable('b'),
        _computed('c'),
      ]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['writableReactons'], 2);
    });

    test('stats correctly count computed reactons', () {
      final graph = buildGraph([
        _computed('a'),
        _computed('b'),
        _writable('c'),
      ]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['computedReactons'], 2);
    });

    test('stats correctly count async reactons', () {
      final graph = buildGraph([
        _asyncReacton('fetch1'),
        _asyncReacton('fetch2'),
        _asyncReacton('fetch3'),
      ]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['asyncReactons'], 3);
    });

    test('stats correctly count selectors', () {
      final graph = buildGraph([_selector('sel')]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['selectors'], 1);
    });

    test('stats correctly count families', () {
      final graph = buildGraph([_family('todoFamily'), _family('userFamily')]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['families'], 2);
    });

    test('stats handles all 5 kinds simultaneously', () {
      final graph = buildGraph([
        _writable('w'),
        _computed('c', dependencies: ['w']),
        _asyncReacton('a'),
        _selector('s', dependencies: ['w']),
        _family('f'),
      ]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(stats['totalReactons'], 5);
      expect(stats['writableReactons'], 1);
      expect(stats['computedReactons'], 1);
      expect(stats['asyncReactons'], 1);
      expect(stats['selectors'], 1);
      expect(stats['families'], 1);
    });

    test('stats contains all expected keys', () {
      final graph = buildGraph([]);
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(
        stats.keys,
        containsAll([
          'totalReactons',
          'writableReactons',
          'computedReactons',
          'asyncReactons',
          'selectors',
          'families',
        ]),
      );
    });
  });

  // ===================================================================
  // Dead reacton detection
  // ===================================================================

  group('findDeadReactons', () {
    test('empty input returns empty list', () {
      expect(findDeadReactons([]), isEmpty);
    });

    test('writable reactons are never flagged as dead', () {
      final dead = findDeadReactons([_writable('counter')]);
      expect(dead, isEmpty);
    });

    test('all-writable input returns empty dead list', () {
      final dead = findDeadReactons([
        _writable('a'),
        _writable('b'),
        _writable('c'),
      ]);
      expect(dead, isEmpty);
    });

    test('computed reacton used as dependency is NOT dead', () {
      final dead = findDeadReactons([
        _writable('a'),
        _computed('b', dependencies: ['a']),
        _selector('c', dependencies: ['b']),
      ]);
      final deadNames = dead.map((d) => d['name']);
      expect(deadNames, isNot(contains('b')));
    });

    test('computed reacton NOT used as dependency IS dead', () {
      final dead = findDeadReactons([
        _writable('a'),
        _computed('orphanComputed', dependencies: ['a']),
      ]);
      final deadNames = dead.map((d) => d['name']);
      expect(deadNames, contains('orphanComputed'));
    });

    test('async reacton not used as dependency IS dead', () {
      final dead = findDeadReactons([
        _asyncReacton('unusedFetch'),
      ]);
      final deadNames = dead.map((d) => d['name']);
      expect(deadNames, contains('unusedFetch'));
    });

    test('selector not used as dependency IS dead', () {
      final dead = findDeadReactons([
        _selector('orphanSelector'),
      ]);
      final deadNames = dead.map((d) => d['name']);
      expect(deadNames, contains('orphanSelector'));
    });

    test('family not used as dependency IS dead', () {
      final dead = findDeadReactons([
        _family('unusedFamily'),
      ]);
      final deadNames = dead.map((d) => d['name']);
      expect(deadNames, contains('unusedFamily'));
    });

    test('mixed graph correctly identifies only dead non-writable reactons', () {
      final dead = findDeadReactons([
        _writable('counter'),
        _computed('doubled', dependencies: ['counter']),
        _computed('tripled', dependencies: ['counter']),
        _selector('label', dependencies: ['doubled']),
      ]);
      // 'doubled' is used by 'label', so NOT dead
      // 'tripled' is NOT used by anything, so IS dead
      // 'label' is NOT used by anything, so IS dead
      // 'counter' is writable, so never dead
      final deadNames = dead.map((d) => d['name']).toSet();
      expect(deadNames, equals({'tripled', 'label'}));
    });

    test('reacton used transitively is not dead', () {
      // a -> b -> c : b is used by c, so b should not be dead
      final dead = findDeadReactons([
        _writable('a'),
        _computed('b', dependencies: ['a']),
        _computed('c', dependencies: ['b']),
      ]);
      final deadNames = dead.map((d) => d['name']).toSet();
      // 'b' is referenced as a dependency by 'c', so NOT dead
      // 'c' has no dependents, so IS dead
      expect(deadNames, equals({'c'}));
    });

    test('dead reacton retains its source information', () {
      final dead = findDeadReactons([
        _computed('orphan', source: 'lib/src/orphan.dart'),
      ]);
      expect(dead, hasLength(1));
      expect(dead.first['source'], 'lib/src/orphan.dart');
      expect(dead.first['name'], 'orphan');
    });

    test('writable reacton with no dependents is still not dead', () {
      // Writable reactons might be read directly by UI, so they
      // should never be flagged even when nothing depends on them.
      final dead = findDeadReactons([
        _writable('uiOnly'),
        _computed('derived', dependencies: ['uiOnly']),
      ]);
      final deadNames = dead.map((d) => d['name']).toSet();
      // 'uiOnly' is writable -> never dead
      // 'derived' is computed and no one depends on it -> dead
      expect(deadNames, equals({'derived'}));
    });

    test('reacton with null dependencies field does not crash', () {
      final reacton = {
        'name': 'noDeps',
        'type': 'int',
        'reactonKind': 'computed',
        'source': 'lib/src/state.dart',
        // 'dependencies' intentionally omitted -> null
      };
      // Should not throw, and should be flagged as dead
      final dead = findDeadReactons([reacton]);
      expect(dead, hasLength(1));
      expect(dead.first['name'], 'noDeps');
    });
  });

  // ===================================================================
  // Integration-style: graph + dead reacton detection consistency
  // ===================================================================

  group('buildGraph and findDeadReactons consistency', () {
    test('graph edges align with non-dead status', () {
      final reactons = [
        _writable('price'),
        _writable('quantity'),
        _computed('total', dependencies: ['price', 'quantity']),
        _asyncReacton('fetchTax', dependencies: ['total']),
        _selector('label', dependencies: ['total']),
        _computed('orphan', dependencies: ['price']),
      ];

      final graph = buildGraph(reactons);
      final dead = findDeadReactons(reactons);
      final deadNames = dead.map((d) => d['name']).toSet();

      // Every non-dead, non-writable reacton should appear as
      // a dependency in at least one edge.
      final edges = (graph['edges'] as List).cast<Map<String, dynamic>>();
      final edgeSources = edges.map((e) => e['from'] as String).toSet();

      final nodes = (graph['nodes'] as List).cast<Map<String, dynamic>>();
      for (final node in nodes) {
        final name = node['name'] as String;
        final kind = node['kind'] as String;
        if (kind != 'reacton' && !deadNames.contains(name)) {
          expect(edgeSources, contains(name),
              reason: '"$name" is not dead and not writable, '
                  'so it should appear as a dependency in some edge');
        }
      }
    });

    test('graph node count matches stats totalReactons', () {
      final reactons = [
        _writable('a'),
        _computed('b'),
        _asyncReacton('c'),
        _selector('d'),
        _family('e'),
      ];
      final graph = buildGraph(reactons);
      final nodes = graph['nodes'] as List;
      final stats = graph['stats'] as Map<String, dynamic>;
      expect(nodes.length, stats['totalReactons']);
    });
  });
}
