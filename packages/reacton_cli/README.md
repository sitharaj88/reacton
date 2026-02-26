# reacton_cli

CLI tool for the Reacton state management library. Scaffold reactons, generate feature modules, visualize dependency graphs, and diagnose configuration issues.

## Installation

```yaml
dev_dependencies:
  reacton_cli: ^0.1.0
```

Or activate globally:

```bash
dart pub global activate reacton_cli
```

## Commands

### reacton init

Add Reacton to an existing Flutter project. Updates `pubspec.yaml`, creates a default store configuration, and sets up recommended analysis options.

```bash
reacton init
```

### reacton create

Scaffold reactons and feature modules.

```bash
# Create a writable reacton
reacton create reacton counter

# Create a computed reacton
reacton create computed filtered_todos

# Create an async reacton
reacton create async weather

# Create a selector reacton
reacton create selector user_name

# Create a family
reacton create family user_by_id

# Create a full feature module (reactons + widget + test)
reacton create feature authentication
```

The `feature` subcommand generates a directory with reactons, a widget, and a test file:

```
lib/features/authentication/
  authentication_reactons.dart
  authentication_page.dart
test/features/authentication/
  authentication_test.dart
```

### reacton graph

Print the dependency graph of all reactons in your project.

```bash
# Text format (default)
reacton graph

# DOT format for Graphviz
reacton graph --dot > graph.dot
dot -Tpng graph.dot -o graph.png
```

Example output:

```
counterReacton (writable)
  -> doubleCountReacton (computed)
  -> tripleCountReacton (computed)
filterReacton (writable)
  -> filteredTodosReacton (computed)
todosReacton (writable)
  -> filteredTodosReacton (computed)
```

### reacton doctor

Diagnose common configuration issues in your Reacton project.

```bash
reacton doctor
```

Checks for:
- Missing dependencies (`reacton`, `flutter_reacton`)
- Missing `ReactonScope` in the widget tree
- Incorrect `analysis_options.yaml` configuration
- Outdated package versions

### reacton analyze

Analyze reactons for potential issues.

```bash
reacton analyze
```

Detects:
- Dead reactons (declared but never read)
- Cyclic dependencies in computed reactons
- High fan-out reactons (too many dependents)
- Overly complex computed chains

## Documentation

See the [Reacton documentation](https://github.com/sitharaj/reacton) for full API reference and guides.

## License

MIT
