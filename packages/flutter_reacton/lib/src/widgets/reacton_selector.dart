import 'package:flutter/widgets.dart';
import 'package:reacton/reacton.dart';

import 'reacton_scope.dart';

/// A widget that rebuilds only when a selected sub-value changes.
///
/// More efficient than [ReactonBuilder] when you only need a
/// small part of a complex reacton's value.
///
/// ```dart
/// ReactonSelector<User, String>(
///   reacton: userReacton,
///   selector: (user) => user.name,
///   builder: (context, name) => Text(name),
/// )
/// ```
class ReactonSelector<T, S> extends StatefulWidget {
  /// The source reacton.
  final ReactonBase<T> reacton;

  /// Function to extract the sub-value.
  final S Function(T value) selector;

  /// Builder called with the selected sub-value.
  final Widget Function(BuildContext context, S selected) builder;

  const ReactonSelector({
    super.key,
    required this.reacton,
    required this.selector,
    required this.builder,
  });

  @override
  State<ReactonSelector<T, S>> createState() => _ReactonSelectorState<T, S>();
}

class _ReactonSelectorState<T, S> extends State<ReactonSelector<T, S>> {
  ReactonStore? _store;
  Unsubscribe? _unsubscribe;
  S? _lastSelected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resubscribe();
  }

  @override
  void didUpdateWidget(ReactonSelector<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reacton.ref != widget.reacton.ref) {
      _resubscribe();
    }
  }

  void _resubscribe() {
    _unsubscribe?.call();
    _store = ReactonScope.of(context);
    _lastSelected = widget.selector(_store!.get(widget.reacton));

    _unsubscribe = _store!.subscribe(widget.reacton, (T value) {
      if (!mounted) return;
      final newSelected = widget.selector(value);
      if (newSelected != _lastSelected) {
        _lastSelected = newSelected;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.selector(_store!.get(widget.reacton));
    _lastSelected = value;
    return widget.builder(context, value);
  }
}
