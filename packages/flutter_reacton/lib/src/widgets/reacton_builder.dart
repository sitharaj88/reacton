import 'package:flutter/widgets.dart';
import 'package:reacton/reacton.dart';

import 'reacton_scope.dart';

/// A widget that rebuilds when a reacton's value changes.
///
/// This is the simplest way to react to state changes in the UI.
///
/// ```dart
/// ReactonBuilder(
///   reacton: counterReacton,
///   builder: (context, count) => Text('$count'),
/// )
/// ```
class ReactonBuilder<T> extends StatefulWidget {
  /// The reacton to watch.
  final ReactonBase<T> reacton;

  /// Builder function called with the current value.
  final Widget Function(BuildContext context, T value) builder;

  const ReactonBuilder({
    super.key,
    required this.reacton,
    required this.builder,
  });

  @override
  State<ReactonBuilder<T>> createState() => _ReactonBuilderState<T>();
}

class _ReactonBuilderState<T> extends State<ReactonBuilder<T>> {
  ReactonStore? _store;
  Unsubscribe? _unsubscribe;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resubscribe();
  }

  @override
  void didUpdateWidget(ReactonBuilder<T> oldWidget) {
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
    return widget.builder(context, _store!.get(widget.reacton));
  }
}
