# reacton_generator

Code generation for the Reacton state management library. Uses `build_runner` to analyze reacton dependency graphs at build time and produce `.reacton_graph.json` files.

## Installation

```yaml
dev_dependencies:
  reacton_generator: ^0.1.0
  build_runner: ^2.4.0
```

## Setup

Add a `build.yaml` to your project root:

```yaml
targets:
  $default:
    builders:
      reacton_generator|reacton_graph_analyzer:
        enabled: true
```

Then run the builder:

```bash
dart run build_runner build
```

## What It Does

### Graph Analyzer

The graph analyzer scans all Dart files in `lib/` for top-level reacton declarations (`reacton()`, `computed()`, `asyncReacton()`, `selector()`, `family()`) and produces a `.reacton_graph.json` file for each source file that contains reactons.

For a file like:

```dart
// lib/reactons/counter_reactons.dart
import 'package:reacton/reacton.dart';

final counterReacton = reacton(0, name: 'counter');
final doubleReacton = computed<int>((read) => read(counterReacton) * 2, name: 'double');
```

The builder produces:

```json
[
  {
    "name": "counterReacton",
    "type": "dynamic",
    "reactonKind": "reacton",
    "source": "lib/reactons/counter_reactons.dart",
    "dependencies": []
  },
  {
    "name": "doubleReacton",
    "type": "dynamic",
    "reactonKind": "computed",
    "source": "lib/reactons/counter_reactons.dart",
    "dependencies": ["counterReacton"]
  }
]
```

### Dependency Extraction

Inside `computed()` and `asyncReacton()` calls, the analyzer detects `read(someReacton)` invocations and records them as dependencies. This enables:

- Static dependency graph visualization (consumed by DevTools and `reacton graph`)
- Dead reacton detection at build time
- Cycle detection before runtime

### Annotations

Use `@ReactonSerializable` to generate `Serializer<T>` implementations for persistence:

```dart
import 'package:reacton_generator/reacton_generator.dart';

@ReactonSerializable()
class UserSettings {
  final bool darkMode;
  final String locale;

  UserSettings({required this.darkMode, required this.locale});
}
```

## Integration

The generated `.reacton_graph.json` files are consumed by:

- **reacton_devtools** -- Displays the static graph overlay in the Graph View tab
- **reacton_cli** -- The `reacton graph` and `reacton analyze` commands use these files for offline analysis

## Documentation

See the [Reacton documentation](https://github.com/sitharaj/reacton) for full API reference and guides.

## License

MIT
