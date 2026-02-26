import 'package:flutter/widgets.dart';
import 'package:reacton/reacton.dart';

import 'reacton_scope.dart';

/// A ref object that provides access to reactons within a [ReactonConsumer].
///
/// Use [watch] to subscribe to reactons (rebuilds on change) and
/// [read] for one-time reads (no subscription).
class ReactonWidgetRef {
  final ReactonStore _store;
  final List<Unsubscribe> _subscriptions = [];
  final Set<ReactonRef> _watchedRefs = {};
  final void Function() _markNeedsBuild;

  ReactonWidgetRef(this._store, this._markNeedsBuild);

  /// Watch a reacton - subscribes and rebuilds on change.
  T watch<T>(ReactonBase<T> reacton) {
    if (!_watchedRefs.contains(reacton.ref)) {
      _watchedRefs.add(reacton.ref);
      final unsub = _store.subscribe(reacton, (_) => _markNeedsBuild());
      _subscriptions.add(unsub);
    }
    return _store.get(reacton);
  }

  /// Read a reacton without subscribing.
  T read<T>(ReactonBase<T> reacton) => _store.get(reacton);

  /// Set a writable reacton's value.
  void set<T>(WritableReacton<T> reacton, T value) => _store.set(reacton, value);

  /// Update a writable reacton using a function.
  void update<T>(WritableReacton<T> reacton, T Function(T) updater) {
    _store.update(reacton, updater);
  }

  /// The underlying store.
  ReactonStore get store => _store;

  /// Clean up all subscriptions.
  void dispose() {
    for (final unsub in _subscriptions) {
      unsub();
    }
    _subscriptions.clear();
    _watchedRefs.clear();
  }
}

/// A widget that provides a [ReactonWidgetRef] for watching multiple reactons.
///
/// More flexible than [ReactonBuilder] - allows watching any number of
/// reactons within a single builder.
///
/// ```dart
/// ReactonConsumer(
///   builder: (context, ref) {
///     final count = ref.watch(counterReacton);
///     final name = ref.watch(nameReacton);
///     return Text('$name: $count');
///   },
/// )
/// ```
class ReactonConsumer extends StatefulWidget {
  /// Builder function with access to a [ReactonWidgetRef].
  final Widget Function(BuildContext context, ReactonWidgetRef ref) builder;

  const ReactonConsumer({
    super.key,
    required this.builder,
  });

  @override
  State<ReactonConsumer> createState() => _ReactonConsumerState();
}

class _ReactonConsumerState extends State<ReactonConsumer> {
  ReactonWidgetRef? _ref;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ref?.dispose();
    final store = ReactonScope.of(context);
    _ref = ReactonWidgetRef(store, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ref?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dispose old subscriptions and create fresh ones each build
    // to handle conditional watches
    _ref!.dispose();
    final store = ReactonScope.of(context);
    _ref = ReactonWidgetRef(store, () {
      if (mounted) setState(() {});
    });
    return widget.builder(context, _ref!);
  }
}
