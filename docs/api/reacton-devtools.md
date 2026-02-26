# reacton_devtools API Reference

The `reacton_devtools` package provides a DevTools extension for inspecting Reacton state at runtime. It registers Dart service extensions that expose the reactive dependency graph, state values, a timeline of changes, and performance metrics.

## Installation

```yaml
# pubspec.yaml
dependencies:
  reacton_devtools: ^0.1.0
```

## Quick Setup

```dart
import 'package:reacton/reacton.dart';
import 'package:reacton_devtools/reacton_devtools.dart';

void main() {
  final store = ReactonStore();

  // Enable DevTools integration (debug builds only)
  assert(() {
    ReactonDevToolsExtension.install(store);
    return true;
  }());

  runApp(ReactonScope(store: store, child: MyApp()));
}
```

::: tip
Wrap the `install` call in an `assert` block so it is stripped from release builds. The service extensions have minimal overhead but are unnecessary in production.
:::

---

## ReactonDevToolsExtension

The main class that registers Dart VM service extensions for DevTools communication.

### Static Methods

#### `install(ReactonStore store)`

Register all DevTools service extensions for the given store. This is the only method you need to call.

```dart
static void install(ReactonStore store)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `store` | `ReactonStore` | The reactive store to inspect |

**Behavior:**
- Creates a `ReactonDevToolsExtension` instance and registers service extensions.
- Hooks into the store's value change notifications to capture timeline events and performance data.
- Calling `install` more than once on the same instance is a no-op (guarded by an internal `_installed` flag).

```dart
final store = ReactonStore();
ReactonDevToolsExtension.install(store);
```

### Service Extensions

The following Dart VM service extensions are registered and can be called by the DevTools UI or any service extension client.

---

#### `ext.reacton.getGraph`

Returns the full reactive dependency graph as a JSON object with nodes and edges.

**Parameters:** None

**Response:**

```json
{
  "nodes": [
    {
      "id": 1,
      "name": "counter",
      "type": "writable",
      "state": "clean",
      "epoch": 5,
      "level": 0,
      "subscriberCount": 2
    },
    {
      "id": 2,
      "name": "doubleCount",
      "type": "computed",
      "state": "clean",
      "epoch": 5,
      "level": 1,
      "subscriberCount": 1
    }
  ],
  "edges": [
    {
      "from": 1,
      "to": 2
    }
  ]
}
```

**Node fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Unique reacton ref ID |
| `name` | `String` | Reacton name (from the `name` parameter) |
| `type` | `String` | One of: `writable`, `computed`, `effect`, `unknown` |
| `state` | `String` | Current graph node state (e.g., `clean`, `dirty`, `computing`) |
| `epoch` | `int` | Number of times the value has been updated |
| `level` | `int` | Topological level in the dependency graph (0 = root) |
| `subscriberCount` | `int` | Number of active widget subscribers |

**Edge fields:**

| Field | Type | Description |
|-------|------|-------------|
| `from` | `int` | Source node ref ID (the dependency) |
| `to` | `int` | Target node ref ID (the dependent) |

---

#### `ext.reacton.getReactonValue`

Get the current value of a specific reacton by its ref ID.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `refId` | `String` | Yes | The integer ref ID as a string |

**Response:**

```json
{
  "refId": 1,
  "value": "42",
  "type": "int"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `refId` | `int` | The requested ref ID |
| `value` | `String` | String representation of the current value (truncated to 200 chars) |
| `type` | `String` | Runtime type name of the value |

**Error:** Returns an extension error if `refId` is missing or no reacton matches.

---

#### `ext.reacton.setReactonValue`

Set a new value on a writable reacton. Used by the DevTools inspector for live editing.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `refId` | `String` | Yes | The integer ref ID as a string |
| `value` | `String` | Yes | The new value as a string |

**Response:**

```json
{
  "success": true
}
```

::: warning
The value is passed as a string and parsed by the store's `setByRefId` method. This works for primitive types (int, double, bool, String). Complex types may not round-trip correctly through string serialization.
:::

---

#### `ext.reacton.getReactonList`

Get a summary list of all reactons in the store.

**Parameters:** None

**Response:**

```json
{
  "reactons": [
    {
      "id": 1,
      "name": "counter",
      "value": "0",
      "type": "writable",
      "subscribers": 2
    },
    {
      "id": 2,
      "name": "doubleCount",
      "value": "0",
      "type": "computed",
      "subscribers": 1
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Reacton ref ID |
| `name` | `String` | Reacton name |
| `value` | `String` | Current value as string (truncated to 200 chars) |
| `type` | `String` | One of: `writable`, `computed`, `effect`, `unknown` |
| `subscribers` | `int` | Number of active widget subscribers |

---

#### `ext.reacton.getStats`

Get aggregate statistics about the reactive store.

**Parameters:** None

**Response:**

```json
{
  "reactonCount": 15,
  "nodeCount": 15,
  "timelineEntries": 42,
  "trackedReactons": 8
}
```

| Field | Type | Description |
|-------|------|-------------|
| `reactonCount` | `int` | Total number of reactons registered in the store |
| `nodeCount` | `int` | Total number of nodes in the dependency graph |
| `timelineEntries` | `int` | Number of entries currently in the timeline ring buffer |
| `trackedReactons` | `int` | Number of reactons with performance tracking data |

---

#### `ext.reacton.getTimeline`

Get the state change timeline. Supports incremental fetching via the `since` parameter.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `since` | `String` | No | Fetch entries after this index (default: `0`) |

**Response:**

```json
{
  "entries": [
    {
      "refId": 1,
      "name": "counter",
      "type": "writable",
      "oldValue": "0",
      "newValue": "1",
      "timestamp": "2026-02-26T12:00:00.000Z",
      "propagationMicros": 15
    }
  ],
  "total": 42,
  "paused": false
}
```

**Entry fields:**

| Field | Type | Description |
|-------|------|-------------|
| `refId` | `int` | Reacton ref ID |
| `name` | `String` | Reacton name |
| `type` | `String` | Node type: `writable`, `computed`, `effect`, `unknown` |
| `oldValue` | `String` | Previous value as string |
| `newValue` | `String` | New value as string |
| `timestamp` | `String` | ISO 8601 timestamp of the change |
| `propagationMicros` | `int` | Time in microseconds for the change to propagate |

**Top-level fields:**

| Field | Type | Description |
|-------|------|-------------|
| `entries` | `List` | Timeline entries (filtered by `since`) |
| `total` | `int` | Total number of entries in the buffer |
| `paused` | `bool` | Whether timeline capture is currently paused |

::: tip
The timeline is a ring buffer that holds up to **500 entries**. Older entries are evicted when the buffer is full. Use `since` for efficient polling.
:::

---

#### `ext.reacton.clearTimeline`

Clear the timeline buffer. Optionally pause or resume timeline capture.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pause` | `String` | No | Set to `"true"` to pause capture, `"false"` to resume |

**Response:**

```json
{
  "success": true
}
```

---

#### `ext.reacton.getPerformance`

Get per-reacton performance metrics.

**Parameters:** None

**Response:**

```json
{
  "reactons": [
    {
      "refId": 1,
      "name": "counter",
      "type": "writable",
      "recomputeCount": 12,
      "avgPropagationMicros": 8,
      "subscriberCount": 2
    },
    {
      "refId": 2,
      "name": "filteredTodos",
      "type": "computed",
      "recomputeCount": 45,
      "avgPropagationMicros": 120,
      "subscriberCount": 1
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `refId` | `int` | Reacton ref ID |
| `name` | `String` | Reacton name |
| `type` | `String` | Node type |
| `recomputeCount` | `int` | Total number of times the value has been recomputed |
| `avgPropagationMicros` | `int` | Average propagation time in microseconds |
| `subscriberCount` | `int` | Number of active widget subscribers |

---

## ReactonDevToolsService

A client-side service class for communicating with the DevTools extension from the DevTools UI. This is used internally by the DevTools panels but can also be used for custom integrations.

### Constructor

```dart
ReactonDevToolsService(
  Future<String> Function(String method, Map<String, String> params) callServiceExtension,
)
```

The constructor takes a function that calls Dart VM service extensions. In the DevTools context, this is wired to the VM service connection.

### Methods

#### `getGraph()`

```dart
Future<GraphData> getGraph()
```

Returns the full dependency graph as a `GraphData` object.

---

#### `getReactonValue(int refId)`

```dart
Future<ReactonValueData> getReactonValue(int refId)
```

Returns the current value of a specific reacton.

---

#### `getReactonList()`

```dart
Future<List<ReactonListEntry>> getReactonList()
```

Returns a list of all reactons with their current values and metadata.

---

#### `getStats()`

```dart
Future<StoreStats> getStats()
```

Returns aggregate store statistics.

---

#### `getTimeline({int since = 0})`

```dart
Future<TimelineData> getTimeline({int since = 0})
```

Returns timeline entries, optionally filtered to entries after `since`.

---

#### `clearTimeline({bool? pause})`

```dart
Future<void> clearTimeline({bool? pause})
```

Clears the timeline buffer. Pass `pause: true` to stop capturing, `pause: false` to resume.

---

#### `getPerformance()`

```dart
Future<List<PerformanceEntry>> getPerformance()
```

Returns per-reacton performance metrics.

---

## Data Classes

### GraphData

The full reactive dependency graph.

```dart
class GraphData {
  final List<GraphNodeData> nodes;
  final List<GraphEdgeData> edges;
}
```

### GraphNodeData

A single node in the dependency graph.

```dart
class GraphNodeData {
  final int id;              // Unique ref ID
  final String name;         // Reacton name
  final String type;         // "writable", "computed", "effect", "unknown"
  final String state;        // Graph node state ("clean", "dirty", etc.)
  final int epoch;           // Update counter
  final int level;           // Topological level (0 = root)
  final int subscriberCount; // Active widget subscribers

  factory GraphNodeData.fromJson(Map<String, dynamic> json);
}
```

### GraphEdgeData

A directed edge representing a dependency relationship.

```dart
class GraphEdgeData {
  final int from; // Source (dependency) ref ID
  final int to;   // Target (dependent) ref ID

  factory GraphEdgeData.fromJson(Map<String, dynamic> json);
}
```

### ReactonValueData

The current value of a single reacton.

```dart
class ReactonValueData {
  final int refId;    // Ref ID
  final String value; // String representation (truncated to 200 chars)
  final String type;  // Runtime type name

  factory ReactonValueData.fromJson(Map<String, dynamic> json);
}
```

### ReactonListEntry

Summary of a reacton for list display in the inspector.

```dart
class ReactonListEntry {
  final int id;           // Ref ID
  final String name;      // Reacton name
  final String value;     // Current value as string
  final String type;      // "writable", "computed", "effect", "unknown"
  final int subscribers;  // Active widget subscribers

  factory ReactonListEntry.fromJson(Map<String, dynamic> json);
}
```

### StoreStats

Aggregate statistics for the reactive store.

```dart
class StoreStats {
  final int reactonCount;    // Total reactons
  final int nodeCount;       // Total graph nodes
  final int timelineEntries; // Timeline buffer size
  final int trackedReactons; // Reactons with perf data

  factory StoreStats.fromJson(Map<String, dynamic> json);
}
```

### TimelineData

Timeline response with entries and metadata.

```dart
class TimelineData {
  final List<TimelineEntryData> entries; // Timeline entries
  final int total;                       // Total entries in buffer
  final bool paused;                     // Whether capture is paused

  factory TimelineData.fromJson(Map<String, dynamic> json);
}
```

### TimelineEntryData

A single state change event in the timeline.

```dart
class TimelineEntryData {
  final int refId;              // Reacton ref ID
  final String name;            // Reacton name
  final String type;            // Node type
  final String oldValue;        // Previous value
  final String newValue;        // New value
  final DateTime timestamp;     // When the change occurred
  final int propagationMicros;  // Propagation time in microseconds

  factory TimelineEntryData.fromJson(Map<String, dynamic> json);
}
```

### PerformanceEntry

Per-reacton performance metrics.

```dart
class PerformanceEntry {
  final int refId;               // Reacton ref ID
  final String name;             // Reacton name
  final String type;             // Node type
  final int recomputeCount;      // Total recomputation count
  final int avgPropagationMicros;// Average propagation time
  final int subscriberCount;     // Active subscribers

  factory PerformanceEntry.fromJson(Map<String, dynamic> json);
}
```

---

## Wire Protocol Summary

All communication between the DevTools UI and the running app happens through Dart VM service extensions. The protocol is JSON-based over the VM service connection.

| Extension Method | Direction | Purpose |
|-----------------|-----------|---------|
| `ext.reacton.getGraph` | UI -> App | Fetch dependency graph |
| `ext.reacton.getReactonValue` | UI -> App | Read a single value |
| `ext.reacton.setReactonValue` | UI -> App | Write a value (live edit) |
| `ext.reacton.getReactonList` | UI -> App | List all reactons |
| `ext.reacton.getStats` | UI -> App | Store statistics |
| `ext.reacton.getTimeline` | UI -> App | State change history |
| `ext.reacton.clearTimeline` | UI -> App | Clear history / pause capture |
| `ext.reacton.getPerformance` | UI -> App | Per-reacton performance data |

All responses are JSON strings returned via `ServiceExtensionResponse.result()`. Errors are returned via `ServiceExtensionResponse.error()` with the `extensionError` code.

### Custom Integration Example

```dart
import 'package:reacton_devtools/src/services/reacton_service.dart';
import 'package:vm_service/vm_service.dart';

// Create a service backed by a real VM service connection
final service = ReactonDevToolsService((method, params) async {
  final response = await vmService.callServiceExtension(
    method,
    isolateId: isolateId,
    args: params,
  );
  return response.json!;
});

// Fetch and display the graph
final graph = await service.getGraph();
for (final node in graph.nodes) {
  print('${node.name} (${node.type}) - ${node.subscriberCount} subscribers');
}

// Monitor the timeline
final timeline = await service.getTimeline(since: lastIndex);
for (final entry in timeline.entries) {
  print('[${entry.timestamp}] ${entry.name}: ${entry.oldValue} -> ${entry.newValue}');
}
```
