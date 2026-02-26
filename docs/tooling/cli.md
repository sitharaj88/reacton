# CLI

The `reacton_cli` package provides a command-line tool for initializing projects, scaffolding reactons and features, visualizing the dependency graph, running diagnostics, and analyzing code quality.

## Installation

```bash
dart pub global activate reacton_cli
```

After activation, the `reacton` command is available globally.

## Commands

| Command | Description |
|---------|-------------|
| `reacton init` | Add Reacton to an existing Flutter project |
| `reacton create` | Scaffold reactons and features from templates |
| `reacton graph` | Print the reacton dependency graph |
| `reacton doctor` | Diagnose common configuration issues |
| `reacton analyze` | Analyze reactons for dead code, cycles, and complexity |

---

## reacton init

Adds Reacton dependencies to an existing Flutter project and scaffolds starter files.

```bash
reacton init
```

### What It Does

1. Adds `flutter_reacton: ^0.1.0` to `dependencies` in `pubspec.yaml`
2. Adds `reacton_test: ^0.1.0` to `dev_dependencies`
3. Adds `reacton_lint: ^0.1.0` to `dev_dependencies`
4. Creates `lib/reactons/` directory
5. Adds `custom_lint` plugin to `analysis_options.yaml`
6. (With `--example`) Creates a starter `counter_reacton.dart`

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--example` / `--no-example` | `true` | Create a starter counter reacton and wrap main.dart with ReactonScope |

### Example

```bash
# With starter example (default)
reacton init

# Without starter example
reacton init --no-example
```

### Output

```
Adding Reacton to your project...

  [+] Added flutter_reacton to dependencies
  [+] Added reacton_test to dev_dependencies
  [+] Added reacton_lint to dev_dependencies
  [+] Created lib/reactons/ directory
  [+] Added custom_lint to analysis_options.yaml

Reacton initialized successfully!

Next steps:
  1. Run: flutter pub get
  2. Wrap your app with ReactonScope:

     ReactonScope(
       child: MaterialApp(...),
     )

  3. Create reactons in lib/reactons/
  4. Use context.watch(myReacton) in widgets
```

---

## reacton create

Scaffolds reactons, computed values, async reactons, selectors, families, and full feature modules from templates.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `reacton create reacton <name>` | Create a writable reacton file |
| `reacton create computed <name>` | Create a computed reacton file |
| `reacton create async <name>` | Create an async reacton file |
| `reacton create selector <name>` | Create a selector reacton file |
| `reacton create family <name>` | Create a reacton family file |
| `reacton create feature <name>` | Create a full feature module |

### create reacton

```bash
reacton create reacton userName --type String --default "''"
```

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Dart type of the reacton value |
| `--default` | `-d` | `''` | Default initial value |
| `--dir` | -- | `lib/reactons` | Output directory |

Creates `lib/reactons/user_name_reacton.dart`.

### create computed

```bash
reacton create computed totalPrice --type double
```

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Computed value type |
| `--dir` | -- | `lib/reactons` | Output directory |

### create async

```bash
reacton create async userProfile --type User
```

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Async data type |
| `--dir` | -- | `lib/reactons` | Output directory |

### create selector

```bash
reacton create selector userName --type String --source-type User
```

| Option | Default | Description |
|--------|---------|-------------|
| `--type` | `String` | Selected value type |
| `--source-type` | `String` | Source reacton type |
| `--dir` | `lib/reactons` | Output directory |

Creates `lib/reactons/user_name_selector.dart`.

### create family

```bash
reacton create family userById --type User --param-type int --default "null"
```

| Option | Default | Description |
|--------|---------|-------------|
| `--type` | `String` | Reacton value type |
| `--param-type` | `String` | Family parameter type |
| `--default` | `''` | Default value |
| `--dir` | `lib/reactons` | Output directory |

Creates `lib/reactons/user_by_id_family.dart`.

### create feature

Scaffolds a complete feature module with reactons, a page widget, and a test file.

```bash
reacton create feature shopping_cart
```

| Flag | Default | Description |
|------|---------|-------------|
| `--with-test` / `--no-with-test` | `true` | Generate a test file |

Creates:

```
lib/features/shopping_cart/
  shopping_cart_reactons.dart
  shopping_cart_page.dart
test/features/
  shopping_cart_test.dart
```

Output:

```
Created feature: shopping_cart
  lib/features/shopping_cart/shopping_cart_reactons.dart
  lib/features/shopping_cart/shopping_cart_page.dart
  test/features/shopping_cart_test.dart
