# Debugging

Debugging reactive state can be challenging because changes propagate automatically through a graph of dependencies. Reacton provides multiple tools and techniques to make this process transparent and systematic.

## LoggingMiddleware

The simplest debugging tool is the built-in `LoggingMiddleware`. It logs every lifecycle event for a reacton: initialization, writes (before and after), disposal, and errors.

### Per-Reacton Setup

```dart
final counterReacton = reacton(
  0,
  name: 'counter',
  options: ReactonOptions<int>(
    middleware: [LoggingMiddleware<int>('counter')],
  ),
);
```

### Global Setup

Apply logging to all reactons via the store's global middleware:

```dart
final store = ReactonStore(
  globalMiddleware: [LoggingMiddleware<dynamic>('global')],
);
```

### Output Format

When you set `counterReacton` to `5`, the log output looks like:

```
[counter] Writing: 0 -> 5
[counter] Written: 5
```

### Custom Logger

By default, `LoggingMiddleware` uses a configurable logger function. You can redirect output to your logging framework:

```dart
final middleware = LoggingMiddleware<int>(
  'counter',
  logger: (message) => logger.debug(message), // Your logger
);
```

### Conditional Logging

For production, you can wrap middleware in a conditional:

```dart
final store = ReactonStore(
  globalMiddleware: [
    if (kDebugMode) LoggingMiddleware<dynamic>('debug'),
  ],
);
```

## ActionLog for Mutation Auditing

`ActionLog` provides a complete audit trail of every state mutation in your application. Unlike `LoggingMiddleware` which logs to the console in real time, `ActionLog` stores structured records that you can query programmatically.

### Setup

```dart
final actionLog = ActionLog(maxRecords: 1000);

// Create middleware that feeds into the action log
class AuditMiddleware<T> extends Middleware<T> {
  final ActionLog log;
  AuditMiddleware(this.log);

  @override
  void onAfterWrite(ReactonBase<T> reacton, T value) {
    log.record(ActionRecord(
      reactonRef: reacton.ref,
      oldValue: null, // You could track this with onBeforeWrite
      newValue: value,
      timestamp: DateTime.now(),
      stackTrace: StackTrace.current, // Capture call site
    ));
  }
}

final store = ReactonStore(
  globalMiddleware: [AuditMiddleware<dynamic>(actionLog)],
);
```

### Querying the Log

```dart
// Get all mutations for a specific reacton
final counterHistory = actionLog.forReacton(counterReacton.ref);
for (final record in counterHistory) {
  print('${record.timestamp}: ${record.oldValue} -> ${record.newValue}');
}

// Get mutations in a time range
final recentActions = actionLog.inRange(
  DateTime.now().subtract(Duration(minutes: 5)),
  DateTime.now(),
);
print('${recentActions.length} mutations in the last 5 minutes');

// Check total mutations
print('Total recorded mutations: ${actionLog.length}');
```

### ActionRecord Fields

| Field | Type | Description |
|---|---|---|
| `reactonRef` | `ReactonRef` | Which reacton was mutated |
| `oldValue` | `dynamic` | Value before the mutation |
| `newValue` | `dynamic` | Value after the mutation |
| `timestamp` | `DateTime` | When the mutation occurred |
| `stackTrace` | `StackTrace?` | Call site (for tracking who caused the mutation) |

The stack trace is particularly valuable for debugging "who set this value?" questions. Inspect it to find the exact line of code that triggered the mutation.

## DevTools Timeline Walkthrough

The Reacton DevTools extension adds a dedicated panel to Flutter DevTools.

### Opening DevTools

1. Run your app in debug mode: `flutter run --debug`
2. Open Flutter DevTools (the URL is printed in the terminal)
3. Navigate to the "Reacton" tab in the DevTools panel

### Timeline View

The timeline shows a chronological stream of state events:

