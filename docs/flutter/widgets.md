# Widgets

The `flutter_reacton` package provides four specialized widgets for different reactive UI patterns. Each serves a distinct purpose -- use the decision matrix at the bottom to choose the right one.

## ReactonBuilder

A `StatefulWidget` that subscribes to a single reacton and rebuilds its builder when the value changes.

### API

```dart
class ReactonBuilder<T> extends StatefulWidget {
  const ReactonBuilder({
    Key? key,
    required ReactonBase<T> reacton,
    required Widget Function(BuildContext context, T value) builder,
  });
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | The reacton to watch |
| `builder` | `Widget Function(BuildContext, T)` | Called with the current value whenever it changes |

### Example

```dart
ReactonBuilder<int>(
  reacton: counterReacton,
  builder: (context, count) => Text('Count: $count'),
)
```

### When to Use

Use `ReactonBuilder` when you want to isolate rebuilds to a specific subtree for a single reacton. It is more explicit than `context.watch()` and makes the subscription boundary visible in the widget tree.

```dart
// Only the Text rebuilds when counterReacton changes,
// not the entire Scaffold
Scaffold(
  appBar: AppBar(title: const Text('My App')),
  body: ReactonBuilder<int>(
    reacton: counterReacton,
    builder: (context, count) => Text('$count'),
  ),
)
```

## ReactonConsumer

A `StatefulWidget` that provides a `ReactonWidgetRef` to its builder, allowing you to watch multiple reactons within a single widget boundary.

### API

```dart
class ReactonConsumer extends StatefulWidget {
  const ReactonConsumer({
    Key? key,
    required Widget Function(BuildContext context, ReactonWidgetRef ref) builder,
  });
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `builder` | `Widget Function(BuildContext, ReactonWidgetRef)` | Called with a ref that can watch any number of reactons |

### ReactonWidgetRef

The `ref` object passed to the builder provides these methods:

| Method | Signature | Description |
|--------|-----------|-------------|
| `watch` | `T watch<T>(ReactonBase<T> reacton)` | Subscribe to a reacton (rebuilds on change) |
| `read` | `T read<T>(ReactonBase<T> reacton)` | One-time read (no subscription) |
| `set` | `void set<T>(WritableReacton<T> reacton, T value)` | Write a value |
| `update` | `void update<T>(WritableReacton<T> r, T Function(T) updater)` | Functional update |
| `store` | `ReactonStore get store` | Direct store access |

### Example

```dart
ReactonConsumer(
  builder: (context, ref) {
    final count = ref.watch(counterReacton);
    final name = ref.watch(nameReacton);
    final isEven = ref.watch(isEvenReacton);

    return Column(
      children: [
        Text('$name: $count'),
        Text(isEven ? 'Even' : 'Odd'),
        ElevatedButton(
          onPressed: () => ref.update(counterReacton, (c) => c + 1),
          child: const Text('Increment'),
        ),
      ],
    );
  },
)
```

### When to Use

Use `ReactonConsumer` when you need to:
- Watch **multiple reactons** in a single rebuild boundary
- Keep read and write operations co-located in the same builder
- Conditionally watch reactons based on other reacton values

::: tip
`ReactonConsumer` re-creates subscriptions on every build to support conditional watches. If the set of watched reactons changes between builds, the old subscriptions are cleaned up and new ones are created automatically.
:::

## ReactonListener

A `StatefulWidget` that listens to a reacton for side effects **without rebuilding its child**. The child widget is passed through unchanged.

### API

```dart
class ReactonListener<T> extends StatefulWidget {
  const ReactonListener({
    Key? key,
    required ReactonBase<T> reacton,
    required void Function(BuildContext context, T value) listener,
    bool Function(T previous, T current)? listenWhen,
    required Widget child,
  });
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | The reacton to listen to |
| `listener` | `void Function(BuildContext, T)` | Called when the value changes |
| `listenWhen` | `bool Function(T previous, T current)?` | Optional filter: listener is called only when this returns `true` |
| `child` | `Widget` | Child widget (never rebuilt by the listener) |

### Example

```dart
ReactonListener<String?>(
  reacton: errorReacton,
  listener: (context, error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  },
  child: const MyPageContent(),
)
```

### Conditional Listening with `listenWhen`

Use `listenWhen` to filter which changes trigger the listener:

```dart
ReactonListener<int>(
  reacton: counterReacton,
  listenWhen: (previous, current) => current > 10,
  listener: (context, count) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Count exceeded 10! Current: $count'),
      ),
    );
  },
  child: const CounterPage(),
)
```

### When to Use

Use `ReactonListener` for **side effects** that should not cause widget rebuilds:
- Showing snackbars, dialogs, or bottom sheets
- Navigation
- Analytics events
- Logging

## ReactonSelector

A `StatefulWidget` that watches a reacton but only rebuilds when a **selected sub-value** changes. More efficient than `ReactonBuilder` when you need only a small portion of a complex state object.

### API

```dart
class ReactonSelector<T, S> extends StatefulWidget {
  const ReactonSelector({
    Key? key,
    required ReactonBase<T> reacton,
    required S Function(T value) selector,
    required Widget Function(BuildContext context, S selected) builder,
  });
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | The source reacton |
| `selector` | `S Function(T)` | Extracts the sub-value from the full value |
| `builder` | `Widget Function(BuildContext, S)` | Called only when the selected sub-value changes |

### Example

```dart
ReactonSelector<User, String>(
  reacton: userReacton,
  selector: (user) => user.name,
  builder: (context, name) => Text('Hello, $name'),
)
```

In this example, if `userReacton` changes but `user.name` stays the same (e.g., only `user.email` changed), the widget does **not** rebuild.

### When to Use

Use `ReactonSelector` when:
- You have a complex state object (e.g., a `User` model with many fields)
- Your widget only depends on one or a few fields
- You want to avoid unnecessary rebuilds from unrelated field changes

::: tip
The selector uses `!=` to compare the previous and current selected values. For custom types, make sure to implement `==` and `hashCode` or use the `options.equals` parameter on the underlying reacton.
:::

## Decision Matrix

Use this table to choose the right widget for your use case:

| Use Case | Widget | Why |
|----------|--------|-----|
| Display a single reacton's value | `ReactonBuilder` | Simple, explicit subscription boundary |
| Display values from multiple reactons | `ReactonConsumer` | Single builder can watch many reactons |
| Inline reacton access in any widget | `context.watch()` | Least boilerplate, no extra widget needed |
| Side effects (snackbar, navigation) | `ReactonListener` | Does not rebuild child |
| Watch a sub-value of a complex reacton | `ReactonSelector` | Prevents rebuilds from unrelated changes |
| Read a value without rebuilding | `context.read()` | No subscription, use in event handlers |

### When to Prefer `context.watch()` Over Widgets

For most cases, `context.watch()` is the simplest approach:

```dart
// Simple and effective
@override
Widget build(BuildContext context) {
  final count = context.watch(counterReacton);
  return Text('$count');
}
```

Use the dedicated widgets when you need:
- **Explicit rebuild boundaries** in a large widget tree (`ReactonBuilder`)
- **Side effect callbacks** without rebuilds (`ReactonListener`)
- **Sub-value filtering** for complex state (`ReactonSelector`)
- **Multi-reacton ref-based access** in a single boundary (`ReactonConsumer`)

## Composing Widgets

These widgets can be freely composed and nested:

```dart
ReactonListener<String?>(
  reacton: errorReacton,
  listener: (context, error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  },
  child: ReactonConsumer(
    builder: (context, ref) {
      final count = ref.watch(counterReacton);
      final name = ref.watch(nameReacton);
      return Column(
        children: [
          Text('$name: $count'),
          ReactonSelector<User, String>(
            reacton: userReacton,
            selector: (user) => user.avatarUrl,
            builder: (context, url) => CircleAvatar(
              backgroundImage: NetworkImage(url),
            ),
          ),
        ],
      );
    },
  ),
)
```

## What's Next

- [Context Extensions](/flutter/context-extensions) -- The `context.watch()` / `context.read()` API
- [Form State](/flutter/forms) -- Reactive forms with `FormReacton` and `FieldReacton`
- [Auto-Dispose](/flutter/auto-dispose) -- Automatic cleanup when widgets unmount
