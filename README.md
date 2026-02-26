# Reacton

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart 3](https://img.shields.io/badge/dart-%3E%3D3.0-blue.svg)](https://dart.dev)
[![Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)

A novel reactive graph engine for Flutter. Fine-grained state management with reactons, computed values, effects, async reactons, state branching, time-travel, and more.

## Packages

| Package | Description | Version |
|---------|-------------|---------|
| [reacton](packages/reacton/) | Pure Dart core -- reactons, reactive graph, store, async, middleware | 0.1.0 |
| [flutter_reacton](packages/flutter_reacton/) | Flutter widgets -- ReactonScope, ReactonBuilder, context.watch() | 0.1.0 |
| [reacton_test](packages/reacton_test/) | Testing utilities -- TestReactonStore, mocks, widget helpers | 0.1.0 |
| [reacton_lint](packages/reacton_lint/) | Custom lint rules via custom_lint | 0.1.0 |
| [reacton_cli](packages/reacton_cli/) | CLI tool -- scaffolding, graph analysis, diagnostics | 0.1.0 |
| [reacton_devtools](packages/reacton_devtools/) | DevTools extension -- graph view, inspector, timeline | 0.1.0 |
| [reacton_generator](packages/reacton_generator/) | Code generation with build_runner | 0.1.0 |

## Quick Start

Add `flutter_reacton` to your Flutter project (it re-exports `reacton`):

```yaml
dependencies:
  flutter_reacton: ^0.1.0
```

```dart
import 'package:flutter_reacton/flutter_reacton.dart';

// 1. Define reactons at the top level
final counterReacton = atom(0, name: 'counter');
final doubleReacton = computed<int>((read) => read(counterReacton) * 2, name: 'double');

// 2. Wrap your app in ReactonScope
void main() => runApp(ReactonScope(child: MyApp()));

// 3. Use in widgets
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterReacton);
    final doubled = context.watch(doubleReacton);

    return Column(
      children: [
        Text('Count: $count'),
        Text('Doubled: $doubled'),
        ElevatedButton(
          onPressed: () => context.update(counterReacton, (n) => n + 1),
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

## Architecture

Reacton is built around a **reactive graph engine** using a two-phase **mark/propagate** algorithm:

1. **Mark phase** -- When a reacton changes, all downstream nodes are marked stale in topological order.
2. **Propagate phase** -- Stale nodes are recomputed level-by-level. If a recomputed value is unchanged, propagation stops early (glitch-free).

Three API levels for progressive complexity:

- **Level 1 (Beginner):** `atom()`, `context.watch()`, `context.set()`
- **Level 2 (Intermediate):** `computed()`, `effect()`, `asyncReacton()`, `selector()`, `family()`
- **Level 3 (Advanced):** `createBranch()`, `enableHistory()`, middleware, persistence, isolates

## Development

This is a [Melos](https://melos.invertase.dev/) monorepo.

```bash
# Bootstrap all packages
melos bootstrap

# Run tests across all packages
melos run test

# Run static analysis
melos run analyze

# Check formatting
melos run format
```

## Examples

- [Counter](examples/counter/) -- Minimal counter app
- [Todo App](examples/todo_app/) -- Full-featured todo app with filtering
- [Realtime Chat](examples/realtime_chat/) -- Async reactons with real-time updates

## License

MIT
