import 'package:flutter/widgets.dart';
import 'package:reacton/reacton.dart';

import 'reacton_scope.dart';

/// A widget that listens to reacton changes for side effects
/// without rebuilding.
///
/// Use this for navigation, showing snackbars, dialogs, etc.
///
/// ```dart
/// ReactonListener(
///   reacton: errorReacton,
///   listener: (context, error) {
///     if (error != null) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(error)),
///       );
///     }
///   },
///   child: MyWidget(),
/// )
/// ```
class ReactonListener<T> extends StatefulWidget {
  /// The reacton to listen to.
  final ReactonBase<T> reacton;

  /// Called when the reacton's value changes.
  final void Function(BuildContext context, T value) listener;

  /// Optional condition for when to call the listener.
  final bool Function(T previous, T current)? listenWhen;

  /// Child widget (not rebuilt on changes).
  final Widget child;

  const ReactonListener({
    super.key,
    required this.reacton,
    required this.listener,
    this.listenWhen,
    required this.child,
  });

  @override
  State<ReactonListener<T>> createState() => _ReactonListenerState<T>();
}

class _ReactonListenerState<T> extends State<ReactonListener<T>> {
  ReactonStore? _store;
  Unsubscribe? _unsubscribe;
  T? _previousValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unsubscribe?.call();
    _store = ReactonScope.of(context);
    _previousValue = _store!.get(widget.reacton);

    _unsubscribe = _store!.subscribe(widget.reacton, (T value) {
      if (!mounted) return;

      final shouldNotify = widget.listenWhen == null ||
          widget.listenWhen!(_previousValue as T, value);

      if (shouldNotify) {
        widget.listener(context, value);
      }

      _previousValue = value;
    });
  }

  @override
  void didUpdateWidget(ReactonListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reacton.ref != widget.reacton.ref) {
      _unsubscribe?.call();
      _store = ReactonScope.of(context);
      _previousValue = _store!.get(widget.reacton);
      _unsubscribe = _store!.subscribe(widget.reacton, (T value) {
        if (!mounted) return;
        final shouldNotify = widget.listenWhen == null ||
            widget.listenWhen!(_previousValue as T, value);
        if (shouldNotify) {
          widget.listener(context, value);
        }
        _previousValue = value;
      });
    }
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
