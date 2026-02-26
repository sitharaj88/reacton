# Debounce & Throttle

Rate-limiting is essential for any application that responds to rapid user input. Reacton provides two built-in utilities -- `Debouncer` and `Throttler` -- along with first-class integration via `ReactonOptions.debounce`.

## The Difference: Debounce vs. Throttle

**Debounce** waits for a pause in activity before executing. If events keep arriving, execution is continually postponed until the events stop. Think of it as "wait until the user stops typing."

**Throttle** executes at most once per time interval, regardless of how many events arrive. Think of it as "execute at most every N milliseconds."

### Timeline Visualization

Consider events arriving rapidly over 1 second, with a 300ms duration:

```
Events:    |x-x-x-x-x---x-x-------x-x-x------|
Time:      0   200 400   600  800  1000 1200 1400

Debounce:  |..............|..........|.........*|
           (waits 300ms after last event)    fires

Throttle:  |*.........*.........*.........*.....|
           fires     fires     fires     fires
           (at most once per 300ms)
```

- **Debounce**: Fires once, 300ms after the last event in each burst
- **Throttle**: Fires on the leading edge of each 300ms window

### When to Use Each

| Use Case | Technique | Why |
|---|---|---|
| Search-as-you-type | Debounce | Wait for the user to stop typing before querying the API |
| Form field validation | Debounce | Validate after the user finishes entering a value |
| Auto-save drafts | Debounce | Save after the user stops making changes |
| Scroll position tracking | Throttle | Send analytics at a steady rate, not on every pixel |
| Button click protection | Throttle | Prevent double-submit by limiting to one click per interval |
| Window resize handling | Throttle | Recompute layout at a bounded rate |
| Live sensor data | Throttle | Process readings at a manageable frequency |

## Debouncer Class

The `Debouncer` class delays function execution until a specified duration has passed without another call.

### API

```dart
class Debouncer {
  /// Create a debouncer with the given delay duration.
  Debouncer(Duration duration);

  /// Schedule the action to run after the debounce period.
  /// Cancels any previously scheduled action.
  void run(void Function() action);

  /// Cancel any pending execution.
  void cancel();

  /// Whether an action is currently scheduled and pending.
  bool get isPending;

  /// Dispose the debouncer, cancelling any pending action.
  void dispose();
}
```

### Basic Usage

```dart
final debouncer = Debouncer(Duration(milliseconds: 300));

void onSearchChanged(String query) {
  debouncer.run(() {
    // This only executes 300ms after the last call
    performSearch(query);
  });
}

// Later: clean up
debouncer.dispose();
```

### How It Works Internally

Each call to `run()`:
1. Cancels any existing pending timer
2. Starts a new timer with the specified duration
3. When the timer fires, the action executes

This means the action only fires after `duration` milliseconds of silence.

```dart
// Source: packages/reacton/lib/src/async/debounce.dart
void run(void Function() action) {
  _timer?.cancel();
  _timer = Timer(duration, action);
}
```

### Checking Pending State

You can check whether a debounced action is pending:

```dart
final debouncer = Debouncer(Duration(milliseconds: 500));

debouncer.run(() => saveDocument());

if (debouncer.isPending) {
  showIndicator('Saving...');
}
```

This is useful for showing "saving..." indicators or preventing navigation while an operation is pending.

## Throttler Class

The `Throttler` class ensures a function executes at most once per specified duration.

### API

```dart
class Throttler {
  /// Create a throttler with the given minimum interval.
  Throttler(Duration duration);

  /// Run the action, throttled to once per duration.
  /// If called during the cooldown period, the action is
  /// scheduled for the end of the period.
  void run(void Function() action);

  /// Cancel any pending scheduled execution.
  void cancel();

  /// Dispose the throttler, cancelling any pending execution.
  void dispose();
}
```

### Basic Usage

```dart
final throttler = Throttler(Duration(milliseconds: 200));

void onScroll(double offset) {
  throttler.run(() {
    // Executes at most once every 200ms
    trackScrollPosition(offset);
  });
}

// Later: clean up
throttler.dispose();
```

### How It Works Internally

On each call to `run()`, the throttler checks:
1. If enough time has passed since the last execution, it runs immediately
2. If not, it schedules the action for when the cooldown period ends

This ensures the latest action always runs eventually, while limiting the execution rate.

```dart
// Source: packages/reacton/lib/src/async/debounce.dart
void run(void Function() action) {
  final now = DateTime.now();
  if (_lastRun == null || now.difference(_lastRun!) >= duration) {
    _lastRun = now;
    action();
  } else {
    _timer?.cancel();
    final remaining = duration - now.difference(_lastRun!);
    _timer = Timer(remaining, () {
      _lastRun = DateTime.now();
      action();
    });
  }
}
```

## Integration with ReactonOptions

For the most common use case -- debouncing writes to a reacton -- Reacton provides a built-in `debounce` option:

```dart
final searchQueryReacton = reacton(
  '',
  name: 'searchQuery',
  options: ReactonOptions<String>(
    debounce: Duration(milliseconds: 300),
  ),
);
```

When `debounce` is set, calls to `store.set(searchQueryReacton, value)` are automatically debounced. The value is only written to the store (and propagated through the graph) after 300ms of no further `set()` calls.

### How This Differs from Manual Debouncing

| Approach | Behavior |
|---|---|
| `ReactonOptions.debounce` | Debounces the **write** itself. The reacton value does not change until the debounce fires. Computed values and widgets that depend on this reacton do not update until then. |
| Manual `Debouncer` in a widget | Debounces the **call to set**. The widget controls when `store.set()` is called. This gives more control over what happens during the debounce period. |

