import 'package:flutter/material.dart';
import 'package:reacton/reacton.dart';

import 'reacton_scope.dart';

/// Builder called once an async reacton has resolved with data.
typedef SuspenseDataBuilder<T> = Widget Function(
  BuildContext context,
  T data,
);

/// Builder for a loading state.
typedef SuspenseLoadingBuilder = Widget Function(BuildContext context);

/// Builder for an error state.
typedef SuspenseErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// A widget that unwraps an [AsyncValue] reacton and renders the appropriate
/// state — loading, error, or data — without forcing callers to pattern-match
/// on [AsyncValue] inside their [build] method.
///
/// ```dart
/// final userReacton = asyncReacton<User>((read) => api.fetchUser());
///
/// ReactonSuspense<User>(
///   reacton: userReacton,
///   loading: (ctx) => const Center(child: CircularProgressIndicator()),
///   error: (ctx, err, stack) => ErrorView(err),
///   data: (ctx, user) => Text('Hello, ${user.name}'),
/// );
/// ```
///
/// When the reacton transitions back to [AsyncLoading] after a successful
/// fetch (revalidation), [ReactonSuspense] will by default keep showing the
/// last data — use [keepPreviousData] to tune this behavior.
class ReactonSuspense<T> extends StatefulWidget {
  /// The async reacton to unwrap.
  final ReactonBase<AsyncValue<T>> reacton;

  /// Builder called when the reacton has data.
  final SuspenseDataBuilder<T> data;

  /// Builder called while the reacton is loading.
  final SuspenseLoadingBuilder loading;

  /// Builder called when the reacton errored. Defaults to a plain [ErrorWidget].
  final SuspenseErrorBuilder? error;

  /// If `true` (the default), render previous data while the reacton is
  /// revalidating (stale-while-revalidate). Set to `false` to show the
  /// [loading] builder on every transition back to [AsyncLoading].
  final bool keepPreviousData;

  const ReactonSuspense({
    super.key,
    required this.reacton,
    required this.data,
    required this.loading,
    this.error,
    this.keepPreviousData = true,
  });

  @override
  State<ReactonSuspense<T>> createState() => _ReactonSuspenseState<T>();
}

class _ReactonSuspenseState<T> extends State<ReactonSuspense<T>> {
  ReactonStore? _store;
  Unsubscribe? _unsubscribe;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resubscribe();
  }

  @override
  void didUpdateWidget(ReactonSuspense<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reacton.ref != widget.reacton.ref) {
      _resubscribe();
    }
  }

  void _resubscribe() {
    _unsubscribe?.call();
    _store = ReactonScope.of(context);
    _unsubscribe = _store!.subscribe(widget.reacton, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _store!.get(widget.reacton);

    return switch (value) {
      AsyncData(value: final v) => widget.data(context, v),
      AsyncLoading(previousData: final prev)
          when widget.keepPreviousData && prev is T =>
        widget.data(context, prev),
      AsyncLoading() => widget.loading(context),
      AsyncError(
        error: final e,
        stackTrace: final st,
        previousData: final prev,
      ) =>
        _renderError(context, e, st, prev),
    };
  }

  Widget _renderError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    T? previousData,
  ) {
    if (widget.keepPreviousData && previousData is T) {
      return widget.data(context, previousData);
    }
    final builder = widget.error;
    if (builder != null) return builder(context, error, stackTrace);
    return ErrorWidget(error);
  }
}
