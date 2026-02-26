# DevTools

The `reacton_devtools` package provides a Flutter DevTools extension for visualizing the reactive graph, inspecting reacton values, viewing state change timelines, and monitoring performance.

## Installation

Add the package to your dependencies:

```yaml
dependencies:
  reacton_devtools: ^0.1.0
```

## Setup

Call `ReactonDevToolsExtension.install()` with your store in `main()`:

```dart
import 'package:flutter_reacton/flutter_reacton.dart';
import 'package:reacton_devtools/reacton_devtools.dart';

void main() {
  final store = ReactonStore();
  ReactonDevToolsExtension.install(store);

  runApp(ReactonScope(store: store, child: MyApp()));
}
```

Once installed, open Flutter DevTools and navigate to the **Reacton** tab.

::: warning
Only install DevTools in debug builds. Wrap the install call in a `kDebugMode` check for production builds:
```dart
if (kDebugMode) {
  ReactonDevToolsExtension.install(store);
}
```
:::

## Tabs

### Graph View

Visualizes the reactive dependency graph as an interactive DAG (directed acyclic graph). Nodes represent reactons and edges represent dependencies.

**Color coding by type:**

| Color | Type |
|-------|------|
| Blue | Writable reactons |
| Green | Computed reactons |
| Orange | Async reactons |
| Red | Effects |

**Interactions:**

- Click a node to inspect its value, subscribers, and dependency chain
- View the full dependency tree for any reacton
- See subscriber count and level in the graph hierarchy

### Reacton Inspector

Browse all reactons in the store with their current values.

**Features:**

- Search and filter reactons by name or type
- View current value and runtime type information
- Edit writable reacton values in real-time (for debugging)
- See subscriber count and dependency depth
- View reacton state (clean, dirty, computing)

### Timeline

A chronological log of all state changes, limited to the most recent 500 entries (ring buffer).

**For each change, the timeline shows:**

- Which reacton changed and its old/new value
- Timestamp and propagation duration (in microseconds)
- Which computed reactons were recomputed as a result
- Effect executions triggered by the change
- Whether the timeline is paused or capturing

**Controls:**

- Pause/resume timeline capture
- Clear the timeline buffer
- Fetch entries incrementally (using the `since` parameter)

### Performance

Aggregated performance metrics for the reactive graph.

**Metrics per reacton:**

- Recomputation count (how many times the value has been recomputed)
- Average propagation time (microseconds)
- Subscriber count
- Node type classification

**Store-level metrics:**

- Total reacton count
- Total graph node count
- Timeline entry count
- Number of tracked reactons

## Service Extensions

The extension registers Dart service extensions for communication between the running app and the DevTools panel. These can also be called programmatically for custom tooling.

| Extension | Parameters | Description |
|-----------|------------|-------------|
| `ext.reacton.getGraph` | -- | Returns the full dependency graph (nodes and edges) with IDs, names, types, states, epochs, levels, and subscriber counts |
| `ext.reacton.getReactonList` | -- | Lists all reactons with their ID, name, current value, type, and subscriber count |
| `ext.reacton.getReactonValue` | `refId` | Gets a specific reacton's value and runtime type by ref ID |
| `ext.reacton.setReactonValue` | `refId`, `value` | Sets a writable reacton's value by ref ID (for live editing) |
| `ext.reacton.getStats` | -- | Returns store statistics: reacton count, node count, timeline entry count, tracked reacton count |
| `ext.reacton.getTimeline` | `since?` | Gets timeline entries, optionally only those after a given index (for incremental fetching) |
| `ext.reacton.clearTimeline` | `pause?` | Clears the timeline buffer; optionally pause or resume capture |
| `ext.reacton.getPerformance` | -- | Returns per-reacton performance data: recompute count, avg propagation time, subscriber count |

### Graph Response Format

```json
{
  "nodes": [
    {
      "id": 0,
      "name": "counter",
      "type": "writable",
      "state": "clean",
      "epoch": 3,
      "level": 0,
      "subscriberCount": 2
    }
  ],
  "edges": [
    { "from": 0, "to": 1 }
  ]
}
```

### Timeline Entry Format

```json
{
  "entries": [
    {
      "refId": 0,
      "name": "counter",
      "type": "writable",
      "oldValue": "0",
      "newValue": "1",
      "timestamp": "2026-02-26T10:30:00.000Z",
      "propagationMicros": 42
    }
  ],
  "total": 1,
  "paused": false
}
```

### Performance Response Format

```json
{
  "reactons": [
    {
      "refId": 1,
      "name": "doubleCount",
      "type": "computed",
      "recomputeCount": 5,
      "avgPropagationMicros": 12,
      "subscriberCount": 1
    }
  ]
}
```

## Architecture

The `ReactonDevToolsExtension` class:

1. Hooks into the store's value change notifications via `store.setDevToolsListener()`
2. Maintains a ring buffer of timeline events (max 500)
3. Tracks per-reacton performance metrics (recompute count, propagation time)
4. Registers Dart service extensions that DevTools queries over the VM service protocol

All tracking is lightweight and designed for debug builds. The ring buffer prevents unbounded memory growth, and timeline capture can be paused when not needed.

## What's Next

- [VS Code Extension](./vscode-extension) -- IDE-level code intelligence and graph visualization
- [CLI](./cli) -- Static graph analysis from the command line
- [Lint Rules](./lint-rules) -- Catch anti-patterns at analysis time
