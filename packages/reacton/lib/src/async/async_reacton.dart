import '../core/reacton_base.dart';
import 'async_value.dart';
import 'retry.dart';

/// A reacton that manages an asynchronous value.
///
/// The fetch function is called automatically when dependencies change.
/// In-flight requests are cancelled when a new fetch starts.
///
/// ```dart
/// final weatherReacton = asyncReacton<Weather>((read) async {
///   final city = read(selectedCityReacton);
///   return await weatherApi.getWeather(city);
/// }, name: 'weather');
/// ```
class AsyncReacton<T> extends ReactonBase<AsyncValue<T>> {
  /// The async fetch function.
  final Future<T> Function(ReactonReader read) fetch;

  /// Retry policy for failed fetches.
  final RetryPolicy? retryPolicy;

  /// Auto-refresh interval.
  final Duration? refreshInterval;

  /// Whether to cancel in-flight requests when the reacton is disposed.
  final bool cancelOnDispose;

  AsyncReacton(
    this.fetch, {
    super.name,
    this.retryPolicy,
    this.refreshInterval,
    this.cancelOnDispose = true,
  });

  @override
  bool equals(AsyncValue<T> a, AsyncValue<T> b) => a == b;
}

/// Create an async reacton that fetches data when dependencies change.
///
/// The fetch function receives a [read] function for accessing
/// other reactons. Dependencies are automatically tracked.
///
/// ```dart
/// final userReacton = asyncReacton<User>((read) async {
///   final id = read(userIdReacton);
///   return await api.getUser(id);
/// }, name: 'user', retryPolicy: RetryPolicy(maxAttempts: 3));
/// ```
AsyncReacton<T> asyncReacton<T>(
  Future<T> Function(ReactonReader read) fetch, {
  String? name,
  RetryPolicy? retryPolicy,
  Duration? refreshInterval,
}) {
  return AsyncReacton<T>(
    fetch,
    name: name,
    retryPolicy: retryPolicy,
    refreshInterval: refreshInterval,
  );
}
