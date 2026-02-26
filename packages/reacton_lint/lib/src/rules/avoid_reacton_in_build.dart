import 'package:analyzer/error/listener.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule: Don't create reactons inside build() methods.
///
/// Reactons should be declared at the top level or as static fields.
/// Creating them in build() creates a new reacton on every rebuild.
class AvoidReactonInBuild extends DartLintRule {
  AvoidReactonInBuild() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_reacton_in_build',
    problemMessage:
        'Do not create reactons inside build(). Reactons should be declared at the '
        'top level or as static fields to maintain identity across rebuilds.',
    correctionMessage:
        'Move this reacton declaration outside the build method.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'build') return;

      // Check if this is a Widget.build method
      final parent = node.parent;
      if (parent is! ClassDeclaration) return;

      // Visit the body looking for reacton(), computed(), asyncReacton() calls
      node.body.visitChildren(_ReactonCallVisitor(reporter));
    });
  }
}

class _ReactonCallVisitor extends RecursiveAstVisitor<void> {
  final DiagnosticReporter reporter;

  _ReactonCallVisitor(this.reporter);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'reacton' || name == 'computed' || name == 'asyncReacton' || name == 'family') {
      reporter.atNode(node, AvoidReactonInBuild._code);
    }
    super.visitMethodInvocation(node);
  }
}
