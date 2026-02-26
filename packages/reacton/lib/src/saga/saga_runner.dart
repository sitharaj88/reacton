import 'dart:async';

import '../store/store.dart';
import 'saga.dart';

// ---------------------------------------------------------------------------
// Per-store saga runtime state
// ---------------------------------------------------------------------------

/// Internal bookkeeping for all sagas running against a single
/// [ReactonStore].
///
/// Stored via an [Expando] so that saga state is associated with the store
/// without modifying the [ReactonStore] class itself, following the same
/// pattern used by `ReactonStoreModules`.
class _SagaRuntime {
  /// Event bus shared by all sagas on this store.
  ///
  /// Events dispatched via [ReactonStoreSaga.dispatch] are broadcast here.
  /// Individual saga contexts subscribe to the stream to implement `take`.
  final StreamController<dynamic> eventBus =
      StreamController<dynamic>.broadcast(sync: true);

  /// Root tasks keyed by the saga's identity (hashCode is sufficient since
  /// each [Saga] object is long-lived and unique).
  final Map<int, _SagaEntry> entries = {};

  /// Dispose all sagas and close the event bus.
  void dispose() {
    for (final entry in entries.values) {
      entry.dispose();
    }
    entries.clear();
    eventBus.close();
  }
}

/// Tracks a single saga's root task, its per-registration handler state,
/// and the subscriptions that feed events to handlers.
class _SagaEntry {
  /// The root task for this saga instance.
  final SagaTask rootTask;

  /// Stream subscription that listens for events and dispatches to handlers.
  final StreamSubscription<dynamic> subscription;

  /// Per-registration state for concurrency management.
  final List<_HandlerSlot> slots;

  _SagaEntry({
    required this.rootTask,
    required this.subscription,
    required this.slots,
  });

  /// Cancel everything associated with this entry.
  void dispose() {
    rootTask.cancel();
    subscription.cancel();
    for (final slot in slots) {
      slot.dispose();
    }
  }
}

/// Manages concurrency state for a single [SagaRegistration].
///
/// Depending on the [HandlerStrategy], a slot may track the currently
/// running task (for takeLatest / takeLeading) or simply fire-and-forget
/// (for takeEvery).
class _HandlerSlot {
  /// The registration this slot corresponds to.
  final SagaRegistration<dynamic> registration;

  /// Whether this handler has been consumed (for takeOnce).
  bool consumed = false;

  /// The currently running handler task (used by takeLatest and takeLeading).
  SagaTask? _activeTask;

  /// All forked handler tasks (for cleanup on dispose).
  final List<SagaTask> _allTasks = [];

  _HandlerSlot(this.registration);

  /// Whether a handler invocation is currently in flight.
  bool get isActive => _activeTask != null && _activeTask!.isRunning;

  /// Record a new handler invocation task.
  void activate(SagaTask task) {
    _activeTask = task;
    _allTasks.add(task);
  }

  /// Cancel all tasks managed by this slot.
  void dispose() {
    for (final task in _allTasks) {
      task.cancel();
    }
    _allTasks.clear();
    _activeTask = null;
  }
}

// ---------------------------------------------------------------------------
// Expando-based runtime storage
// ---------------------------------------------------------------------------

/// Associates a [_SagaRuntime] with each [ReactonStore] that uses sagas.
final Expando<_SagaRuntime> _runtimes = Expando<_SagaRuntime>('sagaRuntime');

/// Get or create the saga runtime for [store].
_SagaRuntime _getRuntime(ReactonStore store) {
  var runtime = _runtimes[store];
  if (runtime == null) {
    runtime = _SagaRuntime();
    _runtimes[store] = runtime;
  }
  return runtime;
}

// ---------------------------------------------------------------------------
// ReactonStoreSaga extension
// ---------------------------------------------------------------------------

/// Extends [ReactonStore] with saga (effect orchestrator) capabilities.
///
/// Sagas are long-running async workflows that react to dispatched events,
/// read and write store state, and orchestrate complex side effects with
/// built-in cancellation, concurrency control, and parent-child task
/// hierarchies.
///
/// ```dart
/// final store = ReactonStore();
///
/// // Start the saga
/// final task = store.runSaga(authSaga);
///
/// // Dispatch events
/// store.dispatch(authSaga, LoginRequested(username: 'admin', password: 's3cret'));
///
/// // Later: tear down
/// store.cancelSaga(authSaga);
/// ```
extension ReactonStoreSaga on ReactonStore {
  /// Start a [Saga] and begin listening for events.
  ///
  /// Returns the root [SagaTask] representing the saga's lifetime.
  /// The saga remains active until explicitly cancelled via [cancelSaga]
  /// or [cancelAllSagas].
  ///
  /// Throws [StateError] if this saga is already running on this store.
  SagaTask runSaga<E>(Saga<E> saga) {
    final runtime = _getRuntime(this);
    final key = saga.hashCode;

    if (runtime.entries.containsKey(key)) {
      throw StateError(
        'Saga "${saga.name}" is already running on this store. '
        'Cancel it first with cancelSaga().',
      );
    }

    final rootTask = SagaTask(name: saga.name);
    final registrations = saga.registrations;

    // Create a handler slot for each registration.
    final slots = registrations
        .map((r) => _HandlerSlot(r))
        .toList(growable: false);

    // Subscribe to the event bus and route events to matching handlers.
    final subscription = runtime.eventBus.stream.listen((event) {
      if (rootTask.isCancelled) return;

      for (final slot in slots) {
        if (slot.consumed) continue;
        if (event.runtimeType != slot.registration.eventType) continue;

        _invokeHandler(
          store: this,
          runtime: runtime,
          rootTask: rootTask,
          slot: slot,
          event: event as E,
        );
      }
    });

    runtime.entries[key] = _SagaEntry(
      rootTask: rootTask,
      subscription: subscription,
      slots: slots,
    );

    return rootTask;
  }

