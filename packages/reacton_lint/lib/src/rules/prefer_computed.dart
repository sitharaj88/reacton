import 'package:analyzer/error/listener.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule: Prefer computed() over manual derivation in build methods.
///
/// When a build method reads multiple reactons and combines them,
/// it's often better to use a computed() reacton for the derived value.
class PreferComputed extends DartLintRule {
  PreferComputed() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_computed',
    problemMessage:
        'Consider extracting this derived value into a computed() reacton. '
        'This improves reusability, testability, and caching.',
    correctionMessage:
        'Create a computed() reacton that derives this value.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'build') return;

      final parent = node.parent;
      if (parent is! ClassDeclaration) return;

      // Count watch() calls in the build body (not in callbacks)
      final counter = _WatchCounter();
      node.body.visitChildren(counter);

      // If there are 3+ watches in a single build, suggest computed
      if (counter.count >= 3) {
        reporter.atNode(node, _code);
      }
    });
  }
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
