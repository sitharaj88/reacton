import 'package:flutter/material.dart';
import 'package:reacton/reacton.dart';

import 'reacton_scope.dart';

/// Builder for the fallback UI shown when the boundary catches an error.
/// The `reset` callback invokes [ReactonErrorBoundary.onReset] if provided.
typedef ErrorBoundaryFallback = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
  VoidCallback reset,
);

/// Builder for the loading UI shown while any watched reacton is loading.
typedef ErrorBoundaryLoadingBuilder = Widget Function(BuildContext context);

/// A widget that groups multiple async reactons under a single loading and
/// error surface — the Flutter-friendly equivalent of a React error boundary.
///
/// Unlike [ReactonSuspense], which unwraps a single reacton, [ReactonErrorBoundary]
/// only renders [child] once **every** reacton in [reactons] has settled with
/// [AsyncData]. If any reacton is loading, [loading] is shown; if any errors,
/// [error] is shown with a `reset` callback that invokes [onReset].
///
/// ```dart
/// ReactonErrorBoundary(
///   reactons: [userReacton, postsReacton, settingsReacton],
///   loading: (ctx) => const CenteredSpinner(),
///   error: (ctx, err, stack, reset) => ErrorView(
///     error: err,
///     onRetry: reset,
///   ),
///   onReset: () {
///     // Invalidate every query in the boundary.
///     for (final r in [userReacton, postsReacton, settingsReacton]) {
///       if (r is QueryReacton) store.invalidateQuery(r);
///     }
///   },
///   child: const ProfilePage(),
/// );
/// ```
///
/// Inside [child] you can call `context.watch(userReacton)` without handling
/// the loading or error states — the boundary guarantees they've resolved.
/// Use `valueOrNull!` or pattern match only on `AsyncData` safely.
class ReactonErrorBoundary extends StatefulWidget {
  /// Every reacton watched by this boundary. Must be non-empty.
  final List<ReactonBase<AsyncValue<Object?>>> reactons;

  /// Rendered while any reacton is in [AsyncLoading].
  final ErrorBoundaryLoadingBuilder loading;

  /// Rendered when any reacton is in [AsyncError]. If `null`, a default
  /// [ErrorWidget] is shown (with no reset affordance).
  final ErrorBoundaryFallback? error;

  /// Invoked when the fallback's `reset` callback is triggered. Use it to
  /// invalidate queries, clear caches, or perform any recovery logic.
  final VoidCallback? onReset;

  /// Rendered once every reacton has [AsyncData].
  final Widget child;

  const ReactonErrorBoundary({
    super.key,
    required this.reactons,
    required this.loading,
    required this.child,
    this.error,
    this.onReset,
  }) : assert(reactons.length > 0, 'reactons must not be empty');

  @override
  State<ReactonErrorBoundary> createState() => _ReactonErrorBoundaryState();
}

class _ReactonErrorBoundaryState extends State<ReactonErrorBoundary> {
  ReactonStore? _store;
  final List<Unsubscribe> _unsubs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resubscribe();
  }

  @override
  void didUpdateWidget(ReactonErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRefs(oldWidget.reactons, widget.reactons)) {
      _resubscribe();
    }
  }

  bool _sameRefs(
    List<ReactonBase<AsyncValue<Object?>>> a,
    List<ReactonBase<AsyncValue<Object?>>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].ref != b[i].ref) return false;
    }
    return true;
  }

  void _resubscribe() {
    for (final u in _unsubs) {
      u();
    }
    _unsubs.clear();
    _store = ReactonScope.of(context);
    for (final reacton in widget.reactons) {
      _unsubs.add(
        _store!.subscribe<AsyncValue<Object?>>(reacton, (_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final u in _unsubs) {
      u();
    }
    _unsubs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // First pass: any error wins (error state takes priority over loading).
    for (final reacton in widget.reactons) {
      final v = _store!.get(reacton);
      if (v is AsyncError) {
        return _renderError(context, v.error, v.stackTrace);
      }
    }

    // Second pass: any loading means we're still settling.
    for (final reacton in widget.reactons) {
      final v = _store!.get(reacton);
      if (v is AsyncLoading) {
        return widget.loading(context);
      }
    }

    // All resolved with data.
    return widget.child;
  }

  Widget _renderError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final builder = widget.error;
    if (builder != null) {
      return builder(context, error, stackTrace, _reset);
    }
    return ErrorWidget(error);
  }

  void _reset() {
    final cb = widget.onReset;
    if (cb != null) cb();
  }
}