Use `ReactonOptions.debounce` for simplicity. Use a manual `Debouncer` when you need to show intermediate state (like a loading indicator) during the debounce period.

## Real-World Examples

### Search-as-You-Type

The most common debounce use case. Wait for the user to stop typing before hitting the API.

```dart
// State declarations
final searchQueryReacton = reacton('', name: 'search.query');

final searchResultsReacton = asyncReacton<List<Product>>(
  (read) async {
    final query = read(searchQueryReacton);
    if (query.isEmpty) return [];
    return await productApi.search(query);
  },
  name: 'search.results',
);

// Widget with debouncing
class SearchBar extends StatefulWidget {
  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _debouncer = Debouncer(Duration(milliseconds: 300));
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search products...',
        suffixIcon: _buildSuffixIcon(context),
      ),
      onChanged: (value) {
        _debouncer.run(() {
          context.set(searchQueryReacton, value);
        });
      },
    );
  }

  Widget _buildSuffixIcon(BuildContext context) {
    if (_debouncer.isPending) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(Icons.search);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }
}
```

### Alternative: Using ReactonOptions Debounce

For simpler cases where you do not need to show a pending indicator:

```dart
final searchQueryReacton = reacton(
  '',
  name: 'search.query',
  options: ReactonOptions<String>(
    debounce: Duration(milliseconds: 300),
  ),
);

// Widget -- no manual debouncer needed
class SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) {
        // Automatically debounced by ReactonOptions
        context.set(searchQueryReacton, value);
      },
    );
  }
}
```

### Button Throttling (Preventing Double-Submit)

Prevent a user from accidentally submitting a form twice by throttling the submit action:

```dart
class SubmitButton extends StatefulWidget {
  final VoidCallback onSubmit;
  SubmitButton({required this.onSubmit});

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  final _throttler = Throttler(Duration(seconds: 2));

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _throttler.run(() {
          widget.onSubmit();
        });
      },
      child: Text('Submit Order'),
    );
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }
}
```

### Form Validation with Debounce

Validate form fields after the user stops typing, avoiding validation on every keystroke:

```dart
class EmailField extends StatefulWidget {
  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  final _debouncer = Debouncer(Duration(milliseconds: 500));
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Email',
        errorText: _errorText,
      ),
      onChanged: (value) {
        // Clear error immediately for responsiveness
        if (_errorText != null) {
          setState(() => _errorText = null);
        }

        _debouncer.run(() {
          // Validate after 500ms of no typing
          final error = _validateEmail(value);
          setState(() => _errorText = error);

          // Also update the reacton
          context.set(emailReacton, value);
        });
      },
    );
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Invalid email format';
    return null;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
```

### Auto-Save with Debounce

Save a document draft after the user stops editing:

```dart
class DocumentEditor extends StatefulWidget {
  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  final _autoSaveDebouncer = Debouncer(Duration(seconds: 2));
  bool _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_hasUnsavedChanges)
          Text('Unsaved changes...', style: TextStyle(color: Colors.orange)),
        Expanded(
          child: TextField(
            maxLines: null,
            onChanged: (value) {
              setState(() => _hasUnsavedChanges = true);
              context.set(documentContentReacton, value);

              _autoSaveDebouncer.run(() async {
                await context.read(documentServiceReacton).saveDraft(value);
                if (mounted) {
                  setState(() => _hasUnsavedChanges = false);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Force save if there are unsaved changes
    if (_hasUnsavedChanges) {
      _autoSaveDebouncer.cancel();
      // Trigger immediate save
    }
    _autoSaveDebouncer.dispose();
    super.dispose();
  }
}
```

### Throttled Scroll Tracking

Track scroll position for analytics without overwhelming the event system:

```dart
class TrackedListView extends StatefulWidget {
  @override
  State<TrackedListView> createState() => _TrackedListViewState();
}

class _TrackedListViewState extends State<TrackedListView> {
  final _scrollThrottler = Throttler(Duration(milliseconds: 200));
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _scrollThrottler.run(() {
      final offset = _scrollController.offset;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final percentage = (offset / maxExtent * 100).round();

      context.set(scrollPositionReacton, percentage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 1000,
      itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
    );
  }

  @override
  void dispose() {
    _scrollThrottler.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

## Lifecycle and Cleanup

Both `Debouncer` and `Throttler` use `Timer` internally. Always dispose them when they are no longer needed to prevent memory leaks and unexpected callbacks:

```dart
@override
void dispose() {
  _debouncer.dispose();  // Cancels any pending timer
  _throttler.dispose();  // Cancels any pending timer
  super.dispose();
}
```

::: warning
If you forget to dispose a `Debouncer` or `Throttler`, the pending timer will fire after the widget is unmounted, potentially calling `setState` on a disposed widget or performing actions on stale state.
:::

## Combining with Effects

You can use `Debouncer` inside effects for scenarios where you want to debounce a reaction to state changes:

```dart
final debouncer = Debouncer(Duration(milliseconds: 500));

final disposeEffect = store.registerEffect(
  createEffect((read) {
    final query = read(searchQueryReacton);

    debouncer.run(() {
      // This runs 500ms after the last searchQuery change
      analyticsService.trackSearch(query);
    });

    return () => debouncer.cancel();
  }, name: 'debouncedSearchTracking'),
);
```

The cleanup function returned by the effect cancels the debouncer when the effect re-runs or is disposed, preventing stale callbacks.

## What's Next

- [Async Reactons](/async/async-reacton) -- Loading async data into reactons
- [Query Reactons](/async/query-reacton) -- Advanced data fetching with caching
- [Retry Policies](/async/retry) -- Handling transient failures
