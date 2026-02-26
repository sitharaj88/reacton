import 'dart:async';

/// Debounce utility for rate-limiting function calls.
///
/// Only executes the function after the specified duration has passed
/// without another call.
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer(this.duration);

  /// Run the function after the debounce period.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel any pending execution.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether a call is pending.
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose the debouncer.
  void dispose() {
    cancel();
  }
}

/// Throttle utility for rate-limiting function calls.
///
/// Executes the function at most once per specified duration.
class Throttler {
  final Duration duration;
  DateTime? _lastRun;
  Timer? _timer;

  Throttler(this.duration);

  /// Run the function, throttled to once per duration.
  void run(void Function() action) {
    final now = DateTime.now();

    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
    } else {
      // Schedule for later if not already scheduled
      _timer?.cancel();
      final remaining = duration - now.difference(_lastRun!);
      _timer = Timer(remaining, () {
        _lastRun = DateTime.now();
        action();
      });
    }
  }

  /// Cancel any pending execution.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose the throttler.
  void dispose() {
    cancel();
  }
}
