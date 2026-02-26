import '../core/reacton_base.dart';
import 'middleware.dart';

/// Built-in middleware that logs reacton lifecycle events.
///
/// ```dart
/// final counterReacton = reacton(0, options: ReactonOptions(
///   middleware: [LoggingMiddleware('counter')],
/// ));
/// ```
class LoggingMiddleware<T> extends Middleware<T> {
  final String _tag;
  final void Function(String message)? _logger;

  /// Create a logging middleware.
  ///
  /// [tag] is a prefix for log messages.
  /// [logger] is an optional custom log function (defaults to print).
  LoggingMiddleware(this._tag, {void Function(String)? logger})
      : _logger = logger;

  void _log(String message) {
    if (_logger != null) {
      _logger!(message);
    }
  }

  @override
  T onInit(ReactonBase<T> reacton, T initialValue) {
    _log('[$_tag] Initialized: $initialValue');
    return initialValue;
  }

  @override
  T onBeforeWrite(ReactonBase<T> reacton, T currentValue, T newValue) {
    _log('[$_tag] Writing: $currentValue -> $newValue');
    return newValue;
  }

  @override
  void onAfterWrite(ReactonBase<T> reacton, T value) {
    _log('[$_tag] Written: $value');
  }

  @override
  void onDispose(ReactonBase<T> reacton) {
    _log('[$_tag] Disposed');
  }

  @override
  void onError(ReactonBase<T> reacton, Object error, StackTrace stackTrace) {
    _log('[$_tag] Error: $error');
  }
}
