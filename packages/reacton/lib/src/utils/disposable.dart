/// Mixin for objects that hold resources and need cleanup.
mixin Disposable {
  bool _disposed = false;

  /// Whether this object has been disposed.
  bool get isDisposed => _disposed;

  /// Release all resources. Called automatically by the store
  /// when the reacton is no longer needed.
  void dispose() {
    _disposed = true;
  }

  /// Assert that this object has not been disposed.
  void assertNotDisposed() {
    assert(!_disposed, '$runtimeType has been disposed');
  }
}

/// A function that unsubscribes/cancels a subscription.
typedef Unsubscribe = void Function();
