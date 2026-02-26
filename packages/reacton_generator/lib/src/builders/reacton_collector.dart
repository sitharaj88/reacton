import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// Builder factory for the reacton collector.
Builder reactonCollectorBuilder(BuilderOptions options) =>
    ReactonCollectorBuilder();

/// Collects all `.reacton_graph.json` fragments and merges them
/// into a single `reacton_graph.json` at the package root.
///
/// This provides the complete dependency graph for DevTools and CLI.
class ReactonCollectorBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': ['reacton_graph.json'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final allReactons = <Map<String, dynamic>>[];

    // Find all graph fragments
    final glob = Glob('lib/**/*.reacton_graph.json');
    await for (final input in buildStep.findAssets(glob)) {
      final content = await buildStep.readAsString(input);
      final reactons = (jsonDecode(content) as List).cast<Map<String, dynamic>>();
      allReactons.addAll(reactons);
    }

    if (allReactons.isEmpty) return;

    // Build the complete graph
    final graph = _buildGraph(allReactons);

    final outputId = AssetId(buildStep.inputId.package, 'lib/reacton_graph.json');
    await buildStep.writeAsString(
      outputId,
      const JsonEncoder.withIndent('  ').convert(graph),
    );

    // Log summary
    log.info('Reacton graph: ${allReactons.length} reactons found');

    // Check for dead reactons
    final deadReactons = _findDeadReactons(allReactons);
    for (final dead in deadReactons) {
      log.warning('Dead reacton: "${dead['name']}" declared in ${dead['source']} '
          'is never used as a dependency');
    }
  }

  Map<String, dynamic> _buildGraph(List<Map<String, dynamic>> reactons) {
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
        'writableReactons': reactons.where((a) => a['reactonKind'] == 'reacton').length,
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

  /// Find reactons that are never referenced as a dependency.
  List<Map<String, dynamic>> _findDeadReactons(List<Map<String, dynamic>> reactons) {
    final allDeps = <String>{};
    for (final reacton in reactons) {
      final deps = (reacton['dependencies'] as List?)?.cast<String>() ?? [];
      allDeps.addAll(deps);
    }

    // Writable reactons (kind='reacton') with no dependents and not used elsewhere
    // are potential dead reactons. Computed/async reactons are always dependencies
    // of something, but writable reactons might be leaf nodes (UI-only).
    // For now, only flag reactons that aren't used as deps AND aren't writable
    return reactons
        .where((a) =>
            a['reactonKind'] != 'reacton' && !allDeps.contains(a['name']))
        .toList();
  }
}
