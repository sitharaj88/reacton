import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:build/build.dart';
import 'package:reacton_generator/reacton_generator.dart';
import 'package:test/test.dart';

/// Helper that extracts [ReactonDeclaration]s from a Dart source string
/// by replicating the same AST-walking logic used inside
/// [ReactonGraphAnalyzerBuilder.build].
///
/// [path] is attached to each declaration's `source` field so tests can
/// assert on it.
List<ReactonDeclaration> analyzeSource(
  String source, {
  String path = 'lib/test.dart',
}) {
  final parseResult = parseString(content: source);
  final unit = parseResult.unit;
  final reactons = <ReactonDeclaration>[];

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
              source: path,
              dependencies: deps,
            ));
          }
        }
      }
    }
  }

  return reactons;
}

/// Mirror of [ReactonGraphAnalyzerBuilder._getReactonKind].
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

/// Mirror of [ReactonGraphAnalyzerBuilder._extractDependencies].
List<String> _extractDependencies(MethodInvocation node) {
  final deps = <String>[];
  final visitor = _ReadCallExtractor(deps);
  for (final arg in node.argumentList.arguments) {
    arg.visitChildren(visitor);
  }
  return deps;
}

/// Mirror of the private [_ReadCallExtractor] in graph_analyzer.dart.
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

