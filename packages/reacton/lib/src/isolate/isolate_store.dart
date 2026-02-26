import 'dart:async';
import 'dart:isolate';

import '../core/reacton_base.dart';
import '../store/store.dart';
import '../utils/disposable.dart';
import 'isolate_protocol.dart';

/// Enables sharing reactive state across Dart isolates.
///
/// Changes to shared reactons propagate bidirectionally between the
/// main isolate and worker isolates via message passing.
///
/// ```dart
/// final isolateStore = await IsolateStore.spawn(
///   store,
///   sharedReactons: [configReacton, resultReacton],
///   entryPoint: (workerStore) {
///     // Runs in worker isolate
///     workerStore.subscribe(configReacton, (config) {
///       final result = heavyComputation(config);
///       workerStore.set(resultReacton, result);
///     });
///   },
/// );
/// ```
class IsolateStore with Disposable {
  final List<Unsubscribe> _subscriptions = [];
  Isolate? _isolate;
  SendPort? _workerPort;
  ReceivePort? _mainReceive;

  IsolateStore._();

  /// Spawn a worker isolate with shared reactons.
  ///
  /// [mainStore] is the main isolate's store.
  /// [sharedReactons] are the reactons to share between isolates.
  /// [entryPoint] is the function to run in the worker isolate.
  static Future<IsolateStore> spawn(
    ReactonStore mainStore, {
    required List<ReactonBase> sharedReactons,
    required void Function(ReactonStore workerStore) entryPoint,
  }) async {
    final store = IsolateStore._();

    // Create communication channel
    final mainReceive = ReceivePort();
    store._mainReceive = mainReceive;

    // Serialize initial values
    final initialValues = <int, Object?>{};
    for (final reacton in sharedReactons) {
      initialValues[reacton.ref.id] = mainStore.getByRef(reacton.ref);
    }

    // Spawn the isolate
    store._isolate = await Isolate.spawn(
      _workerEntryPoint,
      _WorkerInit(
        mainPort: mainReceive.sendPort,
        initialValues: initialValues,
        entryPoint: entryPoint,
      ),
    );

    // Wait for handshake
    final completer = Completer<SendPort>();
    mainReceive.listen((message) {
      if (message is HandshakeAck) {
        store._workerPort = message.workerPort;
        completer.complete(message.workerPort);
      } else if (message is ReactonValueChanged) {
        // Update from worker -> main
        mainStore.setByRefId(message.reactonRefId, message.serializedValue);
      }
    });

    await completer.future;

    // Forward main -> worker changes
    for (final reacton in sharedReactons) {
      final unsub = mainStore.subscribe(reacton, (value) {
        store._workerPort?.send(ReactonValueChanged(reacton.ref.id, value));
      });
      store._subscriptions.add(unsub);
    }

    return store;
  }

  static void _workerEntryPoint(_WorkerInit init) {
    final workerReceive = ReceivePort();
    final workerStore = ReactonStore();

    // Initialize shared reacton values
    for (final MapEntry(:key, :value) in init.initialValues.entries) {
      workerStore.setByRefId(key, value);
    }

    // Send handshake acknowledgment
    init.mainPort.send(HandshakeAck(workerReceive.sendPort));

    // Listen for updates from main
    workerReceive.listen((message) {
      if (message is ReactonValueChanged) {
        workerStore.setByRefId(message.reactonRefId, message.serializedValue);
      }
    });

    // Run the user's entry point
    init.entryPoint(workerStore);
  }

  @override
  void dispose() {
    for (final unsub in _subscriptions) {
      unsub();
    }
    _subscriptions.clear();
    _mainReceive?.close();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    super.dispose();
  }
}

class _WorkerInit {
  final SendPort mainPort;
  final Map<int, Object?> initialValues;
  final void Function(ReactonStore) entryPoint;

  _WorkerInit({
    required this.mainPort,
    required this.initialValues,
    required this.entryPoint,
  });
}
