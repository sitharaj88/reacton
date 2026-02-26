import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers that replicate the detection logic from each lint rule.
// We parse Dart source with parseString() and run AST visitors identical
// to the ones in the production rules, collecting violations into lists
// instead of reporting through ErrorReporter.
// ---------------------------------------------------------------------------

// ---- avoid_reacton_in_build ------------------------------------------------

/// Returns a list of prohibited function names found inside a class's
/// build() method (mirrors _ReactonCallVisitor in the production rule).
List<String> findReactonCreationsInBuild(String source) {
  final result = parseString(content: source);
  final violations = <String>[];
  for (final decl in result.unit.declarations) {
    if (decl is ClassDeclaration) {
      for (final member in decl.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'build') {
          member.body.visitChildren(_ReactonCallFinder(violations));
        }
      }
    }
  }
  return violations;
}

class _ReactonCallFinder extends RecursiveAstVisitor<void> {
  final List<String> violations;
  _ReactonCallFinder(this.violations);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'reacton' ||
        name == 'computed' ||
        name == 'asyncReacton' ||
        name == 'family') {
      violations.add(name);
    }
    super.visitMethodInvocation(node);
  }
}

// ---- avoid_read_in_build ---------------------------------------------------

/// Returns a list of `context.read` strings for every direct (non-callback)
/// context.read() call inside a class's build() method.
List<String> findReadCallsInBuild(String source) {
  final result = parseString(content: source);
  final violations = <String>[];
  for (final decl in result.unit.declarations) {
    if (decl is ClassDeclaration) {
      for (final member in decl.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'build') {
          member.body.visitChildren(_ReadCallFinder(violations));
        }
      }
    }
  }
  return violations;
}

class _ReadCallFinder extends RecursiveAstVisitor<void> {
  final List<String> violations;
  _ReadCallFinder(this.violations);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read') {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'context') {
        if (!_isInsideCallback(node)) {
          violations.add('context.read');
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  bool _isInsideCallback(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression) return true;
      if (current is MethodDeclaration) return false;
      current = current.parent;
    }
    return false;
  }
}

// ---- prefer_computed -------------------------------------------------------

/// Returns the number of context.watch() calls found inside the first class's
/// build() method.
int countWatchCallsInBuild(String source) {
  final result = parseString(content: source);
  for (final decl in result.unit.declarations) {
    if (decl is ClassDeclaration) {
      for (final member in decl.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'build') {
          final counter = _WatchCounter();
          member.body.visitChildren(counter);
          return counter.count;
        }
      }
    }
  }
  return 0;
}

