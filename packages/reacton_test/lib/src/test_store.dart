import 'package:reacton/reacton.dart';

/// An isolated test store with support for overrides.
///
/// ```dart
/// final store = TestReactonStore(overrides: [
///   ReactonOverride(counterReacton, 10),
///   AsyncReactonOverride.data(weatherReacton, sunny),
/// ]);
/// ```
class TestReactonStore extends ReactonStore {
  TestReactonStore({
    List<TestOverride>? overrides,
    StorageAdapter? storageAdapter,
  }) : super(storageAdapter: storageAdapter ?? MemoryStorage()) {
    if (overrides != null) {
      for (final override in overrides) {
        override.apply(this);
      }
    }
  }
}

/// Base class for test overrides.
abstract class TestOverride {
  void apply(ReactonStore store);
}

/// Override a writable reacton's initial value.
class ReactonTestOverride<T> extends TestOverride {
  final ReactonBase<T> reacton;
  final T value;

  ReactonTestOverride(this.reacton, this.value);

  @override
  void apply(ReactonStore store) {
    store.forceSet(reacton, value);
  }
}

/// Override an async reacton to return a synchronous value.
class AsyncReactonTestOverride<T> extends TestOverride {
  final ReactonBase<AsyncValue<T>> reacton;
  final AsyncValue<T> value;

  AsyncReactonTestOverride._(this.reacton, this.value);

  /// Override with data.
  factory AsyncReactonTestOverride.data(ReactonBase<AsyncValue<T>> reacton, T data) {
    return AsyncReactonTestOverride._(reacton, AsyncData(data));
  }

  /// Override with loading state.
  factory AsyncReactonTestOverride.loading(ReactonBase<AsyncValue<T>> reacton) {
    return AsyncReactonTestOverride._(reacton, const AsyncLoading());
  }

  /// Override with error state.
  factory AsyncReactonTestOverride.error(
    ReactonBase<AsyncValue<T>> reacton,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    return AsyncReactonTestOverride._(reacton, AsyncError(error, stackTrace));
  }

  @override
  void apply(ReactonStore store) {
    store.forceSet(reacton, value);
  }
}