void main() {
  // ---------------------------------------------------------------------------
  // ReactonDeclaration
  // ---------------------------------------------------------------------------
  group('ReactonDeclaration', () {
    test('constructor stores all required fields', () {
      final decl = ReactonDeclaration(
        name: 'counter',
        type: 'int',
        reactonKind: 'reacton',
        source: 'lib/state.dart',
      );

      expect(decl.name, 'counter');
      expect(decl.type, 'int');
      expect(decl.reactonKind, 'reacton');
      expect(decl.source, 'lib/state.dart');
    });

    test('dependencies defaults to empty list', () {
      final decl = ReactonDeclaration(
        name: 'counter',
        type: 'int',
        reactonKind: 'reacton',
        source: 'lib/state.dart',
      );

      expect(decl.dependencies, isEmpty);
    });

    test('constructor stores explicit dependencies', () {
      final decl = ReactonDeclaration(
        name: 'doubled',
        type: 'int',
        reactonKind: 'computed',
        source: 'lib/state.dart',
        dependencies: ['counter'],
      );

      expect(decl.dependencies, ['counter']);
    });

    test('toJson() returns correct structure with all fields', () {
      final decl = ReactonDeclaration(
        name: 'doubled',
        type: 'int',
        reactonKind: 'computed',
        source: 'lib/state.dart',
        dependencies: ['counter'],
      );

      final json = decl.toJson();

      expect(json, {
        'name': 'doubled',
        'type': 'int',
        'reactonKind': 'computed',
        'source': 'lib/state.dart',
        'dependencies': ['counter'],
      });
    });

    test('toJson() returns empty dependencies list when none provided', () {
      final decl = ReactonDeclaration(
        name: 'counter',
        type: 'int',
        reactonKind: 'reacton',
        source: 'lib/state.dart',
      );

      final json = decl.toJson();
      expect(json['dependencies'], isEmpty);
    });

    test('toJson() preserves multiple dependencies in order', () {
      final decl = ReactonDeclaration(
        name: 'total',
        type: 'int',
        reactonKind: 'computed',
        source: 'lib/state.dart',
        dependencies: ['price', 'quantity', 'taxRate'],
      );

      final json = decl.toJson();
      expect(json['dependencies'], ['price', 'quantity', 'taxRate']);
    });
  });

  // ---------------------------------------------------------------------------
  // reactonGraphAnalyzerBuilder factory function
  // ---------------------------------------------------------------------------
  group('reactonGraphAnalyzerBuilder', () {
    test('returns a ReactonGraphAnalyzerBuilder instance', () {
      final builder = reactonGraphAnalyzerBuilder(BuilderOptions.empty);
      expect(builder, isA<ReactonGraphAnalyzerBuilder>());
    });

    test('returns a Builder instance', () {
      final builder = reactonGraphAnalyzerBuilder(BuilderOptions.empty);
      expect(builder, isA<Builder>());
    });
  });

  // ---------------------------------------------------------------------------
  // buildExtensions
  // ---------------------------------------------------------------------------
  group('buildExtensions', () {
    test('maps .dart to .reacton_graph.json', () {
      final builder = ReactonGraphAnalyzerBuilder();
      expect(builder.buildExtensions, {
        '.dart': ['.reacton_graph.json'],
      });
    });

    test('has exactly one input extension', () {
      final builder = ReactonGraphAnalyzerBuilder();
      expect(builder.buildExtensions.keys, hasLength(1));
    });

    test('has exactly one output extension per input', () {
      final builder = ReactonGraphAnalyzerBuilder();
      expect(builder.buildExtensions['.dart'], hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Detecting reacton kinds
  // ---------------------------------------------------------------------------
  group('detecting reacton declarations', () {
    test('detects reacton() declaration', () {
      const source = '''
final counter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(1));
      expect(results.first.name, 'counter');
      expect(results.first.reactonKind, 'reacton');
    });

    test('detects computed() declaration', () {
      const source = '''
final doubled = computed((read) => read(counter) * 2);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(1));
      expect(results.first.name, 'doubled');
      expect(results.first.reactonKind, 'computed');
    });

    test('detects asyncReacton() declaration', () {
      const source = '''
final userData = asyncReacton(() async => await fetchUser());
''';
      final results = analyzeSource(source);
      expect(results, hasLength(1));
      expect(results.first.name, 'userData');
      expect(results.first.reactonKind, 'asyncReacton');
    });

    test('detects selector() declaration', () {
      const source = '''
final currentUser = selector((read) => read(users)[read(selectedId)]);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(1));
      expect(results.first.name, 'currentUser');
      expect(results.first.reactonKind, 'selector');
    });

    test('detects family() declaration', () {
      const source = '''
final userById = family((id) => reacton(null));
''';
      final results = analyzeSource(source);
      expect(results, hasLength(1));
      expect(results.first.name, 'userById');
      expect(results.first.reactonKind, 'family');
    });

    test('detects multiple reacton declarations in one file', () {
      const source = '''
final counter = reacton(0);
final step = reacton(1);
final doubled = computed((read) => read(counter) * 2);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(3));
      expect(results[0].name, 'counter');
      expect(results[0].reactonKind, 'reacton');
      expect(results[1].name, 'step');
      expect(results[1].reactonKind, 'reacton');
      expect(results[2].name, 'doubled');
      expect(results[2].reactonKind, 'computed');
    });

    test('detects all five reacton kinds in one file', () {
      const source = '''
final a = reacton(0);
final b = computed((read) => read(a));
final c = asyncReacton(() async => 42);
final d = selector((read) => read(a));
final e = family((id) => reacton(null));
''';
      final results = analyzeSource(source);
      expect(results, hasLength(5));
      expect(results.map((r) => r.reactonKind).toList(), [
        'reacton',
        'computed',
        'asyncReacton',
        'selector',
        'family',
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // Ignoring non-reacton declarations
  // ---------------------------------------------------------------------------
  group('ignoring non-reacton declarations', () {
    test('ignores non-reacton function calls', () {
      const source = '''
final x = someOtherFunction(42);
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores literal assignments', () {
      const source = '''
final x = 42;
final y = 'hello';
final z = true;
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores class declarations', () {
      const source = '''
class MyClass {
  final counter = reacton(0);
}
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores top-level function declarations', () {
      const source = '''
void myFunction() {
  final counter = reacton(0);
}
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores import and export directives', () {
      const source = '''
import 'package:reacton/reacton.dart';
export 'other.dart';
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores variables without initializers', () {
      const source = '''
late final dynamic counter;
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores variables initialized with constructors', () {
      const source = '''
final list = List.empty();
final map = Map<String, int>();
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores typedef declarations', () {
      const source = '''
typedef Callback = void Function(int);
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores enum declarations', () {
      const source = '''
enum Status { loading, success, error }
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('ignores mixin declarations', () {
      const source = '''
mixin MyMixin {
  final counter = reacton(0);
}
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Dependency extraction
  // ---------------------------------------------------------------------------
  group('dependency extraction', () {
    test('extracts single read() dependency in computed', () {
      const source = '''
final doubled = computed((read) => read(counter) * 2);
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, ['counter']);
    });

    test('extracts multiple read() dependencies', () {
      const source = '''
final total = computed((read) => read(price) * read(quantity));
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, ['price', 'quantity']);
    });

    test('extracts three or more read() dependencies', () {
      const source = '''
final summary = computed((read) => read(a) + read(b) + read(c));
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, ['a', 'b', 'c']);
    });

    test('handles reacton with no dependencies', () {
      const source = '''
final counter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, isEmpty);
    });

    test('extracts dependencies from selector', () {
      const source = '''
final selected = selector((read) => read(items)[read(index)]);
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, ['items', 'index']);
    });

    test('extracts dependencies from nested expressions', () {
      const source = '''
final derived = computed((read) {
  final x = read(a);
  final y = read(b);
  return x + y;
});
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, ['a', 'b']);
    });

    test('extracts dependencies from conditional expressions', () {
      const source = '''
final conditional = computed((read) => read(flag) ? read(trueVal) : read(falseVal));
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, ['flag', 'trueVal', 'falseVal']);
    });

    test('does not extract non-read method calls as dependencies', () {
      const source = '''
final derived = computed((read) => read(counter).toString());
''';
      final results = analyzeSource(source);
      // Only 'counter' should be extracted, not anything from toString()
      expect(results.first.dependencies, ['counter']);
    });

    test('handles computed with empty body', () {
      const source = '''
final empty = computed((read) => 0);
''';
      final results = analyzeSource(source);
      expect(results.first.dependencies, isEmpty);
    });

    test('extracts dependencies per declaration independently', () {
      const source = '''
final a = reacton(0);
final b = reacton(1);
final sumAB = computed((read) => read(a) + read(b));
final onlyA = computed((read) => read(a) * 10);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(4));

      // a - no deps
      expect(results[0].dependencies, isEmpty);
      // b - no deps
      expect(results[1].dependencies, isEmpty);
      // sumAB - depends on a and b
      expect(results[2].dependencies, ['a', 'b']);
      // onlyA - depends on only a
      expect(results[3].dependencies, ['a']);
    });
  });

  // ---------------------------------------------------------------------------
  // Reacton name capture
  // ---------------------------------------------------------------------------
  group('reacton name capture', () {
    test('captures simple variable name', () {
      const source = '''
final counter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results.first.name, 'counter');
    });

    test('captures camelCase variable name', () {
      const source = '''
final mySpecialCounter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results.first.name, 'mySpecialCounter');
    });

    test('captures name with underscores', () {
      const source = '''
final _privateCounter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results.first.name, '_privateCounter');
    });

    test('captures name with dollar sign', () {
      const source = r'''
final counter$ = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results.first.name, r'counter$');
    });
  });

  // ---------------------------------------------------------------------------
  // Source path tracking
  // ---------------------------------------------------------------------------
  group('source path tracking', () {
    test('uses default path when not specified', () {
      const source = '''
final counter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results.first.source, 'lib/test.dart');
    });

    test('uses custom path when specified', () {
      const source = '''
final counter = reacton(0);
''';
      final results =
          analyzeSource(source, path: 'lib/features/counter/state.dart');
      expect(results.first.source, 'lib/features/counter/state.dart');
    });

    test('all declarations in same file share the same source', () {
      const source = '''
final a = reacton(0);
final b = computed((read) => read(a));
''';
      final results =
          analyzeSource(source, path: 'lib/my_module.dart');
      expect(results[0].source, 'lib/my_module.dart');
      expect(results[1].source, 'lib/my_module.dart');
    });
  });

  // ---------------------------------------------------------------------------
  // Type reporting
  // ---------------------------------------------------------------------------
  group('type reporting', () {
    test('type defaults to dynamic when element is not resolved', () {
      // parseString() does not perform type resolution so
      // declaredElement will be null and the builder falls back to 'dynamic'.
      const source = '''
final counter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results.first.type, 'dynamic');
    });
  });

  // ---------------------------------------------------------------------------
  // Empty and edge-case files
  // ---------------------------------------------------------------------------
  group('edge cases', () {
    test('handles empty source file', () {
      const source = '';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('handles file with only comments', () {
      const source = '''
// This is a comment
/* Multi-line
   comment */
/// Doc comment
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('handles file with only imports', () {
      const source = '''
import 'dart:core';
import 'package:reacton/reacton.dart';
''';
      final results = analyzeSource(source);
      expect(results, isEmpty);
    });

    test('handles mixed content: reactons + regular code', () {
      const source = '''
import 'package:reacton/reacton.dart';

const maxRetries = 3;

class Config {
  final String apiUrl;
  Config(this.apiUrl);
}

final counter = reacton(0);

void doSomething() {
  print('hello');
}

final doubled = computed((read) => read(counter) * 2);

enum Status { idle, loading, done }

final status = reacton('idle');
''';
      final results = analyzeSource(source);
      expect(results, hasLength(3));
      expect(results[0].name, 'counter');
      expect(results[0].reactonKind, 'reacton');
      expect(results[1].name, 'doubled');
      expect(results[1].reactonKind, 'computed');
      expect(results[1].dependencies, ['counter']);
      expect(results[2].name, 'status');
      expect(results[2].reactonKind, 'reacton');
    });

    test('handles multiple variables in a single declaration statement', () {
      // Dart allows: final a = expr1, b = expr2;
      // The builder iterates declaration.variables.variables, so both should
      // be detected if they are reacton calls.
      const source = '''
final a = reacton(1), b = reacton(2);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(2));
      expect(results[0].name, 'a');
      expect(results[1].name, 'b');
    });

    test('ignores variable where one initializer is reacton and another is not in same statement', () {
      const source = '''
final a = reacton(1), b = someOther(2);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(1));
      expect(results.first.name, 'a');
      expect(results.first.reactonKind, 'reacton');
    });

    test('handles var keyword instead of final', () {
      const source = '''
var counter = reacton(0);
''';
      final results = analyzeSource(source);
      expect(results, hasLength(1));
      expect(results.first.name, 'counter');
    });
  });

  // ---------------------------------------------------------------------------
  // ReactonDeclaration toJson round-trip
  // ---------------------------------------------------------------------------
  group('toJson completeness', () {
    test('toJson contains exactly the expected keys', () {
      final decl = ReactonDeclaration(
        name: 'test',
        type: 'dynamic',
        reactonKind: 'reacton',
        source: 'lib/test.dart',
      );
      final json = decl.toJson();
      expect(json.keys.toSet(), {
        'name',
        'type',
        'reactonKind',
        'source',
        'dependencies',
      });
    });

    test('toJson values match constructor arguments', () {
      final decl = ReactonDeclaration(
        name: 'myReacton',
        type: 'String',
        reactonKind: 'asyncReacton',
        source: 'lib/features/auth.dart',
        dependencies: ['token', 'userId'],
      );
      final json = decl.toJson();
      expect(json['name'], 'myReacton');
      expect(json['type'], 'String');
      expect(json['reactonKind'], 'asyncReacton');
      expect(json['source'], 'lib/features/auth.dart');
      expect(json['dependencies'], ['token', 'userId']);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration-style: full analysis of a realistic module
  // ---------------------------------------------------------------------------
  group('realistic module analysis', () {
    test('analyzes a complete counter module', () {
      const source = '''
import 'package:reacton/reacton.dart';

final counterReacton = reacton(0);
final stepReacton = reacton(1);

final doubledCounter = computed((read) => read(counterReacton) * 2);
final steppedCounter = computed((read) => read(counterReacton) + read(stepReacton));

final asyncUser = asyncReacton(() async => await fetchUser());

final userSelector = selector((read) => read(asyncUser));

final userFamily = family((id) => asyncReacton(() async => await fetchUserById(id)));
''';
      final results =
          analyzeSource(source, path: 'lib/features/counter/state.dart');

      expect(results, hasLength(7));

      // counterReacton
      expect(results[0].name, 'counterReacton');
      expect(results[0].reactonKind, 'reacton');
      expect(results[0].dependencies, isEmpty);
      expect(results[0].source, 'lib/features/counter/state.dart');

      // stepReacton
      expect(results[1].name, 'stepReacton');
      expect(results[1].reactonKind, 'reacton');
      expect(results[1].dependencies, isEmpty);

      // doubledCounter
      expect(results[2].name, 'doubledCounter');
      expect(results[2].reactonKind, 'computed');
      expect(results[2].dependencies, ['counterReacton']);

      // steppedCounter
      expect(results[3].name, 'steppedCounter');
      expect(results[3].reactonKind, 'computed');
      expect(results[3].dependencies, ['counterReacton', 'stepReacton']);

      // asyncUser
      expect(results[4].name, 'asyncUser');
      expect(results[4].reactonKind, 'asyncReacton');
      expect(results[4].dependencies, isEmpty);

      // userSelector
      expect(results[5].name, 'userSelector');
      expect(results[5].reactonKind, 'selector');
      expect(results[5].dependencies, ['asyncUser']);

      // userFamily
      expect(results[6].name, 'userFamily');
      expect(results[6].reactonKind, 'family');
      expect(results[6].dependencies, isEmpty);
    });
  });
}
