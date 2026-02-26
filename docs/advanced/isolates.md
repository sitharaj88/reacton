# Multi-Isolate

Reacton supports sharing reactive state across Dart isolates via `IsolateStore`. This enables offloading heavy computation to background isolates while keeping the UI in sync with results -- all through the familiar reacton API.

## Why Isolates?

Dart is single-threaded. Long-running computations (image processing, JSON parsing, crypto, ML inference) block the UI thread and cause jank. Dart isolates run on separate threads with their own memory, but communicating between them traditionally requires manual `SendPort`/`ReceivePort` plumbing.

`IsolateStore` abstracts this away: you declare which reactons are shared, and changes propagate bidirectionally via message passing.

## IsolateStore.spawn()

Spawn a worker isolate with shared reactons:

```dart
final isolateStore = await IsolateStore.spawn(
  store,
  sharedReactons: [configReacton, resultReacton],
  entryPoint: (workerStore) {
    // This function runs in the worker isolate
    workerStore.subscribe(configReacton, (config) {
      final result = heavyComputation(config);
      workerStore.set(resultReacton, result);
    });
  },
);
```

### Signature

```dart
static Future<IsolateStore> spawn(
  ReactonStore mainStore, {
  required List<ReactonBase> sharedReactons,
  required void Function(ReactonStore workerStore) entryPoint,
});
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `mainStore` | `ReactonStore` | The main isolate's store. |
| `sharedReactons` | `List<ReactonBase>` | The reactons to share between isolates. Their initial values are serialized and sent to the worker. |
| `entryPoint` | `void Function(ReactonStore)` | The function to run in the worker isolate. Receives its own `ReactonStore` pre-initialized with shared reacton values. |

### Return Value

Returns a `Future<IsolateStore>` that completes after the worker isolate has spawned and the handshake is complete.

## How It Works

```
Main Isolate                          Worker Isolate
─────────────                         ───────────────
ReactonStore ──spawn()──────────────> ReactonStore (copy)
     │                                     │
     │   ┌──── shared reactons ────┐       │
     │   │                         │       │
     ├───┤  configReacton  ────────┼──────>│  (main -> worker)
     │   │                         │       │
     │<──┤  resultReacton  <───────┼───────┤  (worker -> main)
     │   │                         │       │
     │   └─────────────────────────┘       │
     │                                     │
  UI thread                           Background thread
```

1. **Spawn**: `IsolateStore.spawn()` creates a new Dart isolate and sends the initial values of all shared reactons.
2. **Handshake**: The worker isolate creates its own `ReactonStore`, initializes shared reacton values, and sends back a `SendPort` for bidirectional communication.
3. **Main-to-Worker**: When a shared reacton changes in the main store, the new value is sent to the worker via `ReactonValueChanged` message.
4. **Worker-to-Main**: When the worker sets a shared reacton, the change is sent back to the main store.

## IsolateProtocol Messages

Communication between isolates uses a sealed `IsolateMessage` class hierarchy:

| Message | Direction | Description |
|---------|-----------|-------------|
| `HandshakeInit` | Main -> Worker | Initial setup with `SendPort` and initial values. |
| `HandshakeAck` | Worker -> Main | Worker confirms readiness with its `SendPort`. |
| `ReactonValueChanged` | Bidirectional | A reacton value has changed. Contains `reactonRefId` and `serializedValue`. |
| `ReactonSubscribe` | Either | Request to subscribe to a reacton's changes. |
| `ReactonUnsubscribe` | Either | Request to unsubscribe from a reacton's changes. |

::: warning
Shared reacton values must be types that can be sent across isolate boundaries. This means they must be primitive types, lists, maps, or types that implement `SendPort`-compatible serialization. Custom objects with closures or non-serializable fields will fail.
:::

## Disposing

Call `dispose()` to shut down the worker isolate and clean up resources:

```dart
isolateStore.dispose();
```

This:
1. Unsubscribes all shared reacton listeners.
2. Closes the communication ports.
3. Kills the worker isolate.

## Example: Image Processing

```dart
// Shared reactons
final imagePathReacton = reacton<String>('', name: 'imagePath');
final processedImageReacton = reacton<Uint8List?>(null, name: 'processedImage');
final processingStatusReacton = reacton<String>('idle', name: 'processingStatus');

// Spawn worker
final imageWorker = await IsolateStore.spawn(
  store,
  sharedReactons: [imagePathReacton, processedImageReacton, processingStatusReacton],
  entryPoint: (workerStore) {
    workerStore.subscribe(imagePathReacton, (path) {
      if (path.isEmpty) return;

      workerStore.set(processingStatusReacton, 'processing');

      try {
        // Heavy computation runs on the worker thread
        final bytes = File(path).readAsBytesSync();
        final processed = applyFilters(bytes); // CPU-intensive
        workerStore.set(processedImageReacton, processed);
        workerStore.set(processingStatusReacton, 'done');
      } catch (e) {
        workerStore.set(processingStatusReacton, 'error: $e');
      }
    });
  },
);

// In the UI -- just watch the reactons as normal
class ImageEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = context.watch(processingStatusReacton);
    final processed = context.watch(processedImageReacton);

    return Column(
      children: [
        if (status == 'processing')
          LinearProgressIndicator(),
        if (processed != null)
          Image.memory(processed),
        ElevatedButton(
          onPressed: () => context.set(imagePathReacton, '/path/to/image.jpg'),
          child: Text('Process Image'),
        ),
      ],
    );
  }
}
```

## Example: Background Data Processing

```dart
// Shared state
final rawDataReacton = reacton<List<Map<String, dynamic>>>([], name: 'rawData');
final analysisResultReacton = reacton<AnalysisResult?>(null, name: 'analysisResult');

// Spawn analysis worker
final analysisWorker = await IsolateStore.spawn(
  store,
  sharedReactons: [rawDataReacton, analysisResultReacton],
  entryPoint: (workerStore) {
    workerStore.subscribe(rawDataReacton, (data) {
      if (data.isEmpty) return;

      // Run expensive analysis on background thread
      final result = AnalysisResult(
        mean: calculateMean(data),
        median: calculateMedian(data),
        outliers: detectOutliers(data),
        trends: analyzeTrends(data),
      );

      workerStore.set(analysisResultReacton, result);
    });
  },
);

// Feed data from the main isolate
store.set(rawDataReacton, fetchedData);

// Results appear automatically via bidirectional sync
store.subscribe(analysisResultReacton, (result) {
  if (result != null) {
    print('Analysis complete: ${result.trends}');
  }
});
```

## Best Practices

::: tip
Keep the number of shared reactons small. Each shared reacton adds a message listener in both directions. Share only the inputs and outputs, not intermediate state.
:::

::: tip
For one-off computations, consider using `Isolate.run()` directly. `IsolateStore` is best when you need ongoing bidirectional state synchronization.
:::

::: danger
Do not share the same `ReactonStore` instance across isolates. Each isolate must have its own store. `IsolateStore.spawn()` handles this automatically by creating a new store in the worker.
:::

## What's Next

- [Observable Collections](/advanced/collections) -- Reactive lists and maps with granular change events
- [Modules](/advanced/modules) -- Organize reactons into feature modules
- [Persistence](/advanced/persistence) -- Auto-persist state to storage backends
