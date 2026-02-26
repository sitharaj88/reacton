import '../core/writable_reacton.dart';
import '../store/store.dart';

/// Performs an optimistic update with automatic rollback on failure.
///
/// The optimistic value is applied immediately (synchronous), then the
/// async mutation runs. If the mutation succeeds, the server-confirmed
/// value is set. If it fails, the previous value is restored.
///
/// ```dart
/// await store.optimistic(
///   reacton: todosReacton,
///   optimisticValue: [...currentTodos, newTodo],
///   mutation: () => api.addTodo(newTodo),
///   onRollback: (error) => showSnackBar('Failed: $error'),
/// );
/// ```
class OptimisticUpdate<T> {
  final ReactonStore _store;
  final WritableReacton<T> _reacton;

  OptimisticUpdate(this._store, this._reacton);

  /// Apply an optimistic value immediately, then run the async mutation.
  ///
  /// Returns the final value from the mutation on success.
  /// On failure, rolls back to the previous value and rethrows.
  Future<T> apply({
    required T optimisticValue,
    required Future<T> Function() mutation,
    void Function(Object error)? onRollback,
  }) async {
    final previousValue = _store.get(_reacton);

    // Apply optimistic value immediately (synchronous)
    _store.set(_reacton, optimisticValue);

    try {
      // Run the actual mutation
      final result = await mutation();
      // On success: set the server-confirmed value
      _store.set(_reacton, result);
      return result;
    } catch (error) {
      // On failure: rollback to previous value
      _store.set(_reacton, previousValue);
      onRollback?.call(error);
      rethrow;
    }
  }
}

/// Extension on ReactonStore for optimistic updates.
extension ReactonStoreOptimistic on ReactonStore {
  /// Perform an optimistic update with automatic rollback.
  Future<T> optimistic<T>({
    required WritableReacton<T> reacton,
    required T optimisticValue,
    required Future<T> Function() mutation,
    void Function(Object error)? onRollback,
  }) {
    return OptimisticUpdate<T>(this, reacton).apply(
      optimisticValue: optimisticValue,
      mutation: mutation,
      onRollback: onRollback,
    );
  }
}
