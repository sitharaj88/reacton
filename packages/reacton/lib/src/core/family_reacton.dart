import 'reacton_base.dart';

/// A factory that creates parameterized reactons on-demand.
///
/// Each unique argument produces a distinct reacton instance.
/// Useful for data that is keyed by an ID or parameter.
///
/// ```dart
/// final userReacton = family<AsyncValue<User>, int>((userId) {
///   return asyncReacton((read) => api.getUser(userId), name: 'user_$userId');
/// });
///
/// // In widget:
/// final user = context.watch(userReacton(42));
/// ```
class ReactonFamily<T, Arg> {
  final ReactonBase<T> Function(Arg arg) _create;
  final Map<Arg, ReactonBase<T>> _cache = {};

  ReactonFamily(this._create);

  /// Get or create the reacton for the given argument.
  ReactonBase<T> call(Arg arg) {
    return _cache.putIfAbsent(arg, () => _create(arg));
  }

  /// Check if a reacton exists for the given argument.
  bool contains(Arg arg) => _cache.containsKey(arg);

  /// Remove the cached reacton for the given argument.
  void remove(Arg arg) => _cache.remove(arg);

  /// Remove all cached reactons.
  void clear() => _cache.clear();

  /// All currently cached arguments.
  Iterable<Arg> get keys => _cache.keys;

  /// All currently cached reactons.
  Iterable<ReactonBase<T>> get reactons => _cache.values;
}

/// Create a family of parameterized reactons.
///
/// The factory function is called once per unique argument value.
/// Results are cached so the same argument always returns the same reacton.
///
/// ```dart
/// final todoDetailReacton = family<AsyncValue<TodoDetail>, String>((todoId) {
///   return asyncReacton((read) => api.getTodoDetail(todoId));
/// });
/// ```
ReactonFamily<T, Arg> family<T, Arg>(ReactonBase<T> Function(Arg arg) create) {
  return ReactonFamily<T, Arg>(create);
}
