/// An interceptor that can transform or reject reacton updates.
///
/// More lightweight than [Middleware] - designed for simple value
/// transformation and gating logic.
class Interceptor<T> {
  /// Debug name for this interceptor.
  final String name;

  /// Transform the value before it's written. Return the new value.
  final T Function(T value)? onWrite;

  /// Transform the value when it's read.
  final T Function(T value)? onRead;

  /// Gate function: return false to reject the update entirely.
  final bool Function(T oldValue, T newValue)? shouldUpdate;

  const Interceptor({
    required this.name,
    this.onWrite,
    this.onRead,
    this.shouldUpdate,
  });
}

/// A chain of interceptors executed in order.
class InterceptorChain<T> {
  final List<Interceptor<T>> _interceptors;

  const InterceptorChain(this._interceptors);

  /// Run all interceptors' write handlers. Returns the final value,
  /// or null if the update was rejected.
  (bool accepted, T value) executeWrite(T currentValue, T newValue) {
    var value = newValue;

    for (final interceptor in _interceptors) {
      // Check gate
      if (interceptor.shouldUpdate != null) {
        if (!interceptor.shouldUpdate!(currentValue, value)) {
          return (false, currentValue);
        }
      }
      // Transform
      if (interceptor.onWrite != null) {
        value = interceptor.onWrite!(value);
      }
    }

    return (true, value);
  }

  /// Run all interceptors' read handlers.
  T executeRead(T value) {
    var result = value;
    for (final interceptor in _interceptors) {
      if (interceptor.onRead != null) {
        result = interceptor.onRead!(result);
      }
    }
    return result;
  }
}
