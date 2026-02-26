/// Policy for retrying failed async operations.
///
/// ```dart
/// final dataReacton = asyncReacton<Data>(
///   (read) => api.fetchData(),
///   retryPolicy: RetryPolicy(
///     maxAttempts: 3,
///     initialDelay: Duration(seconds: 1),
///     shouldRetry: (e) => e is NetworkException,
///   ),
/// );
/// ```
class RetryPolicy {
  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Multiplier applied to the delay after each retry (exponential backoff).
  final double backoffMultiplier;

  /// Maximum delay between retries.
  final Duration? maxDelay;

  /// Function to determine if a specific error should be retried.
  /// Returns true to retry, false to fail immediately.
  final bool Function(Object error)? shouldRetry;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay,
    this.shouldRetry,
  });

  /// Calculate the delay for a given attempt number (0-indexed).
  Duration delayForAttempt(int attempt) {
    final ms = initialDelay.inMilliseconds *
        _pow(backoffMultiplier, attempt);
    final delay = Duration(milliseconds: ms.round());
    if (maxDelay != null && delay > maxDelay!) {
      return maxDelay!;
    }
    return delay;
  }

  /// Whether the given error should be retried.
  bool canRetry(Object error, int attempt) {
    if (attempt >= maxAttempts) return false;
    if (shouldRetry != null) return shouldRetry!(error);
    return true;
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
