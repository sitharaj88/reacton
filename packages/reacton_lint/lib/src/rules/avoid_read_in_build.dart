import 'package:analyzer/error/listener.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule: Avoid using context.read() inside build methods.
///
/// In most cases, context.read() in build() should be context.watch()
/// to ensure the widget rebuilds when the value changes.
class AvoidReadInBuild extends DartLintRule {
  AvoidReadInBuild() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_read_in_build',
    problemMessage:
        'Using context.read() inside build() likely means context.watch() was '
        'intended. context.read() does not cause rebuilds on value change.',
    correctionMessage:
        'Replace with context.watch() or move to an event handler.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'build') return;

      final parent = node.parent;
      if (parent is! ClassDeclaration) return;

      node.body.visitChildren(_ReadCallVisitor(reporter));
    });
  }
}

class _ReadCallVisitor extends RecursiveAstVisitor<void> {
  final ErrorReporter reporter;

  _ReadCallVisitor(this.reporter);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for context.read() pattern
    if (node.methodName.name == 'read') {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'context') {
        // Check if inside a callback (onPressed, etc.) - that's OK
        if (!_isInsideCallback(node)) {
          reporter.reportErrorForNode(AvoidReadInBuild._code, node);
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