```

---

## reacton graph

Prints the reacton dependency graph by scanning `lib/` for reacton declarations.

```bash
reacton graph
```

### Output (text, default)

```
Reacton Dependency Graph
========================================

  [W] counterReacton (lib/reactons/counter_reacton.dart)
  [C] doubleCountReacton (lib/reactons/counter_reacton.dart)
  [A] weatherReacton (lib/reactons/weather_reacton.dart)
  [S] userNameReacton (lib/reactons/user_reacton.dart)
  [F] todoDetailReacton (lib/reactons/todo_reacton.dart)

Legend: [W]=Writable [C]=Computed [A]=Async [S]=Selector [F]=Family
Total reactons: 5
```

### DOT Output (for Graphviz)

```bash
reacton graph --dot
```

```txt
digraph reacton {
  rankdir=LR;
  node [shape=box, style=rounded];

  "counterReacton" [fillcolor="#4A90D9", style="filled,rounded", fontcolor=white];
  "doubleCountReacton" [fillcolor="#5CB85C", style="filled,rounded", fontcolor=white];
  "weatherReacton" [fillcolor="#F0AD4E", style="filled,rounded", fontcolor=white];
}
```

Pipe it to Graphviz to generate an image:

```bash
reacton graph --dot | dot -Tpng -o graph.png
```

### Flags

| Flag | Description |
|------|-------------|
| `--dot` | Output in DOT format for Graphviz |

### Color Coding

| Color | Type |
|-------|------|
| Blue (`#4A90D9`) | Writable reacton |
| Green (`#5CB85C`) | Computed reacton |
| Orange (`#F0AD4E`) | Async reacton |
| Red (`#D9534F`) | Selector |
| Purple (`#9B59B6`) | Family |

---

## reacton doctor

Diagnoses common Reacton configuration issues in the current project.

```bash
reacton doctor
```

### Checks

| Check | Description |
|-------|-------------|
| `pubspec.yaml exists` | The project has a pubspec.yaml |
| `Reacton dependency found` | `flutter_reacton` or `reacton` is in dependencies |
| `reacton_test dev dependency` | `reacton_test` is in dev_dependencies |
| `ReactonScope in main.dart` | `lib/main.dart` contains `ReactonScope` |
| `lib/reactons/ directory exists` | Convention directory for reacton files |
| `test/ directory exists` | Test directory exists |

### Output

```
Reacton Doctor
========================================

  [OK] pubspec.yaml exists
  [OK] Reacton dependency found
  [!!] reacton_test dev dependency
  [OK] ReactonScope in main.dart
  [OK] lib/reactons/ directory exists
  [OK] test/ directory exists

Found 1 issue(s). Fix them for optimal Reacton usage.
```

---

## reacton analyze

Analyzes reacton declarations for issues including dead reactons, circular dependencies, complexity, and naming conventions.

```bash
reacton analyze
```

### Analysis Checks

| Check | Severity | Description |
|-------|----------|-------------|
| Dead reactons | Warning | Declared but never referenced in any other file |
| Circular dependencies | Error | Computed reactons forming a cycle (detected via DFS) |
| High complexity | Info | Computed reactons with more than 5 dependencies |
| Naming conventions | Info | Reactons not following the `xxxReacton` suffix convention |

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--fix` | `false` | Auto-fix simple issues (removes unused imports for dead reactons) |
| `--format` | `text` | Output format: `text` or `json` |

### Text Output

```
Reacton Analyze
========================================

[WARN] Dead reacton: oldCounterReacton (lib/reactons/old.dart)
  -> Declared but never referenced in any other file

[ERROR] Circular dependency detected:
  -> computedA -> computedB -> computedA

[INFO] High complexity: dashboardReacton (lib/reactons/dashboard.dart)
  -> 7 dependencies (threshold: 5)

[INFO] Naming convention: counter (lib/reactons/counter.dart)
  -> Consider renaming to counterReacton

========================================
Issues: 1 error, 1 warning, 2 info
```

### JSON Output

```bash
reacton analyze --format json
```

```json
{
  "issues": [
    {
      "severity": "warning",
      "message": "Dead reacton: oldCounterReacton (lib/reactons/old.dart)",
      "detail": "Declared but never referenced in any other file",
      "reacton": "oldCounterReacton",
      "file": "lib/reactons/old.dart",
      "type": "dead_reacton"
    }
  ],
  "summary": {
    "errors": 0,
    "warnings": 1,
    "info": 0,
    "total": 1
  }
}
```

### Auto-fix

```bash
reacton analyze --fix
```

Currently supports removing unused imports for dead reactons.

## What's Next

- [Code Generation](./code-generation) -- Annotations and build_runner integration
- [Lint Rules](./lint-rules) -- Custom lint rules for Reacton
- [DevTools](./devtools) -- Runtime graph visualization
