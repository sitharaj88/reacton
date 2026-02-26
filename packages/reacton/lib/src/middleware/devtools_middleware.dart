import 'dart:developer' as developer;

import '../core/reacton_base.dart';
import 'middleware.dart';

/// Middleware that reports state changes to DevTools.
///
/// Emits timeline events and logs that the DevTools extension
/// can consume for the timeline view.
class DevToolsMiddleware<T> extends Middleware<T> {
  @override
  T onBeforeWrite(ReactonBase<T> reacton, T currentValue, T newValue) {
    developer.Timeline.startSync(
      'Reacton: ${reacton.ref}',
      arguments: {
        'reacton': reacton.ref.toString(),
        'oldValue': currentValue.toString(),
        'newValue': newValue.toString(),
      },
    );
    return newValue;
  }

  @override
  void onAfterWrite(ReactonBase<T> reacton, T value) {
    developer.Timeline.finishSync();

    // Also post as an event for the DevTools service extension
    developer.postEvent('reacton.stateChange', {
      'reacton': reacton.ref.toString(),
      'reactonId': reacton.ref.id,
      'value': value.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void onError(ReactonBase<T> reacton, Object error, StackTrace stackTrace) {
    developer.postEvent('reacton.error', {
      'reacton': reacton.ref.toString(),
      'reactonId': reacton.ref.id,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    });
  }
}
