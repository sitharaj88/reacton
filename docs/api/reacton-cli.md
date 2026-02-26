# reacton_cli API Reference

The Reacton CLI (`reacton_cli`) provides commands for scaffolding, analyzing, and diagnosing Reacton projects from the terminal.

## Installation

```bash
# Activate globally
dart pub global activate reacton_cli

# Or add as a dev dependency
flutter pub add --dev reacton_cli
```

When installed as a dev dependency, run commands with:

```bash
dart run reacton_cli <command>
```

---

## reacton init

Add Reacton to an existing Flutter project. This command modifies `pubspec.yaml`, creates a `lib/reactons/` directory, optionally scaffolds a starter counter reacton, and configures `analysis_options.yaml` for lint rules.

### Usage

```bash
reacton init [--no-example]
```

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--example` / `--no-example` | `--example` | Create a starter `counter_reacton.dart` and show setup instructions |

### What It Does

1. **Adds dependencies to `pubspec.yaml`:**
   - `flutter_reacton: ^0.1.0` under `dependencies`
   - `reacton_test: ^0.1.0` under `dev_dependencies`
   - `reacton_lint: ^0.1.0` under `dev_dependencies`

2. **Creates `lib/reactons/` directory** (if it does not exist)

3. **Scaffolds `lib/reactons/counter_reacton.dart`** (unless `--no-example`)

4. **Adds `custom_lint` plugin** to `analysis_options.yaml` (if not already present)

### Example Output

```
$ reacton init

Adding Reacton to your project...

  [+] Added flutter_reacton to dependencies
  [+] Added reacton_test to dev_dependencies
  [+] Added reacton_lint to dev_dependencies
  [+] Created lib/reactons/ directory
  [+] Created lib/reactons/counter_reacton.dart
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

A starter counterReacton has been created at lib/reactons/counter_reacton.dart
```

### Error Handling

If no `pubspec.yaml` is found in the current directory:

```
Error: No pubspec.yaml found in current directory.
Run this command from the root of a Flutter project.
```

If Reacton is already configured:

```
Reacton is already configured in this project.
```

---

## reacton create

Scaffold reactons and features from templates. This command has six subcommands for different reacton types.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `reacton create reacton <name>` | Create a writable reacton file |
| `reacton create computed <name>` | Create a computed reacton file |
| `reacton create async <name>` | Create an async reacton file |
| `reacton create selector <name>` | Create a selector reacton file |
| `reacton create family <name>` | Create a reacton family file |
| `reacton create feature <name>` | Create a full feature module (reactons + page + test) |

---

### reacton create reacton

Create a writable reacton file.

```bash
reacton create reacton <name> [options]
```

**Options:**

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Dart type for the reacton value |
| `--default` | `-d` | `''` | Default initial value |
| `--dir` | | `lib/reactons` | Output directory |

**Example:**

```bash
$ reacton create reacton userAge --type int --default 0

Created: lib/reactons/user_age_reacton.dart
```

Generated file:

```dart
import 'package:reacton/reacton.dart';

/// userAge state
final userAgeReacton = reacton<int>(0, name: 'userAge');
```

---

### reacton create computed

Create a computed reacton file.

```bash
reacton create computed <name> [options]
```

**Options:**

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Dart type for the computed value |
| `--dir` | | `lib/reactons` | Output directory |

**Example:**

```bash
$ reacton create computed fullName --type String

Created: lib/reactons/full_name_reacton.dart
```

Generated file:

```dart
import 'package:reacton/reacton.dart';

/// Computed fullName
final fullNameReacton = computed<String>((read) {
  // TODO: Compute derived value
  return read(sourceReacton);
}, name: 'fullName');
```

---

### reacton create async

Create an async reacton file.

```bash
reacton create async <name> [options]
```

**Options:**

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Dart type for the async value |
| `--dir` | | `lib/reactons` | Output directory |

**Example:**

```bash
$ reacton create async weather --type Weather

Created: lib/reactons/weather_reacton.dart
```

Generated file:

```dart
import 'package:reacton/reacton.dart';

/// Async weather
final weatherReacton = asyncReacton<Weather>((read) async {
  throw UnimplementedError('Implement weather fetch');
}, name: 'weather');
```

---

### reacton create selector

Create a selector reacton file.

```bash
reacton create selector <name> [options]
```

**Options:**

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Selected (output) type |
| `--source-type` | | `String` | Source reacton type |
| `--dir` | | `lib/reactons` | Output directory |

**Example:**

```bash
$ reacton create selector userName --type String --source-type User

