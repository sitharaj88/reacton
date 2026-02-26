import 'reacton_base.dart';

/// A read-only reacton that derives its value from other reactons.
///
/// The value is automatically recomputed when any dependency changes.
/// Created via the top-level [computed()] factory function.
///
/// ```dart
/// final doubleCountReacton = computed(
///   (read) => read(counterReacton) * 2,
///   name: 'doubleCount',
/// );
/// ```
class ReadonlyReacton<T> extends ReactonBase<T> {
  /// The computation function that derives this reacton's value.
  final T Function(ReactonReader read) compute;

  ReadonlyReacton(
    this.compute, {
    super.name,
    super.options,
  });
}

/// Create a computed (read-only) reacton that derives its value from other reactons.
///
/// The computation function receives a [read] function that can be used
/// to access other reactons. Dependencies are automatically tracked.
///
/// ```dart
/// final filteredTodosReacton = computed((read) {
///   final todos = read(todosReacton);
///   final filter = read(filterReacton);
///   return todos.where((t) => t.matches(filter)).toList();
/// }, name: 'filteredTodos');
/// ```
ReadonlyReacton<T> computed<T>(
  T Function(ReactonReader read) compute, {
  String? name,
  ReactonOptions<T>? options,
}) {
  return ReadonlyReacton<T>(compute, name: name, options: options);
}
