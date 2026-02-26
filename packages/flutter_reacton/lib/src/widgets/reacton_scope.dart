import 'package:flutter/widgets.dart';
import 'package:reacton/reacton.dart';

/// Provides a [ReactonStore] to the widget tree.
///
/// Wrap your app (or a subtree) with [ReactonScope] to make reactons
/// available via [context.watch()], [context.read()], etc.
///
/// ```dart
/// void main() => runApp(
///   ReactonScope(child: MyApp()),
/// );
/// ```
class ReactonScope extends InheritedWidget {
  /// The store provided to the widget tree.
  final ReactonStore store;

  /// Create a ReactonScope with an optional existing store.
  ///
  /// If no store is provided, a new one is created automatically.
  /// Use [overrides] to override reacton values for testing.
  ReactonScope({
    super.key,
    ReactonStore? store,
    List<ReactonOverride>? overrides,
    required super.child,
  }) : store = _createStore(store, overrides);

  static ReactonStore _createStore(
    ReactonStore? store,
    List<ReactonOverride>? overrides,
  ) {
    final s = store ?? ReactonStore();
    if (overrides != null) {
      for (final override in overrides) {
        override._apply(s);
      }
    }
    return s;
  }

  /// Get the [ReactonStore] from the nearest [ReactonScope] ancestor.
  ///
  /// Throws if no [ReactonScope] is found.
  static ReactonStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ReactonScope>();
    assert(scope != null, 'No ReactonScope found in widget tree. '
        'Wrap your app with ReactonScope.');
    return scope!.store;
  }

  /// Get the [ReactonStore] from the nearest [ReactonScope] ancestor,
  /// without creating a dependency (won't rebuild on store change).
  static ReactonStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ReactonScope>();
    assert(scope != null, 'No ReactonScope found in widget tree.');
    return scope!.store;
  }

  /// Get the [ReactonStore] if available, or null.
  static ReactonStore? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ReactonScope>()?.store;
  }

  @override
  bool updateShouldNotify(ReactonScope oldWidget) => store != oldWidget.store;
}

/// Override a reacton's value (used for testing and configuration).
class ReactonOverride<T> {
  final ReactonBase<T> reacton;
  final T value;

  const ReactonOverride(this.reacton, this.value);

  void _apply(ReactonStore store) {
    store.forceSet(reacton, value);
  }
}