Created: lib/reactons/user_name_selector.dart
```

---

### reacton create family

Create a reacton family file.

```bash
reacton create family <name> [options]
```

**Options:**

| Option | Abbr | Default | Description |
|--------|------|---------|-------------|
| `--type` | `-t` | `String` | Reacton value type |
| `--param-type` | | `String` | Family parameter type |
| `--default` | `-d` | `''` | Default value |
| `--dir` | | `lib/reactons` | Output directory |

**Example:**

```bash
$ reacton create family userById --type User --param-type String

Created: lib/reactons/user_by_id_family.dart
```

---

### reacton create feature

Scaffold a full feature module with reactons, a page widget, and a test file.

```bash
reacton create feature <name> [options]
```

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `--with-test` / `--no-with-test` | `--with-test` | Also generate a test file |

**Example:**

```bash
$ reacton create feature checkout

Created feature: checkout
  lib/features/checkout/checkout_reactons.dart
  lib/features/checkout/checkout_page.dart
  test/features/checkout_test.dart
```

The generated files follow this structure:

- `checkout_reactons.dart` -- Reacton declarations for the feature
- `checkout_page.dart` -- A `StatelessWidget` page that uses `context.watch()`
- `checkout_test.dart` -- A test file with `TestReactonStore` setup

::: tip
Use `--no-with-test` to skip test generation if you prefer to organize tests differently.
:::

---

## reacton graph

Print the reacton dependency graph by scanning all `.dart` files in `lib/`.

### Usage

```bash
reacton graph [--dot]
```

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--dot` | `false` | Output in DOT format (for Graphviz) instead of plain text |

### Text Output (Default)

```
$ reacton graph

Reacton Dependency Graph
========================================

  [W] counterReacton (lib/reactons/counter_reacton.dart)
  [C] doubleCountReacton (lib/reactons/counter_reacton.dart)
  [W] todosReacton (lib/features/todo/todo_reactons.dart)
  [C] filteredTodosReacton (lib/features/todo/todo_reactons.dart)
  [A] weatherReacton (lib/features/weather/weather_reactons.dart)
  [F] userByIdFamily (lib/reactons/user_family.dart)
  [S] userNameSelector (lib/reactons/user_selector.dart)

Legend: [W]=Writable [C]=Computed [A]=Async [S]=Selector [F]=Family
Total reactons: 7
```

### DOT Output

The DOT format can be piped to Graphviz to generate an image:

```bash
$ reacton graph --dot

digraph reacton {
  rankdir=LR;
  node [shape=box, style=rounded];

  "counterReacton" [fillcolor="#4A90D9", style="filled,rounded", fontcolor=white];
  "doubleCountReacton" [fillcolor="#5CB85C", style="filled,rounded", fontcolor=white];
  "todosReacton" [fillcolor="#4A90D9", style="filled,rounded", fontcolor=white];
  "filteredTodosReacton" [fillcolor="#5CB85C", style="filled,rounded", fontcolor=white];
  "weatherReacton" [fillcolor="#F0AD4E", style="filled,rounded", fontcolor=white];
  "userByIdFamily" [fillcolor="#9B59B6", style="filled,rounded", fontcolor=white];
  "userNameSelector" [fillcolor="#D9534F", style="filled,rounded", fontcolor=white];
}
```

**Generate a PNG image:**

```bash
reacton graph --dot | dot -Tpng -o reacton_graph.png
```

**Generate an SVG:**

```bash
reacton graph --dot | dot -Tsvg -o reacton_graph.svg
```

### Node Colors

| Type | Color | Hex |
|------|-------|-----|
| Writable (`reacton`) | Blue | `#4A90D9` |
| Computed (`computed`) | Green | `#5CB85C` |
| Async (`asyncReacton`) | Orange | `#F0AD4E` |
| Selector (`selector`) | Red | `#D9534F` |
| Family (`family`) | Purple | `#9B59B6` |

---

## reacton doctor

Diagnose common Reacton configuration issues in the current project.

### Usage

```bash
reacton doctor
```

### Checks Performed

