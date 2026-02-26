import '../core/reacton_base.dart';

/// Base class for reacton middleware.
///
/// Middleware intercepts reacton lifecycle events: initialization, reads,
/// writes, and disposal. Use middleware for cross-cutting concerns like
/// logging, validation, persistence, and analytics.
///
/// ```dart
/// class LoggingMiddleware<T> extends Middleware<T> {
///   @override
///   void onAfterWrite(ReactonBase<T> reacton, T value) {
///     print('${reacton.ref}: $value');
///   }
/// }
/// ```
abstract class Middleware<T> {
  /// Called when the reacton is first initialized. Return the initial value
  /// (possibly modified).
  T onInit(ReactonBase<T> reacton, T initialValue) => initialValue;

  /// Called before a value is written to the reacton.
  /// Return the (possibly modified) value, or throw to reject the write.
  T onBeforeWrite(ReactonBase<T> reacton, T currentValue, T newValue) => newValue;

  /// Called after a value has been written and propagated.
  void onAfterWrite(ReactonBase<T> reacton, T value) {}

  /// Called when the reacton is disposed from the store.
  void onDispose(ReactonBase<T> reacton) {}

  /// Called when an error occurs during computation.
  void onError(ReactonBase<T> reacton, Object error, StackTrace stackTrace) {}
}
