import 'dart:async';
import 'package:reacton/reacton.dart';

/// Manages automatic disposal of reactons when they have no active watchers.
///
/// When the last widget watching a reacton is unmounted, a grace period
/// timer starts. If no new watchers appear before it expires, the reacton
/// is removed from the store.
class AutoDisposeManager {
  final ReactonStore _store;
  final Map<ReactonRef, int> _watcherCounts = {};
  final Map<ReactonRef, Timer?> _disposalTimers = {};
  final Duration _gracePeriod;

  AutoDisposeManager(
    this._store, {
    Duration gracePeriod = const Duration(seconds: 5),
  }) : _gracePeriod = gracePeriod;

  /// Notify that a watcher started watching a reacton.
  void onWatch(ReactonRef ref) {
    _watcherCounts[ref] = (_watcherCounts[ref] ?? 0) + 1;
    // Cancel any pending disposal
    _disposalTimers[ref]?.cancel();
    _disposalTimers[ref] = null;
  }

  /// Notify that a watcher stopped watching a reacton.
  void onUnwatch(ReactonRef ref) {
    final count = (_watcherCounts[ref] ?? 1) - 1;
    _watcherCounts[ref] = count;

    if (count <= 0) {
      // Start grace period timer
      _disposalTimers[ref] = Timer(_gracePeriod, () {
        // Check again in case a new watcher appeared
        if ((_watcherCounts[ref] ?? 0) <= 0) {
          _store.remove(ref);
          _watcherCounts.remove(ref);
          _disposalTimers.remove(ref);
        }
      });
    }
  }

  /// Get the current watcher count for a reacton.
  int watcherCount(ReactonRef ref) => _watcherCounts[ref] ?? 0;

  /// Cancel all pending disposals.
  void cancelAll() {
    for (final timer in _disposalTimers.values) {
      timer?.cancel();
    }
    _disposalTimers.clear();
  }

  /// Dispose the manager.
  void dispose() {
    cancelAll();
    _watcherCounts.clear();
  }
}