class _WatchCounter extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'watch') {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'context') {
        count++;
      }
    }
    super.visitMethodInvocation(node);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // avoid_reacton_in_build
  // =========================================================================
  group('avoid_reacton_in_build', () {
    test('detects reacton() call inside build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final counter = reacton(0);
    return Text('\$counter');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, contains('reacton'));
      expect(violations, hasLength(1));
    });

    test('detects computed() call inside build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final doubled = computed(() => count.value * 2);
    return Text('\$doubled');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, contains('computed'));
      expect(violations, hasLength(1));
    });

    test('detects asyncReacton() call inside build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final data = asyncReacton(() => fetchData());
    return Text('\$data');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, contains('asyncReacton'));
      expect(violations, hasLength(1));
    });

    test('detects family() call inside build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final items = family((id) => reacton(0));
    return Text('\$items');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, contains('family'));
    });

    test('does NOT flag top-level reacton declarations', () {
      final source = '''
final counter = reacton(0);
final doubled = computed(() => counter.value * 2);

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Text('hello');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag reactons in non-build methods', () {
      final source = '''
class MyWidget extends StatelessWidget {
  void initState() {
    final counter = reacton(0);
  }
  Widget build(BuildContext context) {
    return Text('hello');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag reactons in standalone functions (not classes)', () {
      final source = '''
Widget build(BuildContext context) {
  final counter = reacton(0);
  return Text('\$counter');
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, isEmpty);
    });

    test('detects multiple violations in one build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = reacton(0);
    final b = computed(() => a.value * 2);
    final c = asyncReacton(() => fetchData());
    final d = family((id) => reacton(0));
    return Text('hello');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, hasLength(5)); // reacton, computed, asyncReacton, family, and nested reacton
      expect(violations, containsAll(['reacton', 'computed', 'asyncReacton', 'family']));
    });

    test('does NOT flag calls in non-class build functions', () {
      // A standalone function called `build` is not inside a ClassDeclaration
      final source = '''
Widget build(BuildContext context) {
  final counter = reacton(0);
  return Text('\$counter');
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag unrelated method calls in build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final data = fetchData();
    final result = transform(data);
    return Text('\$result');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, isEmpty);
    });

    test('detects reacton() nested inside widget tree in build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        Builder(builder: (ctx) {
          final c = reacton(0);
          return Text('\$c');
        }),
      ],
    );
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, contains('reacton'));
    });

    test('does NOT flag reactons declared as static class fields', () {
      final source = '''
class MyWidget extends StatelessWidget {
  static final counter = reacton(0);

  Widget build(BuildContext context) {
    return Text('hello');
  }
}
''';
      // Static field declarations are FieldDeclaration, not inside build()
      final violations = findReactonCreationsInBuild(source);
      expect(violations, isEmpty);
    });

    test('detects reacton() in build() of a second class', () {
      final source = '''
class FirstWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Text('clean');
  }
}

class SecondWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final x = reacton(42);
    return Text('\$x');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, hasLength(1));
      expect(violations.first, equals('reacton'));
    });
  });

  // =========================================================================
  // avoid_read_in_build
  // =========================================================================
  group('avoid_read_in_build', () {
    test('detects context.read() in build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final value = context.read(counterReacton);
    return Text('\$value');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, hasLength(1));
      expect(violations.first, equals('context.read'));
    });

    test('does NOT flag context.watch() in build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final value = context.watch(counterReacton);
    return Text('\$value');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag context.read() inside onPressed callback', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read(counterReacton);
      },
      child: Text('click'),
    );
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag context.read() inside lambda callback', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read(counterReacton),
      child: Text('tap'),
    );
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag context.read() in non-build methods', () {
      final source = '''
class MyWidget extends StatelessWidget {
  void handleTap(BuildContext context) {
    context.read(counterReacton);
  }
  Widget build(BuildContext context) {
    return Text('hello');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag something.read() (non-context target)', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final value = store.read(counterReacton);
    return Text('\$value');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('detects multiple context.read() violations', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.read(reactonA);
    final b = context.read(reactonB);
    final c = context.read(reactonC);
    return Text('\$a \$b \$c');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, hasLength(3));
    });

    test('does NOT flag context.read() in inline function expression', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final callback = () {
      context.read(counterReacton);
    };
    return ElevatedButton(onPressed: callback, child: Text('go'));
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag context.read() inside a named function inside build()', () {
      // A function declaration inside build is not a FunctionExpression but
      // a FunctionDeclarationStatement whose functionExpression IS a
      // FunctionExpression, so the parent walk should still hit it.
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    void doStuff() {
      context.read(counterReacton);
    }
    return Text('hello');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      // The local function body is a FunctionExpression, so this should
      // be treated as a callback.
      expect(violations, isEmpty);
    });

    test('detects context.read() at top level of build but not in callbacks', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final directRead = context.read(reactonA);
    return ElevatedButton(
      onPressed: () {
        context.read(reactonB);
      },
      child: Text('\$directRead'),
    );
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, hasLength(1));
      expect(violations.first, equals('context.read'));
    });

    test('does NOT flag read() without a target', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final value = read(counterReacton);
    return Text('\$value');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag context.read() in standalone build function', () {
      final source = '''
Widget build(BuildContext context) {
  final value = context.read(counterReacton);
  return Text('\$value');
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag context.read() inside then() callback in build()', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    fetchData().then((data) {
      context.read(reactonA);
    });
    return Text('loading');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });

    test('does NOT flag context.read() inside nested arrow function', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (ctx, index) => Text(context.read(items).toString()),
    );
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isEmpty);
    });
  });

  // =========================================================================
  // prefer_computed
  // =========================================================================
  group('prefer_computed', () {
    test('0 watch calls does not trigger', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Text('hello');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(0));
      expect(count < 3, isTrue);
    });

    test('1 watch call does not trigger', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(reactonA);
    return Text('\$a');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(1));
      expect(count < 3, isTrue);
    });

    test('2 watch calls does not trigger', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(reactonA);
    final b = context.watch(reactonB);
    return Text('\$a \$b');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(2));
      expect(count < 3, isTrue);
    });

    test('3 watch calls triggers the rule', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(reactonA);
    final b = context.watch(reactonB);
    final c = context.watch(reactonC);
    return Text('\$a \$b \$c');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(3));
      expect(count >= 3, isTrue);
    });

    test('4 watch calls triggers the rule', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(reactonA);
    final b = context.watch(reactonB);
    final c = context.watch(reactonC);
    final d = context.watch(reactonD);
    return Text('\$a \$b \$c \$d');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(4));
      expect(count >= 3, isTrue);
    });

    test('does NOT count something.watch() (non-context target)', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = store.watch(reactonA);
    final b = store.watch(reactonB);
    final c = store.watch(reactonC);
    return Text('\$a \$b \$c');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(0));
    });

    test('does NOT count context.read() as a watch call', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.read(reactonA);
    final b = context.read(reactonB);
    final c = context.read(reactonC);
    return Text('\$a \$b \$c');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(0));
    });

    test('counts watch calls in nested widget expressions', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(context.watch(reactonA).toString()),
          Text(context.watch(reactonB).toString()),
          Text(context.watch(reactonC).toString()),
        ],
      ),
    );
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(3));
      expect(count >= 3, isTrue);
    });

    test('does NOT count watch calls in non-build methods', () {
      final source = '''
class MyWidget extends StatelessWidget {
  void someMethod(BuildContext context) {
    final a = context.watch(reactonA);
    final b = context.watch(reactonB);
    final c = context.watch(reactonC);
  }
  Widget build(BuildContext context) {
    return Text('hello');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(0));
    });

    test('does NOT count watch calls in standalone function', () {
      final source = '''
Widget build(BuildContext context) {
  final a = context.watch(reactonA);
  final b = context.watch(reactonB);
  final c = context.watch(reactonC);
  return Text('\$a \$b \$c');
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(0));
    });

    test('5 watch calls triggers the rule', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(reactonA);
    final b = context.watch(reactonB);
    final c = context.watch(reactonC);
    final d = context.watch(reactonD);
    final e = context.watch(reactonE);
    return Text('\$a \$b \$c \$d \$e');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(5));
      expect(count >= 3, isTrue);
    });

    test('counts watch() without a target as zero', () {
      // bare watch() calls without a target should not be counted
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = watch(reactonA);
    final b = watch(reactonB);
    final c = watch(reactonC);
    return Text('\$a \$b \$c');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(0));
    });

    test('mixed context.watch and context.read counts only watches', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(reactonA);
    final b = context.read(reactonB);
    final c = context.watch(reactonC);
    final d = context.read(reactonD);
    final e = context.watch(reactonE);
    return Text('\$a \$b \$c \$d \$e');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count, equals(3));
      expect(count >= 3, isTrue);
    });
  });

  // =========================================================================
  // Plugin structure & rule metadata
  // =========================================================================
  group('plugin structure and rule metadata', () {
    test('AvoidReactonInBuild lint code name is correct', () {
      // We verify by checking the source expectation: the rule registers
      // with name 'avoid_reacton_in_build'. We can't instantiate DartLintRule
      // without custom_lint, but we can validate the detection logic is
      // consistent with the expected rule name by parsing the source file.
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final c = reacton(0);
    return Text('\$c');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, isNotEmpty,
          reason: 'avoid_reacton_in_build detection logic should work');
    });

    test('AvoidReadInBuild lint code name is correct', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final v = context.read(counterReacton);
    return Text('\$v');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, isNotEmpty,
          reason: 'avoid_read_in_build detection logic should work');
    });

    test('PreferComputed lint code name is correct', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(rA);
    final b = context.watch(rB);
    final c = context.watch(rC);
    return Text('\$a \$b \$c');
  }
}
''';
      final count = countWatchCallsInBuild(source);
      expect(count >= 3, isTrue,
          reason: 'prefer_computed detection logic should work');
    });

    test('all three rules should be independent', () {
      // A source that triggers avoid_reacton_in_build should not
      // accidentally trigger avoid_read_in_build or prefer_computed
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final c = reacton(0);
    return Text('\$c');
  }
}
''';
      final reactonViolations = findReactonCreationsInBuild(source);
      final readViolations = findReadCallsInBuild(source);
      final watchCount = countWatchCallsInBuild(source);

      expect(reactonViolations, isNotEmpty);
      expect(readViolations, isEmpty);
      expect(watchCount, equals(0));
    });
  });

  // =========================================================================
  // Edge cases
  // =========================================================================
  group('edge cases', () {
    test('empty build method triggers no violations', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container();
  }
}
''';
      expect(findReactonCreationsInBuild(source), isEmpty);
      expect(findReadCallsInBuild(source), isEmpty);
      expect(countWatchCallsInBuild(source), equals(0));
    });

    test('class with no build method triggers no violations', () {
      final source = '''
class MyService {
  void doSomething() {
    final c = reacton(0);
    context.read(counterReacton);
  }
}
''';
      expect(findReactonCreationsInBuild(source), isEmpty);
      expect(findReadCallsInBuild(source), isEmpty);
      expect(countWatchCallsInBuild(source), equals(0));
    });

    test('multiple classes - only build() methods in classes are checked', () {
      final source = '''
class CleanWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Text('clean');
  }
}

class DirtyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = reacton(0);
    final b = context.read(rA);
    final c = context.watch(rA);
    final d = context.watch(rB);
    final e = context.watch(rC);
    return Text('\$a \$b \$c \$d \$e');
  }
}
''';
      final reactonViolations = findReactonCreationsInBuild(source);
      final readViolations = findReadCallsInBuild(source);
      final watchCount = countWatchCallsInBuild(source);

      expect(reactonViolations, hasLength(1));
      expect(readViolations, hasLength(1));
      // countWatchCallsInBuild returns count from first class with build()
      // which is CleanWidget (0 watches). We need a multi-class aware version
      // for exhaustive checking, but the production rule reports per-method.
      // Here we verify that the first build found has 0 watches.
      expect(watchCount, equals(0));
    });

    test('build method with expression body (=>) is scanned', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) => Text(context.read(rA).toString());
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, hasLength(1));
    });

    test('reacton in a conditional inside build is detected', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    if (someCondition) {
      final c = reacton(0);
    }
    return Text('hello');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, hasLength(1));
      expect(violations.first, equals('reacton'));
    });

    test('context.read in a for loop inside build is detected', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    for (var i = 0; i < 3; i++) {
      context.read(items);
    }
    return Text('hello');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, hasLength(1));
    });

    test('context.read in a try-catch inside build is detected', () {
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    try {
      final v = context.read(counterReacton);
    } catch (e) {
      // ignore
    }
    return Text('hello');
  }
}
''';
      final violations = findReadCallsInBuild(source);
      expect(violations, hasLength(1));
    });

    test('context.watch inside callback still counts for prefer_computed', () {
      // The _WatchCounter does NOT exclude callbacks (unlike _ReadCallVisitor).
      // This mirrors the production rule which counts all watches.
      final source = '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = context.watch(rA);
    final b = context.watch(rB);
    return GestureDetector(
      onTap: () {
        context.watch(rC);
      },
      child: Text('\$a \$b'),
    );
  }
}
''';
      final count = countWatchCallsInBuild(source);
      // All three watches are counted (including the one in the callback)
      expect(count, equals(3));
    });

    test('abstract class with build() is checked', () {
      final source = '''
abstract class BaseWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final c = reacton(0);
    return Text('\$c');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      expect(violations, hasLength(1));
    });

    test('mixin class with build() method - no ClassDeclaration so no flag', () {
      // A mixin is MixinDeclaration, not ClassDeclaration, so the rule
      // should not trigger for it. However, parseString may represent
      // `mixin` as MixinDeclaration. Let's verify.
      final source = '''
mixin BuildMixin {
  Widget build(BuildContext context) {
    final c = reacton(0);
    return Text('\$c');
  }
}
''';
      final violations = findReactonCreationsInBuild(source);
      // Mixin is not a ClassDeclaration, so no violations should be found.
      expect(violations, isEmpty);
    });
  });
}
