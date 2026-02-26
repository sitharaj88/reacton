import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';

/// Command: reacton analyze
///
/// Analyzes Reacton reactons for issues including dead reactons,
/// circular dependencies, and complexity problems.
class AnalyzeCommand extends Command<void> {
  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Analyze Reacton reactons for issues (dead reactons, cycles, complexity)';

  AnalyzeCommand() {
    argParser
      ..addFlag('fix', help: 'Auto-fix simple issues (remove unused imports)')
      ..addOption(
        'format',
        help: 'Output format',
        allowed: ['text', 'json'],
        defaultsTo: 'text',
      );
  }

  @override
  Future<void> run() async {
    final shouldFix = argResults!['fix'] as bool;
    final format = argResults!['format'] as String;

    // Scan lib/ for reacton declarations
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      stderr.writeln('Error: No lib/ directory found.');
      return;
    }

    // Collect all Dart file contents
    final fileContents = <String, String>{};
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        fileContents[entity.path] = entity.readAsStringSync();
      }
    }

    if (fileContents.isEmpty) {
      stdout.writeln('No Dart files found in lib/');
      return;
    }

    // Extract all reacton declarations
    final reactons = <_ReactonInfo>[];
    for (final entry in fileContents.entries) {
      _extractReactons(entry.value, entry.key, reactons);
    }

    if (reactons.isEmpty) {
      stdout.writeln('No reactons found in lib/');
      return;
    }

    // Run all analysis checks
    final issues = <_Issue>[];

    _detectDeadReactons(reactons, fileContents, issues);
    _detectCycles(reactons, fileContents, issues);
    _analyzeComplexity(reactons, fileContents, issues);
    _checkNamingConventions(reactons, issues);

    // Apply auto-fix if requested
    if (shouldFix) {
      _applyFixes(issues, fileContents);
    }

    // Output results
    if (format == 'json') {
      _printJsonOutput(issues);
    } else {
      _printTextOutput(issues);
    }
  }

  void _extractReactons(String content, String filePath, List<_ReactonInfo> reactons) {
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

  /// Detect reactons that are declared but never referenced in any other file.
  void _detectDeadReactons(
    List<_ReactonInfo> reactons,
    Map<String, String> fileContents,
    List<_Issue> issues,
  ) {
    for (final reacton in reactons) {
      final refPattern = RegExp(
        r'(?:read|watch|context\.watch|context\.read|select)\s*\(\s*'
        '${RegExp.escape(reacton.name)}'
        r'\s*\)',
      );

      // Also check for bare references (e.g., passed as argument, used in
      // dependency lists) but exclude the declaration file's own declaration
      // line.
      var referencedElsewhere = false;

      for (final entry in fileContents.entries) {
        final filePath = entry.key;
        final content = entry.value;

        if (filePath == reacton.file) {
          // In the same file, check for references outside the declaration
          // itself. Split by lines to skip the declaration line.
          final lines = content.split('\n');
          for (final line in lines) {
            // Skip the declaration line
            if (RegExp(
              r'final\s+'
              '${RegExp.escape(reacton.name)}'
              r'\s*=\s*(reacton|computed|asyncReacton|selector|family)\b',
            ).hasMatch(line)) {
              continue;
            }
            if (refPattern.hasMatch(line) ||
                _hasBarReference(line, reacton.name)) {
              referencedElsewhere = true;
              break;
            }
          }
        } else {
          // In other files, any reference counts
          if (refPattern.hasMatch(content) ||
              _hasBareReferenceInFile(content, reacton.name)) {
            referencedElsewhere = true;
          }
        }

        if (referencedElsewhere) break;
      }

      if (!referencedElsewhere) {
        issues.add(_Issue(
          severity: _Severity.warning,
          message: 'Dead reacton: ${reacton.name} (${reacton.file})',
          detail: 'Declared but never referenced in any other file',
          reacton: reacton.name,
          file: reacton.file,
          type: 'dead_reacton',
        ));
      }
    }
  }

  /// Check if a line contains a bare reference to a reacton name (not a
  /// declaration).
  bool _hasBarReference(String line, String reactonName) {
    // Match the reacton name as a whole word, but not as part of a declaration
    final bareRef = RegExp(r'\b' '${RegExp.escape(reactonName)}' r'\b');
    return bareRef.hasMatch(line);
  }

  /// Check if file content has a bare reference to a reacton name (import or
  /// usage).
  bool _hasBareReferenceInFile(String content, String reactonName) {
    final bareRef = RegExp(r'\b' '${RegExp.escape(reactonName)}' r'\b');
    return bareRef.hasMatch(content);
  }

  /// Detect circular dependencies between computed reactons using DFS.
  void _detectCycles(
    List<_ReactonInfo> reactons,
    Map<String, String> fileContents,
    List<_Issue> issues,
  ) {
    // Build dependency graph: reacton name -> list of reacton names it reads
    final graph = <String, List<String>>{};
    final reactonNames = reactons.map((a) => a.name).toSet();

    for (final reacton in reactons) {
      if (reacton.type == 'computed' || reacton.type == 'selector') {
        final content = fileContents[reacton.file] ?? '';
        final deps = _extractDependencies(content, reacton.name, reactonNames);
        graph[reacton.name] = deps;
      }
    }

    // DFS cycle detection
    final visited = <String>{};
    final inStack = <String>{};
    final detectedCycles = <List<String>>[];

    void dfs(String node, List<String> path) {
      if (inStack.contains(node)) {
        // Found a cycle - extract the cycle from the path
        final cycleStart = path.indexOf(node);
        if (cycleStart != -1) {
          final cycle = [...path.sublist(cycleStart), node];
          detectedCycles.add(cycle);
        }
        return;
      }
      if (visited.contains(node)) return;

      visited.add(node);
      inStack.add(node);
      path.add(node);

      for (final dep in (graph[node] ?? <String>[])) {
        dfs(dep, path);
      }

      path.removeLast();
      inStack.remove(node);
    }

    for (final reactonName in graph.keys) {
      if (!visited.contains(reactonName)) {
        dfs(reactonName, []);
      }
    }

    for (final cycle in detectedCycles) {
      final cycleStr = cycle.join(' \u2192 ');
      issues.add(_Issue(
        severity: _Severity.error,
        message: 'Circular dependency detected:',
        detail: cycleStr,
        reacton: cycle.first,
        file: reactons.firstWhere((a) => a.name == cycle.first).file,
        type: 'cycle',
      ));
    }
  }

  /// Extract reacton dependencies from a computed reacton's body by finding read()
  /// calls.
  List<String> _extractDependencies(
    String fileContent,
    String reactonName,
    Set<String> knownReactons,
  ) {
    final deps = <String>[];
    final readPattern = RegExp(r'read\s*\(\s*(\w+)\s*\)');

    // Find the block of code associated with this reacton. We look for the
    // declaration and then capture subsequent read() calls until the next
    // top-level declaration or end of file.
    final declPattern = RegExp(
      r'final\s+'
      '${RegExp.escape(reactonName)}'
      r'\s*=\s*(computed|selector)\b',
    );
    final declMatch = declPattern.firstMatch(fileContent);
    if (declMatch == null) return deps;

    // Extract from the declaration onwards (simplified heuristic)
    final remaining = fileContent.substring(declMatch.start);

    // Track brace depth to find the end of the declaration
    var braceDepth = 0;
    var started = false;
    var endIndex = remaining.length;

    for (var i = 0; i < remaining.length; i++) {
      if (remaining[i] == '(') {
        braceDepth++;
        started = true;
      } else if (remaining[i] == ')') {
        braceDepth--;
        if (started && braceDepth == 0) {
          endIndex = i + 1;
          break;
        }
      }
    }

    final reactonBody = remaining.substring(0, endIndex);

    for (final match in readPattern.allMatches(reactonBody)) {
      final dep = match.group(1)!;
      if (knownReactons.contains(dep) && !deps.contains(dep)) {
        deps.add(dep);
      }
    }

    return deps;
  }

  /// Flag reactons with high complexity (many dependencies).
  void _analyzeComplexity(
    List<_ReactonInfo> reactons,
    Map<String, String> fileContents,
    List<_Issue> issues,
  ) {
    const threshold = 5;
    final reactonNames = reactons.map((a) => a.name).toSet();

    for (final reacton in reactons) {
      if (reacton.type == 'computed' || reacton.type == 'selector') {
        final content = fileContents[reacton.file] ?? '';
        final deps = _extractDependencies(content, reacton.name, reactonNames);

        if (deps.length > threshold) {
          issues.add(_Issue(
            severity: _Severity.info,
            message:
                'High complexity: ${reacton.name} (${reacton.file})',
            detail: '${deps.length} dependencies (threshold: $threshold)',
            reacton: reacton.name,
            file: reacton.file,
            type: 'complexity',
          ));
        }
      }
    }
  }

  /// Flag reactons not following the xxxReacton naming convention.
  void _checkNamingConventions(
    List<_ReactonInfo> reactons,
    List<_Issue> issues,
  ) {
    final reactonSuffix = RegExp(r'Reacton$');

    for (final reacton in reactons) {
      if (!reactonSuffix.hasMatch(reacton.name)) {
        issues.add(_Issue(
          severity: _Severity.info,
          message: 'Naming convention: ${reacton.name} (${reacton.file})',
          detail: 'Consider renaming to ${reacton.name}Reacton',
          reacton: reacton.name,
          file: reacton.file,
          type: 'naming',
        ));
      }
    }
  }

  /// Apply automatic fixes for simple issues.
  void _applyFixes(List<_Issue> issues, Map<String, String> fileContents) {
    // Currently supports removing unused imports for dead reactons
    final deadReactons = issues
        .where((i) => i.type == 'dead_reacton')
        .map((i) => i.reacton)
        .toSet();

    if (deadReactons.isEmpty) return;

    for (final entry in fileContents.entries) {
      final filePath = entry.key;
      var content = entry.value;
      var modified = false;

      for (final reactonName in deadReactons) {
        // Remove import lines that specifically import a dead reacton's file
        final importPattern = RegExp(
          r"import\s+'[^']*" '${RegExp.escape(reactonName)}' r"[^']*'\s*;[\r\n]*",
        );
        final newContent = content.replaceAll(importPattern, '');
        if (newContent != content) {
          content = newContent;
          modified = true;
        }
      }

      if (modified) {
        File(filePath).writeAsStringSync(content);
        stdout.writeln('  Fixed: Removed unused imports in $filePath');
      }
    }
  }

  void _printTextOutput(List<_Issue> issues) {
    stdout.writeln('Reacton Analyze');
    stdout.writeln('${'=' * 40}');
    stdout.writeln('');

    if (issues.isEmpty) {
      stdout.writeln('No issues found. All reactons look healthy!');
      stdout.writeln('');
      stdout.writeln('${'=' * 40}');
      return;
    }

    for (final issue in issues) {
      final tag = switch (issue.severity) {
        _Severity.error => '[ERROR]',
        _Severity.warning => '[WARN]',
        _Severity.info => '[INFO]',
      };

      stdout.writeln('$tag ${issue.message}');
      stdout.writeln('  \u2192 ${issue.detail}');
      stdout.writeln('');
    }

    final errorCount =
        issues.where((i) => i.severity == _Severity.error).length;
    final warnCount =
        issues.where((i) => i.severity == _Severity.warning).length;
    final infoCount =
        issues.where((i) => i.severity == _Severity.info).length;

    stdout.writeln('${'=' * 40}');

    final parts = <String>[];
    if (errorCount > 0) parts.add('$errorCount error${errorCount > 1 ? 's' : ''}');
    if (warnCount > 0) parts.add('$warnCount warning${warnCount > 1 ? 's' : ''}');
    if (infoCount > 0) parts.add('$infoCount info');

    stdout.writeln('Issues: ${parts.join(', ')}');
  }

  void _printJsonOutput(List<_Issue> issues) {
    final jsonIssues = issues.map((i) {
      return {
        'severity': i.severity.name,
        'message': i.message,
        'detail': i.detail,
        'reacton': i.reacton,
        'file': i.file,
        'type': i.type,
      };
    }).toList();

    final output = {
      'issues': jsonIssues,
      'summary': {
        'errors':
            issues.where((i) => i.severity == _Severity.error).length,
        'warnings':
            issues.where((i) => i.severity == _Severity.warning).length,
        'info':
            issues.where((i) => i.severity == _Severity.info).length,
        'total': issues.length,
      },
    };

    stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
  }
}

enum _Severity { error, warning, info }

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

class _Issue {
  final _Severity severity;
  final String message;
  final String detail;
  final String reacton;
  final String file;
  final String type;

  const _Issue({
    required this.severity,
    required this.message,
    required this.detail,
    required this.reacton,
    required this.file,
    required this.type,
  });
}
