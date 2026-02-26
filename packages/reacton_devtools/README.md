# reacton_devtools

Flutter DevTools extension for the Reacton state management library. Provides reactive graph visualization, reacton inspector, timeline view, and performance metrics.

## Installation

```yaml
dependencies:
  reacton_devtools: ^0.1.0
```

## Setup

Install the DevTools extension by calling `ReactonDevToolsExtension.install()` with your store, typically in `main()`:

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

## Tabs

### Graph View

Visualizes the reactive dependency graph as an interactive DAG. Nodes represent reactons and edges represent dependencies. Color-coded by type:

- **Blue** -- Writable reactons
- **Green** -- Computed reactons
- **Orange** -- Async reactons
- **Red** -- Effects

Click a node to inspect its value, subscribers, and dependency chain.

### Reacton Inspector

Browse all reactons in the store with their current values. Features:

- Search and filter reactons by name or type
- View current value and type information
- Edit writable reacton values in real-time
- See subscriber count and dependency depth

### Timeline

A chronological log of all state changes. Shows:

- Which reacton changed and its old/new value
- Timestamp and propagation duration
- Which computed reactons were recomputed as a result
- Effect executions triggered by the change

### Performance

Aggregated performance metrics for the reactive graph:

- Total reacton count and node count
- Recomputation frequency per computed reacton
- Propagation time histograms
- Identifies hot paths and potential bottlenecks

## Service Extensions

The extension registers the following Dart service extensions for communication with DevTools:

| Extension | Description |
|-----------|-------------|
| `ext.reacton.getGraph` | Get the full dependency graph (nodes + edges) |
| `ext.reacton.getReactonList` | List all reactons with current values |
| `ext.reacton.getReactonValue` | Get a specific reacton's value by ref ID |
| `ext.reacton.setReactonValue` | Set a writable reacton's value by ref ID |
| `ext.reacton.getStats` | Get store statistics (reacton count, node count, timeline entries) |
| `ext.reacton.getTimeline` | Get state change timeline entries (supports incremental `since` param) |
| `ext.reacton.clearTimeline` | Clear timeline buffer (optionally pause/resume capture) |
| `ext.reacton.getPerformance` | Get per-reacton performance metrics (recompute counts, avg propagation) |

## Documentation

See the [Reacton documentation](https://github.com/sitharaj/reacton) for full API reference and guides.

## License

MIT