| Check | What It Verifies |
|-------|-----------------|
| `pubspec.yaml exists` | Running from a Flutter/Dart project root |
| `Reacton dependency found` | `flutter_reacton` or `reacton` is in dependencies |
| `reacton_test dev dependency` | `reacton_test` is in dev_dependencies |
| `ReactonScope in main.dart` | `lib/main.dart` contains `ReactonScope` |
| `lib/reactons/ directory exists` | Conventional reacton directory is present |
| `test/ directory exists` | Test directory is present |

### Example Output

```
$ reacton doctor

Reacton Doctor
========================================

  [OK] pubspec.yaml exists
  [OK] Reacton dependency found
  [OK] reacton_test dev dependency
  [!!] ReactonScope in main.dart
  [OK] lib/reactons/ directory exists
  [OK] test/ directory exists

Found 1 issue(s). Fix them for optimal Reacton usage.
```

When all checks pass:

```
No issues found! Your Reacton setup looks good.
```

---

## reacton analyze

Analyze reactons for dead code, circular dependencies, naming issues, and complexity problems.

### Usage

```bash
reacton analyze [--fix] [--format text|json]
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--fix` | `false` | Auto-fix simple issues (removes unused imports for dead reactons) |
| `--format` | `text` | Output format: `text` or `json` |

### Analysis Checks

#### Dead Reactons (Warning)

Detects reactons that are declared but never referenced in any file (not used in `read()`, `watch()`, or passed as an argument).

```
[WARN] Dead reacton: unusedReacton (lib/reactons/unused_reacton.dart)
  -> Declared but never referenced in any other file
```

#### Circular Dependencies (Error)

Detects cycles in the computed reacton dependency graph using depth-first search.

```
[ERROR] Circular dependency detected:
  -> reactonA -> reactonB -> reactonC -> reactonA
```

#### High Complexity (Info)

Flags computed reactons that depend on more than 5 other reactons.

```
[INFO] High complexity: dashboardReacton (lib/reactons/dashboard.dart)
  -> 8 dependencies (threshold: 5)
```

#### Naming Conventions (Info)

Flags reactons that do not follow the `xxxReacton` suffix convention.

```
[INFO] Naming convention: counter (lib/reactons/counter.dart)
  -> Consider renaming to counterReacton
```

### Text Output Example

```
$ reacton analyze

Reacton Analyze
========================================

[WARN] Dead reacton: legacyConfigReacton (lib/reactons/legacy_config.dart)
  -> Declared but never referenced in any other file

[INFO] Naming convention: counter (lib/reactons/counter.dart)
  -> Consider renaming to counterReacton

[INFO] High complexity: reportReacton (lib/features/report/report_reactons.dart)
  -> 7 dependencies (threshold: 5)

========================================
Issues: 1 warning, 2 info
```

### JSON Output Example

```bash
$ reacton analyze --format json
```

```json
{
  "issues": [
    {
      "severity": "warning",
      "message": "Dead reacton: legacyConfigReacton (lib/reactons/legacy_config.dart)",
      "detail": "Declared but never referenced in any other file",
      "reacton": "legacyConfigReacton",
      "file": "lib/reactons/legacy_config.dart",
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

### Auto-Fix

The `--fix` flag currently supports:

- **Removing unused imports** for dead reactons in files that import them

```bash
$ reacton analyze --fix

  Fixed: Removed unused imports in lib/features/settings/settings_page.dart

Reacton Analyze
========================================

[WARN] Dead reacton: legacyConfigReacton (lib/reactons/legacy_config.dart)
  -> Declared but never referenced in any other file

========================================
Issues: 1 warning
```

::: warning
Auto-fix only removes imports. The dead reacton declaration file itself is not deleted. Review and remove dead files manually.
:::

---

## CI Integration

### Run All Checks in CI

```bash
# Full project health check
reacton doctor && reacton analyze --format json
```

### Fail CI on Errors

```bash
# Pipe JSON output through jq to check for errors
ERRORS=$(reacton analyze --format json | jq '.summary.errors')
if [ "$ERRORS" -gt 0 ]; then
  echo "Reacton analysis found $ERRORS error(s)"
  exit 1
fi
```

### GitHub Actions

```yaml
- name: Reacton Doctor
  run: dart run reacton_cli doctor

- name: Reacton Analyze
  run: dart run reacton_cli analyze

- name: Reacton Graph (artifact)
  run: |
    dart run reacton_cli graph --dot > graph.dot
    dot -Tpng graph.dot -o reacton_graph.png

- uses: actions/upload-artifact@v4
  with:
    name: reacton-graph
    path: reacton_graph.png
```
