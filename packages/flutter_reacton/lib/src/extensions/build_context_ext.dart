import 'package:flutter/widgets.dart';
import 'package:reacton/reacton.dart';

import '../widgets/reacton_scope.dart';

/// Subscription tracker that associates reacton subscriptions with an Element.
///
/// Uses [Expando] to attach tracker state to Elements without
/// requiring a custom widget base class.
class _ReactonSubscriptionTracker {
  final Map<ReactonRef, Unsubscribe> _unsubscribers = {};
  bool _disposed = false;

  final Element _element;

  _ReactonSubscriptionTracker(this._element);

  void track<T>(ReactonBase<T> reacton, ReactonStore store) {
    if (_disposed) return;
    if (_unsubscribers.containsKey(reacton.ref)) return;

    final unsub = store.subscribe(reacton, (_) {
      _scheduleRebuild();
    });
    _unsubscribers[reacton.ref] = unsub;
  }

  void _scheduleRebuild() {
    // Guard: element may have been unmounted since the subscription was created.
    // Check both our own disposed flag and the element's lifecycle.
    if (_disposed) return;
    try {
      if (_element.mounted) {
        _element.markNeedsBuild();
      } else {
        // Element is no longer active — clean up all subscriptions
        dispose();
      }
    } catch (_) {
      // Element is defunct — clean up
      dispose();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final unsub in _unsubscribers.values) {
      unsub();
    }
    _unsubscribers.clear();
  }

  static final _trackers = Expando<_ReactonSubscriptionTracker>();

  static _ReactonSubscriptionTracker of(Element element) {
    var tracker = _trackers[element];
    if (tracker == null || tracker._disposed) {
      tracker = _ReactonSubscriptionTracker(element);
      _trackers[element] = tracker;
    }
    return tracker;
  }
}

/// Extension on [BuildContext] for reactive reacton access.
///
/// These are the primary APIs for using Reacton in Flutter widgets.
extension ReactonBuildContextExtension on BuildContext {
  /// Watch a reacton - rebuilds this widget when the value changes.
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   final count = context.watch(counterReacton);
  ///   return Text('$count');
  /// }
  /// ```
  T watch<T>(ReactonBase<T> reacton) {
    final store = ReactonScope.of(this);
    final element = this as Element;
    final tracker = _ReactonSubscriptionTracker.of(element);
    tracker.track(reacton, store);
    return store.get(reacton);
  }

  /// Read a reacton's current value without subscribing.
  ///
  /// Does NOT rebuild when the value changes.
  /// Use this in event handlers, not in build methods.
  ///
  /// ```dart
  /// onPressed: () {
  ///   final current = context.read(counterReacton);
  ///   context.set(counterReacton, current + 1);
  /// }
  /// ```
  T read<T>(ReactonBase<T> reacton) {
    return ReactonScope.read(this).get(reacton);
  }

  /// Set a writable reacton's value.
  ///
  /// ```dart
  /// context.set(counterReacton, 42);
  /// ```
  void set<T>(WritableReacton<T> reacton, T value) {
    ReactonScope.read(this).set(reacton, value);
  }

  /// Update a writable reacton using a function.
  ///
  /// ```dart
  /// context.update(counterReacton, (count) => count + 1);
  /// ```
  void update<T>(WritableReacton<T> reacton, T Function(T current) updater) {
    ReactonScope.read(this).update(reacton, updater);
  }

  /// Access the ReactonStore directly.
  ReactonStore get reactonStore => ReactonScope.read(this);
}