```
┌─ 10:23:45.123 ─────────────────────────────────────┐
│ SET counter: 0 -> 1                                  │
│   Propagated to: doubleCount, isEven                 │
│   Widgets rebuilt: CounterDisplay                    │
│   Duration: 0.2ms                                    │
└──────────────────────────────────────────────────────┘
┌─ 10:23:45.456 ─────────────────────────────────────┐
│ BATCH (2 mutations)                                  │
│   SET firstName: 'John' -> 'Jane'                    │
│   SET lastName: 'Doe' -> 'Smith'                     │
│   Propagated to: fullName                            │
│   Widgets rebuilt: ProfileHeader                     │
│   Duration: 0.3ms                                    │
└──────────────────────────────────────────────────────┘
```

**What to look for:**
- **Unexpected propagation targets**: If a computed value recomputes when you did not expect it to, check its dependency list.
- **Missing batches**: Multiple SET events in rapid succession that should have been batched.
- **Long durations**: Propagation that takes more than 1ms might indicate an expensive computed value.
- **Excessive widget rebuilds**: More widgets rebuilding than expected suggests subscriptions are too broad.

### Filtering the Timeline

You can filter timeline events by:
- **Reacton name**: Show only events for a specific reacton
- **Event type**: Show only SETs, only BATCH events, or only EFFECT runs
- **Time range**: Focus on a specific window of time

## DevTools Graph View

The graph view visualizes the dependency graph as an interactive diagram.

### Reading the Graph

- **Green nodes**: Writable reactons (sources of truth)
- **Blue nodes**: Computed reactons (derived state)
- **Orange nodes**: Widget subscribers
- **Purple nodes**: Effects
- **Arrows**: Point from a dependency to its dependent ("A -> B" means B reads A)

### Interactive Features

- **Click a node**: Highlights all upstream dependencies (what it reads) and downstream dependents (what reads it)
- **Hover a node**: Shows the current value, subscriber count, and last update time
- **Search**: Find a specific reacton by name
- **Layout**: Toggle between hierarchical and force-directed layout

### What to Look For

1. **Orphaned nodes**: Reactons with no dependents and no subscribers. These may be unused state that should be cleaned up.
2. **Hub nodes**: Reactons with many dependents. A change to a hub node causes a large propagation wave. Consider whether all those dependencies are necessary.
3. **Deep chains**: A -> B -> C -> D -> E. Long chains increase propagation latency. Consider flattening by having E read A directly if the intermediate values are not used elsewhere.
4. **Cycles**: The graph should be a DAG (directed acyclic graph). If you see cycles, something is wrong -- a computed value cannot depend on itself.

## VS Code Extension Diagnostics

The Reacton VS Code extension provides inline diagnostics:

### Inline Value Display

When you hover over a reacton variable in your source code, the extension shows:
- Current value (if the app is running in debug mode)
- Number of active subscribers
- Last update timestamp

### Code Lens

Above each reacton declaration, a code lens shows:
- The number of places where this reacton is watched
- Quick navigation to all watch sites

### Problem Detection

The extension detects common issues and shows them as warnings:
- Creating reactons inside `build()` methods
- Using `context.read()` where `context.watch()` was likely intended
- Reactons without `name` parameter (harder to debug)

## Snapshot Comparison for Regression Debugging

When a bug occurs and you are not sure what state change caused it, snapshot comparison helps narrow down the problem.

### Taking Snapshots at Key Points

```dart
// Before a complex operation
final before = store.snapshot();

// Perform the operation
await performComplexUpdate();

// After the operation
final after = store.snapshot();

// Compare
final diff = compareSnapshots(before, after);
for (final change in diff) {
  print('${change.ref.debugName}: ${change.oldValue} -> ${change.newValue}');
}
```

### Implementing Snapshot Comparison

