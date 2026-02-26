# Flutter Package API (`flutter_reacton`)

Complete API reference for the `flutter_reacton` package -- Flutter widgets, context extensions, form state management, and lifecycle utilities for Reacton.

```dart
import 'package:flutter_reacton/flutter_reacton.dart';
```

This package re-exports everything from `package:reacton/reacton.dart`, so a single import gives you both the core library and Flutter bindings.

---

## Widgets

### ReactonScope

Provides a `ReactonStore` to the widget tree. Wrap your app (or a subtree) with `ReactonScope` to make reactons available via context extensions.

```dart
ReactonScope({
  Key? key,
  ReactonStore? store,
  List<ReactonOverride>? overrides,
  required Widget child,
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `store` | `ReactonStore?` | `null` | Existing store (creates a new one if not provided) |
| `overrides` | `List<ReactonOverride>?` | `null` | Override reacton values (useful for testing) |
| `child` | `Widget` | required | The widget subtree |

#### Static Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `of(context)` | `ReactonStore` | Get the store from the nearest ancestor (creates dependency -- rebuilds on store change) |
| `read(context)` | `ReactonStore` | Get the store without creating a dependency |
| `maybeOf(context)` | `ReactonStore?` | Get the store if available, or null |

### ReactonOverride

Override a reacton's value in a `ReactonScope`.

```dart
const ReactonOverride<T>(ReactonBase<T> reacton, T value)
```

### ReactonBuilder\<T\>

A widget that rebuilds when a single reacton's value changes.

```dart
const ReactonBuilder<T>({
  Key? key,
  required ReactonBase<T> reacton,
  required Widget Function(BuildContext context, T value) builder,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | The reacton to watch |
| `builder` | `Widget Function(BuildContext, T)` | Builder called with the current value |

**Example:**

```dart
ReactonBuilder(
  reacton: counterReacton,
  builder: (context, count) => Text('$count'),
)
```

### ReactonConsumer

A widget that provides a `ReactonWidgetRef` for watching multiple reactons within a single builder.

```dart
const ReactonConsumer({
  Key? key,
  required Widget Function(BuildContext context, ReactonWidgetRef ref) builder,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `builder` | `Widget Function(BuildContext, ReactonWidgetRef)` | Builder with access to a ref object |

**Example:**

```dart
ReactonConsumer(
  builder: (context, ref) {
    final count = ref.watch(counterReacton);
    final name = ref.watch(nameReacton);
    return Text('$name: $count');
  },
)
```

### ReactonWidgetRef

Ref object provided by `ReactonConsumer` for accessing reactons.

| Method | Signature | Description |
|--------|-----------|-------------|
| `watch<T>(reacton)` | `T` | Watch a reacton (rebuilds on change) |
| `read<T>(reacton)` | `T` | Read without subscribing |
| `set<T>(reacton, value)` | `void` | Set a writable reacton's value |
| `update<T>(reacton, updater)` | `void` | Update using a function |
| `store` | `ReactonStore` | The underlying store |

### ReactonListener\<T\>

A widget that listens to reacton changes for side effects without rebuilding the child widget.

```dart
const ReactonListener<T>({
  Key? key,
  required ReactonBase<T> reacton,
  required void Function(BuildContext context, T value) listener,
  bool Function(T previous, T current)? listenWhen,
  required Widget child,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | The reacton to listen to |
| `listener` | `void Function(BuildContext, T)` | Called when the value changes |
| `listenWhen` | `bool Function(T, T)?` | Optional condition for when to call the listener |
| `child` | `Widget` | Child widget (not rebuilt) |

**Example:**

```dart
ReactonListener(
  reacton: errorReacton,
  listener: (context, error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  },
  child: MyWidget(),
)
```

### ReactonSelector\<T, S\>

A widget that rebuilds only when a selected sub-value changes. More efficient than `ReactonBuilder` when you only need a small part of a complex value.

```dart
const ReactonSelector<T, S>({
  Key? key,
  required ReactonBase<T> reacton,
  required S Function(T value) selector,
  required Widget Function(BuildContext context, S selected) builder,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `reacton` | `ReactonBase<T>` | The source reacton |
| `selector` | `S Function(T)` | Function to extract the sub-value |
| `builder` | `Widget Function(BuildContext, S)` | Builder called with the selected value |

**Example:**

```dart
ReactonSelector<User, String>(
  reacton: userReacton,
  selector: (user) => user.name,
  builder: (context, name) => Text(name),
)
```

---

## BuildContext Extensions

The primary API for using Reacton in Flutter widgets.

### ReactonBuildContextExtension

| Method | Signature | Description |
|--------|-----------|-------------|
| `watch<T>(reacton)` | `T` | Watch a reacton -- rebuilds this widget when the value changes |
| `read<T>(reacton)` | `T` | Read the current value without subscribing (use in event handlers) |
| `set<T>(reacton, value)` | `void` | Set a writable reacton's value |
| `update<T>(reacton, updater)` | `void` | Update a writable reacton using a function |
| `reactonStore` | `ReactonStore` | Access the store directly |

**Example:**

```dart
Widget build(BuildContext context) {
  final count = context.watch(counterReacton);
  return Column(
    children: [
      Text('$count'),
      ElevatedButton(
        onPressed: () => context.update(counterReacton, (c) => c + 1),
        child: Text('Increment'),
      ),
      ElevatedButton(
        onPressed: () => context.set(counterReacton, 0),
        child: Text('Reset'),
      ),
    ],
  );
}
```

---

## Form State Management

### FormReacton

A reactive form that manages a group of field reactons. Extends `WritableReacton<FormState>`.

```dart
FormReacton reactonForm({
  required Map<String, FieldReacton> fields,
  String? name,
})
```

| Member | Type | Description |
|--------|------|-------------|
| `fields` | `Map<String, FieldReacton>` | Map of field names to field reactons |

### FormState

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `isSubmitting` | `bool` | `false` | Whether the form is currently submitting |
| `isSubmitted` | `bool` | `false` | Whether the form has been submitted |
| `submitError` | `String?` | `null` | Error from the last submit attempt |
| `submitCount` | `int` | `0` | Number of submit attempts |

### FieldReacton\<T\>

A reactive form field with validation, dirty tracking, and touch state. Extends `WritableReacton<FieldState<T>>`.

```dart
FieldReacton<T> reactonField<T>(
  T initialValue, {
  List<Validator<T>> validators = const [],
  Future<String?> Function(T value)? asyncValidator,
  String? name,
})
```

| Member | Type | Description |
|--------|------|-------------|
| `validators` | `List<Validator<T>>` | Synchronous validators |
| `asyncValidator` | `Future<String?> Function(T)?` | Async validator |
| `initialFieldValue` | `T` | Initial value before changes |
| `validate(value)` | `String?` | Run synchronous validators |

### FieldState\<T\>

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `value` | `T` | required | Current field value |
| `error` | `String?` | `null` | Validation error message |
| `isDirty` | `bool` | `false` | Whether the value has changed from initial |
| `isTouched` | `bool` | `false` | Whether the user has interacted |
| `isValidating` | `bool` | `false` | Whether async validation is running |
| `isValid` | `bool` | computed | Whether `error` is null |

### Validators

| Factory | Signature | Description |
|---------|-----------|-------------|
| `required()` | `Validator<String>` | String is not empty |
| `minLength(min)` | `Validator<String>` | Minimum string length |
| `maxLength(max)` | `Validator<String>` | Maximum string length |
| `email()` | `Validator<String>` | Valid email format |
| `pattern(regex)` | `Validator<String>` | Matches a regex pattern |
| `range(min, max)` | `Validator<num>` | Numeric range |
| `matches(getOther)` | `Validator<String>` | Two values match (e.g., password confirmation) |
| `compose(validators)` | `Validator<T>` | Combine multiple validators (returns first error) |

### Store Form Extensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `isFormValid(form)` | `bool` | Check if all fields are valid |
| `validateForm(form)` | `bool` | Validate all fields; returns true if all valid |
| `submitForm(form, {onValid, onError})` | `Future<void>` | Validate and submit |
| `resetForm(form)` | `void` | Reset all fields to initial values |
| `touchAllFields(form)` | `void` | Touch all fields (shows all errors) |
| `isFormDirty(form)` | `bool` | Check if any field has been modified |
| `formField<T>(form, name)` | `FieldReacton<T>` | Get a specific field by name |

### Store Field Extensions

| Method | Signature | Description |
|--------|-----------|-------------|
| `setFieldValue<T>(field, value)` | `void` | Set value with auto-validation and dirty tracking |
| `touchField<T>(field)` | `void` | Mark field as touched |
| `resetField<T>(field)` | `void` | Reset field to initial state |
| `fieldValue<T>(field)` | `T` | Get the current value |
| `fieldError<T>(field)` | `String?` | Get the current error |

---

## Auto-Dispose

### AutoDisposeManager

Manages automatic disposal of reactons when they have no active watchers.

```dart
AutoDisposeManager(ReactonStore store, {Duration gracePeriod = const Duration(seconds: 5)})
```

| Method | Signature | Description |
|--------|-----------|-------------|
| `onWatch(ref)` | `void` | Notify that a watcher started watching |
| `onUnwatch(ref)` | `void` | Notify that a watcher stopped watching (starts grace period) |
| `watcherCount(ref)` | `int` | Current watcher count for a reacton |
| `cancelAll()` | `void` | Cancel all pending disposals |
| `dispose()` | `void` | Dispose the manager |

When the last watcher stops watching a reacton, a grace period timer starts. If no new watchers appear before it expires, the reacton is removed from the store.

---

## What's Next

- [Core Package API](./reacton) -- Core reactive primitives
- [Test Package API](./reacton-test) -- Testing utilities
