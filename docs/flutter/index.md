# Flutter Integration

The `flutter_reacton` package provides everything you need to use Reacton in Flutter -- widgets, context extensions, form state management, and automatic lifecycle cleanup.

## Overview

Flutter integration is built on three layers:

1. **ReactonScope** -- An `InheritedWidget` that provides a `ReactonStore` to the widget tree
2. **Context Extensions** -- `context.watch()`, `context.read()`, `context.set()`, and `context.update()` for inline reacton access
3. **Specialized Widgets** -- `ReactonBuilder`, `ReactonConsumer`, `ReactonListener`, and `ReactonSelector` for specific use cases

## Quick Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

final counter = reacton(0, name: 'counter');

void main() => runApp(ReactonScope(child: const MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch(counter);
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('$count')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.update(counter, (c) => c + 1),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## Import

A single import gives you access to everything:

```dart
import 'package:flutter_reacton/flutter_reacton.dart';
```

This re-exports the core `reacton` package, so you get both Flutter widgets and core reacton primitives.

## Pages in This Section

| Page | What You Will Learn |
|------|---------------------|
| [ReactonScope](/flutter/reacton-scope) | How to provide a `ReactonStore` to the widget tree, nested scopes, and testing overrides |
| [Context Extensions](/flutter/context-extensions) | `context.watch()`, `context.read()`, `context.set()`, `context.update()`, and the subscription tracking mechanism |
| [Widgets](/flutter/widgets) | `ReactonBuilder`, `ReactonConsumer`, `ReactonListener`, `ReactonSelector` -- when and how to use each |
| [Form State](/flutter/forms) | `FormReacton`, `FieldReacton`, built-in validators, and complete form examples |
| [Auto-Dispose](/flutter/auto-dispose) | Automatic cleanup of reacton subscriptions and the grace period lifecycle |

## What's Next

- [ReactonScope](/flutter/reacton-scope) -- Start with the foundational widget
- [Core Concepts](/guide/core-concepts) -- Understand the underlying reacton primitives