```dart
class SnapshotDiff {
  final ReactonRef ref;
  final dynamic oldValue;
  final dynamic newValue;
  SnapshotDiff(this.ref, this.oldValue, this.newValue);
}

List<SnapshotDiff> compareSnapshots(StoreSnapshot before, StoreSnapshot after) {
  final diffs = <SnapshotDiff>[];
  final allRefs = {...before.values.keys, ...after.values.keys};

  for (final ref in allRefs) {
    final oldVal = before.values[ref];
    final newVal = after.values[ref];
    if (oldVal != newVal) {
      diffs.add(SnapshotDiff(ref, oldVal, newVal));
    }
  }

  return diffs;
}
```

### Snapshot-Based Regression Tests

You can capture a snapshot of "known good" state and assert against it in tests:

```dart
test('checkout preserves user state', () {
  final store = TestReactonStore();
  setupInitialState(store);

  final userBefore = store.get(userReacton);
  final userSnapshot = store.snapshot();

  // Perform checkout (should not affect user state)
  store.set(cartReacton, emptyCart);

  // Assert user state is unchanged
  expect(store.get(userReacton), equals(userBefore));
});
```

## Step-by-Step Debugging Workflow

When something goes wrong, follow this systematic workflow:

### Step 1: Reproduce and Identify

Identify the symptom: incorrect value displayed, unexpected rebuild, stale state, or missing update.

### Step 2: Check the Timeline

Open DevTools and look at the timeline around when the bug occurs. Answer these questions:
- Was the expected `SET` event fired?
- Did it propagate to the expected computed values?
- Did the correct widgets rebuild?

### Step 3: Inspect the Graph

If propagation is wrong, check the graph view:
- Is the dependency edge present between the source and the computed value that should update?
- Is the widget subscribed to the correct reacton?

### Step 4: Add Targeted Logging

If DevTools does not show enough detail, add `LoggingMiddleware` to the specific reacton(s) in question:

```dart
final problematicReacton = reacton(
  initialValue,
  name: 'problematic',
  options: ReactonOptions(
    middleware: [LoggingMiddleware('DEBUG-problematic')],
  ),
);
```

### Step 5: Check Equality

A common cause of "missing updates" is incorrect equality. If a reacton holds a mutable object or a list/map, the default `==` might not detect changes:

```dart
// This does NOT trigger an update because List identity is the same
final list = store.get(todosReacton);
list.add(newTodo);
store.set(todosReacton, list); // Same reference, == returns true

// This DOES trigger an update because it's a new list
store.update(todosReacton, (list) => [...list, newTodo]);
```

### Step 6: Verify Reacton Identity

If a reacton seems to not exist in the store, verify that you are not accidentally creating a new reacton with a new identity. Check that your reacton is declared as a top-level variable or registered in a module, not created inline.

### Step 7: Test in Isolation

Extract the state logic and test it without widgets:

```dart
test('counter increments correctly', () {
  final store = ReactonStore();
  expect(store.get(counterReacton), 0);

  store.update(counterReacton, (c) => c + 1);
  expect(store.get(counterReacton), 1);

  // Verify computed value
  expect(store.get(doubleCountReacton), 2);
});
```

## Debugging Cheat Sheet

| Symptom | Likely Cause | Fix |
|---|---|---|
| Widget does not rebuild | Using `context.read()` instead of `context.watch()` | Switch to `context.watch()` |
| Widget rebuilds too often | Watching a broad reacton instead of a selector | Use `selector()` for the specific field |
| Computed value is stale | Missing dependency (not reading the source in compute function) | Ensure `read(source)` is called |
| "No reacton found" error | Reacton created inside `build()` (new identity each time) | Move declaration to top-level |
| Set has no effect | Value is equal to current (equality check passes) | Check `==` operator or use custom equality |
| Batch does not seem to work | Async code inside `batch()` (batch is synchronous) | Ensure all mutations inside `batch()` are synchronous |
| Effect runs twice on startup | Effect registered twice (e.g., in `initState` without guard) | Use a flag or register in module `onInit` |

## What's Next

- [Performance](/architecture/performance) -- Optimizing your graph
- [Scaling to Enterprise](/architecture/scaling) -- Debugging at scale with large teams
- [Testing](/testing/) -- Writing tests to prevent bugs before they reach production
