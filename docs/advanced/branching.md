# State Branching

Reacton supports git-like branching for state. A `StateBranch` is an isolated copy-on-write overlay on the parent store. Changes made to a branch do not affect the main store until explicitly merged. This enables speculative updates, form previews, A/B testing, and draft features.

## Creating a Branch

```dart
final branch = store.createBranch('dark-theme-preview');

// Modify the branch -- the main store is unaffected
branch.set(themeReacton, ThemeData.dark());

print(branch.get(themeReacton)); // dark theme
print(store.get(themeReacton));  // still light theme
```

### Signature

```dart
StateBranch createBranch(String name);
```

## Reading and Writing

Branches use copy-on-write: when you `get()`, the branch checks its overrides first, then falls back to the parent store. When you `set()`, only the branch is modified.

```dart
final branch = store.createBranch('preview');

// Read -- falls through to parent store
final currentTheme = branch.get(themeReacton); // parent's value

// Write -- only modifies the branch
branch.set(themeReacton, ThemeData.dark());

// Now reading returns the branch's override
print(branch.get(themeReacton)); // dark theme
print(store.get(themeReacton));  // still light theme (unchanged)
```

### Update with a Function

```dart
branch.update(counterReacton, (current) => current + 1);
```

## StateBranch API

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Name of this branch. |
| `parentStore` | `ReactonStore` | The parent store this branch was created from. |
| `createdAt` | `DateTime` | When this branch was created. |
| `isClosed` | `bool` | Whether this branch has been merged or discarded. |
| `isMerged` | `bool` | Whether this branch has been merged into the parent. |
| `isDiscarded` | `bool` | Whether this branch has been discarded. |
| `modifiedReactons` | `Set<ReactonRef>` | All reacton refs that have been modified in this branch. |

### Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `get` | `T get<T>(ReactonBase<T>)` | Read a value (checks overrides, then parent). |
| `set` | `void set<T>(WritableReacton<T>, T)` | Write a value (branch only). |
| `update` | `void update<T>(WritableReacton<T>, T Function(T))` | Update a value using a function. |
| `diff()` | `BranchDiff diff()` | Get all changes between this branch and the parent. |
| `discard()` | `void discard()` | Discard this branch, clearing all overrides. |

::: warning
You cannot modify a closed branch (one that has been merged or discarded). Attempting to `set()` on a closed branch will trigger an assertion error.
:::

## Inspecting Changes with diff()

The `diff()` method returns a `BranchDiff` showing all changes between the branch and its parent store.

```dart
final branch = store.createBranch('preview');
branch.set(themeReacton, ThemeData.dark());
branch.set(fontSizeReacton, 18.0);

final diff = branch.diff();

print(diff.branchName);    // 'preview'
print(diff.changeCount);   // 2
print(diff.isEmpty);       // false

for (final change in diff.changes.values) {
  print('${change.ref}: ${change.parentValue} -> ${change.branchValue}');
  print('  Changed: ${change.hasChanged}');
}
```

### BranchDiff

| Property | Type | Description |
|----------|------|-------------|
| `branchName` | `String` | Name of the branch. |
| `changes` | `Map<ReactonRef, BranchChange>` | All changes, keyed by reacton ref. |
| `isEmpty` | `bool` | Whether there are no changes. |
| `isNotEmpty` | `bool` | Whether there are changes. |
| `changeCount` | `int` | Number of changed reactons. |

### BranchChange

| Property | Type | Description |
|----------|------|-------------|
| `ref` | `ReactonRef` | The reacton that was changed. |
| `parentValue` | `dynamic` | The value in the parent store. |
| `branchValue` | `dynamic` | The value in the branch. |
| `hasChanged` | `bool` | Whether `parentValue != branchValue`. |

## Merging a Branch

Apply a branch's changes to the parent store with `store.mergeBranch()`:

```dart
final branch = store.createBranch('dark-theme-preview');
branch.set(themeReacton, ThemeData.dark());
branch.set(accentColorReacton, Colors.purple);

// Apply all branch changes to the store
store.mergeBranch(branch);

// Now the store has the branched values
print(store.get(themeReacton)); // dark theme
```

### Merge Strategy

Control how conflicts are resolved with `MergeStrategy`:

```dart
store.mergeBranch(branch, strategy: MergeStrategy.theirs); // default
store.mergeBranch(branch, strategy: MergeStrategy.ours);
```

| Strategy | Description |
|----------|-------------|
| `MergeStrategy.theirs` | Use the branch's values (default). The branch "wins." |
| `MergeStrategy.ours` | Keep the parent's values. Effectively discards branch changes. |

::: tip
Merging is atomic -- all changes are applied inside a `batch()`, so dependent computed reactons recompute only once.
:::

### Signature

```dart
void mergeBranch(
  StateBranch branch, {
  MergeStrategy strategy = MergeStrategy.theirs,
});
```

## Discarding a Branch

If you decide not to apply the branch's changes, discard it:

```dart
branch.discard();
// branch.isClosed == true
// All overrides are cleared
```

## Use Cases

### Form Preview

Let users preview form changes before saving:

```dart
class SettingsPreview extends StatefulWidget {
  @override
  _SettingsPreviewState createState() => _SettingsPreviewState();
}

class _SettingsPreviewState extends State<SettingsPreview> {
  late StateBranch _previewBranch;

  @override
  void initState() {
    super.initState();
    _previewBranch = context.store.createBranch('settings-preview');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview area shows branched state
        Text('Preview: ${_previewBranch.get(themeReacton)}'),

        // Controls modify the branch
        Switch(
          value: _previewBranch.get(darkModeReacton),
          onChanged: (dark) {
            setState(() {
              _previewBranch.set(darkModeReacton, dark);
            });
          },
        ),

        // Apply or discard
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                context.store.mergeBranch(_previewBranch);
                Navigator.pop(context);
              },
              child: Text('Apply'),
            ),
            TextButton(
              onPressed: () {
                _previewBranch.discard();
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (!_previewBranch.isClosed) {
      _previewBranch.discard();
    }
    super.dispose();
  }
}
```

### A/B Testing

Test different configurations without affecting the main app:

```dart
final branchA = store.createBranch('variant-a');
branchA.set(buttonColorReacton, Colors.blue);
branchA.set(layoutReacton, LayoutType.grid);

final branchB = store.createBranch('variant-b');
branchB.set(buttonColorReacton, Colors.green);
branchB.set(layoutReacton, LayoutType.list);

// Show user one variant, then merge the winner
if (userPreference == 'a') {
  store.mergeBranch(branchA);
  branchB.discard();
} else {
  store.mergeBranch(branchB);
  branchA.discard();
}
```

### Speculative Updates

Try a complex state transition and only commit if it succeeds:

```dart
final branch = store.createBranch('checkout');

try {
  branch.set(cartStatusReacton, CartStatus.processing);
  branch.update(inventoryReacton, (inv) => inv.deduct(items));
  branch.set(orderReacton, Order.from(items));

  // Validate the branch state
  final order = branch.get(orderReacton);
  if (order.isValid) {
    store.mergeBranch(branch);
  } else {
    branch.discard();
  }
} catch (e) {
  branch.discard();
  rethrow;
}
```

## What's Next

- [State Machines](/advanced/state-machines) -- Enforce typed state transitions with guards
- [History](/advanced/history) -- Add undo/redo to any reacton
- [Modules](/advanced/modules) -- Group related reactons with lifecycle management
