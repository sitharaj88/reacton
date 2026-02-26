/// Tracks invocations of effects for testing.
///
/// ```dart
/// final tracker = EffectTracker();
///
/// final dispose = store.registerEffect(createEffect((read) {
///   tracker.record('myEffect');
///   final count = read(counterReacton);
///   return null;
/// }));
///
/// store.set(counterReacton, 1);
/// expect(tracker.callCount('myEffect'), 2); // initial + update
/// ```
class EffectTracker {
  final List<EffectInvocation> _invocations = [];

  /// Record an effect invocation.
  void record(String name, [Map<String, dynamic>? metadata]) {
    _invocations.add(EffectInvocation(
      name: name,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// All recorded invocations.
  List<EffectInvocation> get invocations => List.unmodifiable(_invocations);

  /// Number of times any effect was called.
  int get totalCallCount => _invocations.length;

  /// Number of times a specific effect was called.
  int callCount(String name) =>
      _invocations.where((i) => i.name == name).length;

  /// Whether a specific effect was ever called.
  bool wasCalled(String name) => _invocations.any((i) => i.name == name);

  /// Whether any effect was called.
  bool get wasAnyCalled => _invocations.isNotEmpty;

  /// Get invocations for a specific effect.
  List<EffectInvocation> invocationsOf(String name) =>
      _invocations.where((i) => i.name == name).toList();

  /// Clear all recorded invocations.
  void reset() => _invocations.clear();
}

/// A single effect invocation record.
class EffectInvocation {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const EffectInvocation({
    required this.name,
    required this.timestamp,
    this.metadata,
  });

  @override
  String toString() => 'EffectInvocation($name, $timestamp)';
}
