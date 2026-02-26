/// Testing utilities for Reacton state management.
///
/// Provides isolated test environments, reacton mocks, effect tracking,
/// and widget test helpers.
///
/// ```dart
/// import 'package:reacton_test/reacton_test.dart';
///
/// void main() {
///   test('counter increments', () {
///     final store = TestReactonStore();
///     store.set(counterReacton, 1);
///     store.expectReacton(counterReacton, 1);
///   });
/// }
/// ```
library reacton_test;

export 'src/test_store.dart';
export 'src/reacton_mock.dart';
export 'src/effect_tracker.dart';
export 'src/graph_assertions.dart';
export 'src/pump_helpers.dart';