  /// Dispatch an event [event] to a running [Saga].
  ///
  /// The event is broadcast to the saga's event bus. All registered
  /// handlers whose event type matches will be considered (subject to
  /// their concurrency strategy).
  ///
  /// Throws [StateError] if the saga is not running on this store.
  void dispatch<E>(Saga<E> saga, E event) {
    final runtime = _getRuntime(this);
    final key = saga.hashCode;

    if (!runtime.entries.containsKey(key)) {
      throw StateError(
        'Saga "${saga.name}" is not running on this store. '
        'Start it first with runSaga().',
      );
    }

    runtime.eventBus.add(event);
  }

  /// Cancel a running [Saga] and clean up all its resources.
  ///
  /// The root task and all child tasks are cancelled. Stream subscriptions
  /// are disposed. It is safe to call this even if the saga has already
  /// been cancelled.
  void cancelSaga<E>(Saga<E> saga) {
    final runtime = _getRuntime(this);
    final key = saga.hashCode;
    final entry = runtime.entries.remove(key);
    entry?.dispose();
  }

  /// Cancel **all** running sagas on this store and dispose the runtime.
  ///
  /// This is typically called during store teardown.
  void cancelAllSagas() {
    final runtime = _runtimes[this];
    if (runtime != null) {
      runtime.dispose();
      _runtimes[this] = null;
    }
  }
}

// ---------------------------------------------------------------------------
// Internal handler invocation logic
// ---------------------------------------------------------------------------

/// Invoke a handler according to its concurrency strategy.
void _invokeHandler<E>({
  required ReactonStore store,
  required _SagaRuntime runtime,
  required SagaTask rootTask,
  required _HandlerSlot slot,
  required E event,
}) {
  switch (slot.registration.strategy) {
    case HandlerStrategy.takeOnce:
      // Run once, then mark consumed so no further events match.
      slot.consumed = true;
      _spawnHandler(
        store: store,
        runtime: runtime,
        rootTask: rootTask,
        slot: slot,
        handler: slot.registration.handler,
        event: event,
      );

    case HandlerStrategy.takeEvery:
      // Fire-and-forget: spawn a new handler for every event.
      _spawnHandler(
        store: store,
        runtime: runtime,
        rootTask: rootTask,
        slot: slot,
        handler: slot.registration.handler,
        event: event,
      );

    case HandlerStrategy.takeLatest:
      // Cancel the previous handler (if running), then spawn a new one.
      slot._activeTask?.cancel();
      _spawnHandler(
        store: store,
        runtime: runtime,
        rootTask: rootTask,
        slot: slot,
        handler: slot.registration.handler,
        event: event,
      );

    case HandlerStrategy.takeLeading:
      // Ignore the event if a handler is already running.
      if (slot.isActive) return;
      _spawnHandler(
        store: store,
        runtime: runtime,
        rootTask: rootTask,
        slot: slot,
        handler: slot.registration.handler,
        event: event,
      );
  }
}

/// Spawn a handler invocation as a child task of [rootTask].
void _spawnHandler<E>({
  required ReactonStore store,
  required _SagaRuntime runtime,
  required SagaTask rootTask,
  required _HandlerSlot slot,
  required Future<void> Function(SagaContext ctx, dynamic event) handler,
  required E event,
}) {
  final childTask = SagaTask(
    name: '${rootTask.name ?? 'saga'}:handler(${slot.registration.eventType})',
  );
  rootTask.addChild(childTask);
  slot.activate(childTask);

  final context = SagaContext(
    store: store,
    task: childTask,
    eventBus: runtime.eventBus,
  );

  // Run the handler asynchronously.
  _executeHandler(context, handler, event, childTask);
}

/// Execute a handler function, catching cancellation and errors.
Future<void> _executeHandler(
  SagaContext context,
  Future<void> Function(SagaContext ctx, dynamic event) handler,
  dynamic event,
  SagaTask task,
) async {
  try {
    await handler(context, event);
    task.complete();
  } on SagaCancelledException {
    // Expected during cancellation flow.
    task.cancel();
  } catch (error, stackTrace) {
    task.completeError(error, stackTrace);
  }
}
