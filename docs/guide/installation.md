# Installation

Add Reacton to your Flutter project in under a minute. The `flutter_reacton` package is all you need -- it re-exports the core `reacton` package automatically.

## Add the Dependency

Add `flutter_reacton` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_reacton: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Import

A single import gives you access to everything -- core reacton primitives, Flutter widgets, and context extensions:

```dart
import 'package:flutter_reacton/flutter_reacton.dart';
```

::: tip
You do **not** need to import `package:reacton/reacton.dart` separately. The `flutter_reacton` package re-exports it.
:::

## Wrap Your App with ReactonScope

`ReactonScope` is an `InheritedWidget` that provides a `ReactonStore` to the widget tree. Wrap your app (or a subtree) with it:

```dart
void main() {
  runApp(ReactonScope(child: const MyApp()));
}
```

That is all the setup required. You can now use `context.watch()`, `context.set()`, and all other Reacton APIs anywhere below the `ReactonScope`.

## Minimum Versions

| Requirement | Version |
|-------------|---------|
| Dart SDK | `>=3.0.0` |
| Flutter SDK | `>=3.10.0` |

## Additional Packages

Install these packages as needed for testing, linting, CLI tooling, and code generation:

### Testing

```yaml
dev_dependencies:
  reacton_test: ^0.1.0
```

Provides `TestStore`, mock reactons, graph assertions, effect tracking, and widget test pump helpers.

### CLI

```bash
dart pub global activate reacton_cli
```

Scaffold projects, generate reacton boilerplate, analyze dependency graphs, and run diagnostics from the command line.

### Lint Rules

```yaml
dev_dependencies:
  reacton_lint: ^0.1.0
```

Then add to your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - reacton_lint
```

Catches common mistakes like using `context.read()` inside `build()` methods.

### Code Generation

```yaml
dependencies:
  reacton_generator: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
```

Annotation-driven reacton generation and automatic graph analysis via `build_runner`.

### DevTools Extension

```yaml
dev_dependencies:
  reacton_devtools: ^0.1.0
```

A Flutter DevTools extension for visualizing the reactive graph, inspecting reacton values in real time, and time-travel debugging.

## Verifying the Installation

Create a minimal app to verify everything works:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

final greeting = reacton('Hello, Reacton!', name: 'greeting');

void main() => runApp(ReactonScope(child: const MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => Text(context.watch(greeting)),
          ),
        ),
      ),
    );
  }
}
```

If you see "Hello, Reacton!" on screen, you are all set.

## What's Next

- [Quick Start](/guide/quick-start) -- Build a counter app step by step
- [Core Concepts](/guide/core-concepts) -- Understand reactons, computed values, and the store
- [Flutter Integration](/flutter/) -- Explore ReactonScope, widgets, and context extensions
