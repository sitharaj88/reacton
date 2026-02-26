/// Template for generating feature reacton files.
const featureReactonsTemplate = r'''
import 'package:reacton/reacton.dart';

// --- {{pascalName}} Feature Reactons ---

/// Main state reacton for {{name}}.
final {{camelName}}Reacton = reacton<String>(
  '',
  name: '{{snakeName}}',
);

/// Loading state for {{name}}.
final {{camelName}}LoadingReacton = reacton<bool>(
  false,
  name: '{{snakeName}}_loading',
);

/// Error state for {{name}}.
final {{camelName}}ErrorReacton = reacton<String?>(
  null,
  name: '{{snakeName}}_error',
);

/// Computed status that combines loading and error.
final {{camelName}}StatusReacton = computed<String>(
  (read) {
    final loading = read({{camelName}}LoadingReacton);
    final error = read({{camelName}}ErrorReacton);
    if (loading) return 'loading';
    if (error != null) return 'error';
    return 'ready';
  },
  name: '{{snakeName}}_status',
);
''';

/// Template for generating feature widget files.
const featureWidgetTemplate = r'''
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import '{{snakeName}}_reactons.dart';

class {{pascalName}}Page extends StatelessWidget {
  const {{pascalName}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final value = context.watch({{camelName}}Reacton);
    final isLoading = context.watch({{camelName}}LoadingReacton);
    final error = context.watch({{camelName}}ErrorReacton);

    return Scaffold(
      appBar: AppBar(title: const Text('{{pascalName}}')),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.set({{camelName}}ErrorReacton, null),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text(value));
        },
      ),
    );
  }
}
''';

/// Template for generating feature test files.
const featureTestTemplate = r'''
import 'package:flutter_test/flutter_test.dart';
import 'package:reacton/reacton.dart';

import 'package:{{package}}/features/{{snakeName}}/{{snakeName}}_reactons.dart';

void main() {
  late ReactonStore store;

  setUp(() {
    store = ReactonStore();
  });

  tearDown(() {
    store.dispose();
  });

  group('{{pascalName}} reactons', () {
    test('{{camelName}}Reacton has correct default value', () {
      expect(store.get({{camelName}}Reacton), equals(''));
    });

    test('{{camelName}}LoadingReacton defaults to false', () {
      expect(store.get({{camelName}}LoadingReacton), isFalse);
    });

    test('{{camelName}}ErrorReacton defaults to null', () {
      expect(store.get({{camelName}}ErrorReacton), isNull);
    });

    test('{{camelName}}StatusReacton reflects loading state', () {
      store.set({{camelName}}LoadingReacton, true);
      expect(store.get({{camelName}}StatusReacton), equals('loading'));
    });

    test('{{camelName}}StatusReacton reflects error state', () {
      store.set({{camelName}}ErrorReacton, 'Something went wrong');
      expect(store.get({{camelName}}StatusReacton), equals('error'));
    });

    test('{{camelName}}StatusReacton shows ready by default', () {
      expect(store.get({{camelName}}StatusReacton), equals('ready'));
    });
  });
}
''';
