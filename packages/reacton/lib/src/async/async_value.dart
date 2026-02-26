/// Represents the state of an asynchronous operation.
///
/// [AsyncValue] is a sealed class with three states:
/// - [AsyncLoading] - The operation is in progress
/// - [AsyncData] - The operation completed with data
/// - [AsyncError] - The operation failed with an error
///
/// Supports stale-while-revalidate: [AsyncLoading] and [AsyncError] can
/// carry [previousData] from the last successful fetch.
///
/// ```dart
/// final weather = context.watch(weatherReacton);
/// weather.when(
///   loading: () => CircularProgressIndicator(),
///   data: (w) => Text('${w.temp}°C'),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
sealed class AsyncValue<T> {
  const AsyncValue();

  /// Create a loading state.
  const factory AsyncValue.loading([T? previousData]) = AsyncLoading<T>;

  /// Create a data (success) state.
  const factory AsyncValue.data(T value) = AsyncData<T>;

  /// Create an error state.
  const factory AsyncValue.error(Object error,
      [StackTrace? stackTrace, T? previousData]) = AsyncError<T>;

  /// Pattern match on the three states.
  R when<R>({
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    return switch (this) {
      AsyncLoading() => loading(),
      AsyncData(value: final v) => data(v),
      AsyncError(error: final e, stackTrace: final st) => error(e, st),
    };
  }

  /// Pattern match with a builder that receives previous data during loading.
  R whenOrElse<R>({
    R Function(T? previousData)? loading,
    R Function(T data)? data,
    R Function(Object error, StackTrace? stackTrace, T? previousData)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncLoading(previousData: final prev) =>
        loading?.call(prev) ?? orElse(),
      AsyncData(value: final v) => data?.call(v) ?? orElse(),
      AsyncError(
        error: final e,
        stackTrace: final st,
        previousData: final prev
      ) =>
        error?.call(e, st, prev) ?? orElse(),
    };
  }

  /// Map the data value to a new type.
  AsyncValue<R> map<R>(R Function(T) transform) {
    return switch (this) {
      AsyncLoading(previousData: final prev) =>
        AsyncValue<R>.loading(prev != null ? transform(prev) : null),
      AsyncData(value: final v) => AsyncValue<R>.data(transform(v)),
      AsyncError(
        error: final e,
        stackTrace: final st,
        previousData: final prev
      ) =>
        AsyncValue<R>.error(
            e, st, prev != null ? transform(prev) : null),
    };
  }

  /// Get the data value, or null if not in data state.
  T? get valueOrNull => switch (this) {
        AsyncData(value: final v) => v,
        AsyncLoading(previousData: final prev) => prev,
        AsyncError(previousData: final prev) => prev,
      };

  /// Whether this is currently loading.
  bool get isLoading => this is AsyncLoading<T>;

  /// Whether this has data.
  bool get hasData => this is AsyncData<T>;

  /// Whether this has an error.
  bool get hasError => this is AsyncError<T>;

  /// Whether there is any data (current or stale).
  bool get hasValue => valueOrNull != null;
}

/// Loading state - an async operation is in progress.
class AsyncLoading<T> extends AsyncValue<T> {
  /// Previous successful data (for stale-while-revalidate).
  final T? previousData;

  const AsyncLoading([this.previousData]);

  @override
  bool operator ==(Object other) =>
      other is AsyncLoading<T> && other.previousData == previousData;

  @override
  int get hashCode => previousData.hashCode;

  @override
  String toString() => 'AsyncLoading(previousData: $previousData)';
}

/// Data state - the async operation completed successfully.
class AsyncData<T> extends AsyncValue<T> {
  /// The successful result.
  final T value;

  const AsyncData(this.value);

  @override
  bool operator ==(Object other) =>
      other is AsyncData<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AsyncData($value)';
}

/// Error state - the async operation failed.
class AsyncError<T> extends AsyncValue<T> {
  /// The error that occurred.
  final Object error;

  /// The stack trace of the error.
  final StackTrace? stackTrace;

  /// Previous successful data (for stale-while-revalidate).
  final T? previousData;

  const AsyncError(this.error, [this.stackTrace, this.previousData]);

  @override
  bool operator ==(Object other) =>
      other is AsyncError<T> &&
      other.error == error &&
      other.previousData == previousData;

  @override
  int get hashCode => Object.hash(error, previousData);

  @override
  String toString() => 'AsyncError($error, previousData: $previousData)';
}
