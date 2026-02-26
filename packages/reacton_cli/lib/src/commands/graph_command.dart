import 'dart:io';
import 'package:args/command_runner.dart';

/// Command: reacton graph
///
/// Prints the reacton dependency graph.
class GraphCommand extends Command<void> {
  @override
  String get name => 'graph';

  @override
  String get description => 'Print the reacton dependency graph';

  GraphCommand() {
    argParser.addFlag('dot', help: 'Output in DOT format for Graphviz');
  }

  @override
  Future<void> run() async {
    final isDot = argResults!['dot'] as bool;

    // Scan lib/ for reacton declarations
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      stderr.writeln('Error: No lib/ directory found.');
      return;
    }

    final reactons = <_ReactonInfo>[];
    await _scanDirectory(libDir, reactons);

    if (reactons.isEmpty) {
      stdout.writeln('No reactons found in lib/');
      return;
    }

    if (isDot) {
      _printDotGraph(reactons);
    } else {
      _printTextGraph(reactons);
    }
  }

  Future<void> _scanDirectory(Directory dir, List<_ReactonInfo> reactons) async {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = entity.readAsStringSync();
        _extractReactons(content, entity.path, reactons);
      }
    }
  }

  void _extractReactons(String content, String filePath, List<_ReactonInfo> reactons) {
    // Simple regex-based extraction for reacton declarations
    final reactonPattern = RegExp(
      r'final\s+(\w+)\s*=\s*(reacton|computed|asyncReacton|selector|family)\b',
    );

    for (final match in reactonPattern.allMatches(content)) {
      reactons.add(_ReactonInfo(
        name: match.group(1)!,
        type: match.group(2)!,
        file: filePath,
      ));
    }
  }

  void _printTextGraph(List<_ReactonInfo> reactons) {
    stdout.writeln('Reacton Dependency Graph');
    stdout.writeln('${'=' * 40}');
    stdout.writeln('');

    for (final reacton in reactons) {
      final icon = switch (reacton.type) {
        'reacton' => '[W]',
        'computed' => '[C]',
        'asyncReacton' => '[A]',
        'selector' => '[S]',
        'family' => '[F]',
        _ => '[?]',
      };
      stdout.writeln('  $icon ${reacton.name} (${reacton.file})');
    }

    stdout.writeln('');
    stdout.writeln('Legend: [W]=Writable [C]=Computed [A]=Async [S]=Selector [F]=Family');
    stdout.writeln('Total reactons: ${reactons.length}');
  }

  void _printDotGraph(List<_ReactonInfo> reactons) {
    stdout.writeln('digraph reacton {');
    stdout.writeln('  rankdir=LR;');
    stdout.writeln('  node [shape=box, style=rounded];');
    stdout.writeln('');

    for (final reacton in reactons) {
      final color = switch (reacton.type) {
        'reacton' => '#4A90D9',
        'computed' => '#5CB85C',
        'asyncReacton' => '#F0AD4E',
        'selector' => '#D9534F',
        'family' => '#9B59B6',
        _ => '#777777',
      };
      stdout.writeln('  "${reacton.name}" [fillcolor="$color", style="filled,rounded", fontcolor=white];');
    }

    stdout.writeln('}');
  }
}

class _ReactonInfo {
  final String name;
  final String type;
  final String file;

  const _ReactonInfo({
    required this.name,
    required this.type,
    required this.file,
  });
}
