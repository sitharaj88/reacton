# History (Undo/Redo)

Reacton provides built-in time-travel capabilities. Enable history on any writable reacton to get undo, redo, and jump-to-any-point navigation. Combined with the `ActionLog`, you get a full audit trail of every state mutation for debugging and analytics.

## Enabling History

Call `store.enableHistory()` to create a `History<T>` controller for any writable reacton:

```dart
final counterReacton = reacton(0, name: 'counter');

final history = store.enableHistory(counterReacton, maxHistory: 50);

store.set(counterReacton, 1);
store.set(counterReacton, 2);
store.set(counterReacton, 3);

history.undo(); // counter = 2
history.undo(); // counter = 1
history.redo(); // counter = 2
history.jumpTo(0); // counter = 0 (initial value)
```

### Signature

```dart
History<T> enableHistory<T>(
  WritableReacton<T> reacton, {
  int maxHistory = 100,
});
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `reacton` | `WritableReacton<T>` | -- | The reacton to track. |
| `maxHistory` | `int` | `100` | Maximum number of history entries. Oldest entries are evicted when the limit is reached. |

## History&lt;T&gt; API

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `entries` | `List<HistoryEntry<T>>` | Unmodifiable list of all history entries. |
| `currentIndex` | `int` | The current position in history (0-indexed). |
| `currentValue` | `T` | The value at the current history position. |
| `canUndo` | `bool` | `true` if there is a previous entry to undo to. |
| `canRedo` | `bool` | `true` if there is a next entry to redo to. |
| `length` | `int` | Total number of history entries. |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `undo()` | `void` | Go back one step in history. No-op if `canUndo` is `false`. |
| `redo()` | `void` | Go forward one step in history. No-op if `canRedo` is `false`. |
| `jumpTo(index)` | `void` | Jump to a specific index in history. Asserts that the index is in range. |
| `clear()` | `void` | Clear all history and start fresh with the current value. |
| `dispose()` | `void` | Unsubscribe from the reacton and free resources. |

## HistoryEntry&lt;T&gt;

Each entry in the history log records a value and when it was set.

```dart
class HistoryEntry<T> {
  final T value;
  final DateTime timestamp;
  final String? label;
}
```

| Field | Type | Description |
|-------|------|-------------|
| `value` | `T` | The value at this point in history. |
| `timestamp` | `DateTime` | When this entry was recorded. |
| `label` | `String?` | Optional label describing what caused this change. |

## How History Tracks Changes

History records every value change to the tracked reacton. When you undo or redo, the reacton's value is set directly by the history controller, and these undo/redo operations are **not** recorded as new entries (preventing infinite loops).

### Forking Behavior

When you undo to a previous state and then make a new change, all "future" entries (those after the current index) are discarded. This is the same behavior as text editor undo:

```
Initial state: [0]
                ^

Set to 1: [0, 1]
              ^

Set to 2: [0, 1, 2]
                 ^

Undo:     [0, 1, 2]
              ^           (current = 1)

Set to 5: [0, 1, 5]      (entry "2" is discarded)
                 ^
```

### Max History Enforcement

When the number of entries exceeds `maxHistory`, the oldest entries are removed from the front:

```
maxHistory = 3

[a, b, c]     (full)
Set d:
[b, c, d]     (oldest "a" evicted)
```

## Widget Integration

```dart
class DrawingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.store;
    // Assume history was created during app initialization
    // final history = store.enableHistory(canvasReacton);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: history.canUndo ? () => history.undo() : null,
            icon: Icon(Icons.undo),
          ),
          IconButton(
            onPressed: history.canRedo ? () => history.redo() : null,
            icon: Icon(Icons.redo),
          ),
        ],
      ),
      body: DrawingCanvas(),
    );
  }
}
```

## ActionLog

The `ActionLog` class provides a complete audit trail of all state mutations across the entire store. Unlike `History<T>` (which tracks a single reacton), `ActionLog` records changes to all reactons for debugging, analytics, and DevTools integration.

### Creating an ActionLog

```dart
final log = ActionLog(maxRecords: 1000);
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `maxRecords` | `int` | `1000` | Maximum number of records. Oldest are evicted when full. |

### Recording Actions

```dart
log.record(ActionRecord(
  reactonRef: counterReacton.ref,
  oldValue: 0,
  newValue: 1,
  timestamp: DateTime.now(),
  stackTrace: StackTrace.current, // optional, for debugging
));
```

### ActionRecord

| Field | Type | Description |
|-------|------|-------------|
| `reactonRef` | `ReactonRef` | The reacton that was modified. |
| `oldValue` | `dynamic` | The previous value. |
| `newValue` | `dynamic` | The new value. |
| `timestamp` | `DateTime` | When the action occurred. |
| `stackTrace` | `StackTrace?` | Stack trace at the point of mutation (for debugging). |

### Querying the Log

| Method | Returns | Description |
|--------|---------|-------------|
| `records` | `List<ActionRecord>` | All recorded actions (unmodifiable). |
| `forReacton(ref)` | `List<ActionRecord>` | All records for a specific reacton. |
| `inRange(from, to)` | `List<ActionRecord>` | Records within a time range. |
| `length` | `int` | Total number of recorded actions. |
| `isEnabled` | `bool` | Whether logging is currently enabled. |

### Controlling the Log

| Method | Description |
|--------|-------------|
| `enable()` | Enable logging (on by default). |
| `disable()` | Disable logging. New records are silently dropped. |
| `clear()` | Clear all records. |

### Example: Debugging State Changes

```dart
final log = ActionLog();

// After some mutations...
store.set(counterReacton, 1);
store.set(counterReacton, 2);
store.set(nameReacton, 'Alice');

// Query the log
final counterChanges = log.forReacton(counterReacton.ref);
print('Counter changed ${counterChanges.length} times');

for (final record in counterChanges) {
  print('  ${record.oldValue} -> ${record.newValue} at ${record.timestamp}');
}

// Query by time range
final recentChanges = log.inRange(
  DateTime.now().subtract(Duration(minutes: 5)),
  DateTime.now(),
);
print('${recentChanges.length} changes in the last 5 minutes');
```

## Complete Example: Form with Undo

```dart
// Form state
final formDataReacton = reacton(
  FormData(name: '', email: '', bio: ''),
  name: 'formData',
);

// Enable history
late final History<FormData> formHistory;

void initFormHistory(ReactonStore store) {
  formHistory = store.enableHistory(formDataReacton, maxHistory: 50);
}

// Widget
class EditProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final formData = context.watch(formDataReacton);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: formHistory.canUndo ? () => formHistory.undo() : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: formHistory.canRedo ? () => formHistory.redo() : null,
            tooltip: 'Redo',
          ),
          Text('${formHistory.currentIndex + 1}/${formHistory.length}'),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: TextEditingController(text: formData.name),
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) => context.set(
                formDataReacton,
                formData.copyWith(name: value),
              ),
            ),
            TextField(
              controller: TextEditingController(text: formData.email),
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (value) => context.set(
                formDataReacton,
                formData.copyWith(email: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## What's Next

- [State Branching](/advanced/branching) -- Preview state changes before committing
- [State Machines](/advanced/state-machines) -- Enforce typed state transitions
- [Middleware](/advanced/middleware) -- Intercept writes for logging and validation
