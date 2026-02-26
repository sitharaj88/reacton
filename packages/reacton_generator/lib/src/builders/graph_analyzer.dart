import 'dart:convert';

import 'package:build/build.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

/// Builder factory for the graph analyzer.
Builder reactonGraphAnalyzerBuilder(BuilderOptions options) =>
    ReactonGraphAnalyzerBuilder();

/// Reacton declaration found during analysis.
class ReactonDeclaration {
  final String name;
  final String type;
  final String reactonKind; // 'reacton', 'computed', 'asyncReacton', 'selector', 'family'
  final String source;
  final List<String> dependencies;

  ReactonDeclaration({
    required this.name,
    required this.type,
    required this.reactonKind,
    required this.source,
    this.dependencies = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'reactonKind': reactonKind,
        'source': source,
        'dependencies': dependencies,
      };
}

/// Analyzes Dart source files to build a static dependency graph
/// of all reacton declarations.
///
/// Produces `.reacton_graph.json` files in the build cache that can be
/// consumed by DevTools and the CLI's `reacton graph` command.
class ReactonGraphAnalyzerBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.reacton_graph.json'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    // Only analyze files in lib/
    if (!inputId.path.startsWith('lib/')) return;

    final content = await buildStep.readAsString(inputId);

    // Parse the source
    final parseResult = parseString(content: content);
    final unit = parseResult.unit;

    final reactons = <ReactonDeclaration>[];

    // Visit top-level declarations
    for (final declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (final variable in declaration.variables.variables) {
          final initializer = variable.initializer;
          if (initializer is MethodInvocation) {
            final reactonKind = _getReactonKind(initializer.methodName.name);
            if (reactonKind != null) {
              final deps = _extractDependencies(initializer);
              reactons.add(ReactonDeclaration(
                name: variable.name.lexeme,
                type: variable.declaredElement?.type.toString() ?? 'dynamic',
                reactonKind: reactonKind,
                source: inputId.path,
                dependencies: deps,
              ));
            }
          }
        }
      }
    }

    if (reactons.isNotEmpty) {
      final outputId = inputId.changeExtension('.reacton_graph.json');
      await buildStep.writeAsString(
        outputId,
        const JsonEncoder.withIndent('  ').convert(
          reactons.map((a) => a.toJson()).toList(),
        ),
      );
    }
  }

  /// Check if a function name is a Reacton factory.
  String? _getReactonKind(String name) {
    return switch (name) {
      'reacton' => 'reacton',
      'computed' => 'computed',
      'asyncReacton' => 'asyncReacton',
      'selector' => 'selector',
      'family' => 'family',
      _ => null,
    };
  }

  /// Extract reacton names that appear inside `read(someReacton)` calls.
  List<String> _extractDependencies(MethodInvocation node) {
    final deps = <String>[];
    final visitor = _ReadCallExtractor(deps);

    // Look through the arguments for function expressions that call read()
    for (final arg in node.argumentList.arguments) {
      arg.visitChildren(visitor);
    }

    return deps;
  }
}

/// AST visitor that finds `read(reactonName)` calls inside expressions.
class _ReadCallExtractor extends RecursiveAstVisitor<void> {
  final List<String> dependencies;

  _ReadCallExtractor(this.dependencies);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read') {
      final args = node.argumentList.arguments;
      if (args.isNotEmpty && args.first is SimpleIdentifier) {
        dependencies.add((args.first as SimpleIdentifier).name);
      }
    }
    super.visitMethodInvocation(node);
  }

  // Also handle function invocations like `read(reacton)`
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final function = node.function;
    if (function is SimpleIdentifier && function.name == 'read') {
      final args = node.argumentList.arguments;
      if (args.isNotEmpty && args.first is SimpleIdentifier) {
        dependencies.add((args.first as SimpleIdentifier).name);
      }
    }
    super.visitFunctionExpressionInvocation(node);
  }
}
