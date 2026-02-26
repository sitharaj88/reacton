/// Handles batching of updates for the reactive graph.
///
/// Reacton uses synchronous batching (no microtask delays) for predictable
/// and fast state propagation. All mutations within a [batch()] call
/// are collected and propagated together at the end.
class UpdateScheduler {
  bool _isBatching = false;
  final List<void Function()> _pendingFlushes = [];
  void Function()? _onFlush;

  /// Whether we're currently inside a batch.
  bool get isBatching => _isBatching;

  /// Set the flush handler (called by ReactiveGraph).
  set onFlush(void Function() handler) => _onFlush = handler;

  /// Execute [fn] in a batch. All mutations within are
  /// propagated together at the end.
  ///
  /// Batches can be nested; only the outermost batch triggers propagation.
  void batch(void Function() fn) {
    if (_isBatching) {
      // Nested batch: just execute, outer batch will flush
      fn();
      return;
    }

    _isBatching = true;
    try {
      fn();
      _flush();
    } finally {
      _isBatching = false;
    }
  }

  /// Schedule a propagation. If inside a batch, defers until batch ends.
  /// If outside a batch, executes immediately.
  void scheduleFlush() {
    if (_isBatching) {
      // Defer: will be flushed at end of batch
      if (_pendingFlushes.isEmpty && _onFlush != null) {
        _pendingFlushes.add(_onFlush!);
      }
    } else {
      // Immediate propagation
      _onFlush?.call();
    }
  }

  void _flush() {
    while (_pendingFlushes.isNotEmpty) {
      final flushes = List.of(_pendingFlushes);
      _pendingFlushes.clear();
      for (final flush in flushes) {
        flush();
      }
    }
  }
}
