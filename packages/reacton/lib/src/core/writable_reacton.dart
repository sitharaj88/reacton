import 'reacton_base.dart';

/// A writable reacton holds a mutable value that can be read and written.
///
/// This is the primary building block of Reacton state management.
/// Created via the top-level [reacton()] factory function.
///
/// ```dart
/// final counterReacton = reacton(0, name: 'counter');
/// final nameReacton = reacton('', name: 'name');
/// ```
class WritableReacton<T> extends ReactonBase<T> {
  /// The initial value of this reacton before any writes.
  final T initialValue;

  /// Optional custom write handler.
  final void Function(void Function<V>(WritableReacton<V>, V) set, T value)?
      onWrite;

  WritableReacton(
    this.initialValue, {
    super.name,
    super.options,
    this.onWrite,
  });
}

/// Create a writable reacton with the given initial value.
///
/// This is the simplest way to create reactive state in Reacton.
///
/// ```dart
/// final counterReacton = reacton(0, name: 'counter');
/// final nameReacton = reacton('World', name: 'name');
/// ```
WritableReacton<T> reacton<T>(
  T initialValue, {
  String? name,
  ReactonOptions<T>? options,
  void Function(void Function<V>(WritableReacton<V>, V) set, T value)? onWrite,
}) {
  return WritableReacton<T>(
    initialValue,
    name: name,
    options: options,
    onWrite: onWrite,
  );
}
