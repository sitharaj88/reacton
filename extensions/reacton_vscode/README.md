# Reacton State Management for VS Code

**Full-featured IDE support for the Reacton reactive state management library for Flutter and Dart.**

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://marketplace.visualstudio.com/items?itemName=sitharaj.reacton-vscode)
[![VS Code Marketplace](https://img.shields.io/badge/VS%20Code-Marketplace-007ACC.svg)](https://marketplace.visualstudio.com/items?itemName=sitharaj.reacton-vscode)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Table of Contents

- [Features](#features)
  - [Code Intelligence](#code-intelligence)
  - [Diagnostics](#diagnostics)
  - [Dependency Graph](#dependency-graph)
  - [Explorer Sidebar](#explorer-sidebar)
  - [Widget Wrapping](#widget-wrapping)
  - [Quick Navigation](#quick-navigation)
  - [Status Bar](#status-bar)
  - [Code Snippets](#code-snippets)
- [Supported Reacton Types](#supported-reacton-types)
- [Configuration](#configuration)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Requirements](#requirements)
- [Installation](#installation)
- [Contributing](#contributing)
- [License](#license)

---

## Features

### Code Intelligence

The extension provides rich code intelligence features that integrate directly into the VS Code editing experience.

#### Code Lens

Inline annotations appear above every Reacton declaration, providing at-a-glance metadata without leaving the editor.

Each Code Lens row displays:

- **Type information** -- the Reacton kind (Writable, Computed, Async, Family, Selector, Effect, or State Machine)
- **Dependency count** -- the number and names of Reactons this declaration depends on
- **Subscriber count** -- how many other Reactons subscribe to this declaration
- **Show in Graph** -- click to open the interactive dependency graph with this Reacton highlighted
- **Find References** -- click to find all usages of this Reacton across the workspace

#### Hover Information

Hovering over any Reacton name (declaration or reference) displays a rich tooltip containing:

| Field | Description |
|-------|-------------|
| Type | The Reacton kind (e.g., Writable Reacton, Computed Reacton) |
| Value Type | The Dart generic type parameter (e.g., `int`, `List<String>`) |
| Doc Comment | Any `///` documentation comments above the declaration |
| Dependencies | List of Reactons this declaration reads from, with their types |
| Subscribers | List of Reactons that depend on this declaration |
| File Location | Clickable link to the source file and line number |
| Graph Link | "Show in Graph" action to open the dependency graph |

#### Go to Definition

Jump from any Reacton reference directly to its declaration. Press `F12` or `Ctrl+Click` (`Cmd+Click` on macOS) on a Reacton name to navigate to where it is defined.

#### Find All References

Locate every usage of a Reacton across the entire workspace. Press `Shift+F12` on a Reacton name or use the Code Lens "Find References" action. The provider scans all Dart files using word-boundary matching to avoid false positives from partial name matches.

#### Document Symbols

Reacton declarations appear in:

- **File Outline** -- the Explorer sidebar outline panel
- **Breadcrumbs** -- the breadcrumb navigation bar at the top of the editor
- **Go to Symbol** -- press `Ctrl+Shift+O` (`Cmd+Shift+O` on macOS) to search

When a file contains multiple Reacton declarations, they are automatically grouped under a parent "Reactons" namespace for a clean outline hierarchy. Each symbol includes the Reacton type and value type in its detail field.

---

### Diagnostics

The extension includes five built-in diagnostic rules that detect common anti-patterns and potential bugs in real time. Diagnostics are displayed inline in the editor as squiggly underlines, in the Problems panel, and in the minimap.

| Code | Severity | Description |
|------|----------|-------------|
| `reacton-missing-name` | Warning | A Reacton declaration is missing the `name` parameter. Adding a name improves debugging and DevTools experience. |
| `reacton-in-build` | Error | `reacton()`, `computed()`, or `asyncReacton()` is called inside a `build()` method. This creates a new Reacton on every rebuild, which is almost certainly a bug. Declare Reactons as top-level or class-level fields instead. |
| `reacton-circular-dependency` | Error | A circular dependency exists between two or more Reactons. This will cause infinite re-evaluation at runtime. Detected via iterative DFS on the full dependency graph. |
| `reacton-unused` | Hint | A Reacton is declared but never referenced by another Reacton, `read()`, or `watch()` call. Effects are excluded from this rule since they are side-effect-only by design. Unused Reactons are rendered with a faded style. |
| `reacton-too-many-watchers` | Information | A single `build()` method contains 3 or more `context.watch()` calls. Each watcher triggers a rebuild independently, so the widget may rebuild more often than necessary. Consider combining them into a single `computed()` Reacton. |

---

### Dependency Graph

An interactive, canvas-based visualization of the entire Reacton dependency graph in your workspace. Open it with `Cmd+Shift+G` / `Ctrl+Shift+G` or by clicking the status bar item.

**Color coding by type:**

| Color | Type |
|-------|------|
| Blue (`#4fc3f7`) | Writable Reacton |
| Green (`#81c784`) | Computed Reacton |
| Orange (`#ffb74d`) | Async Reacton |
| Purple (`#ce93d8`) | Family |
| Pink (`#f06292`) | Selector |
| Red (`#ef5350`) | Effect |
| Violet (`#7e57c2`) | State Machine |

**Interactions:**

- **Filter by type** -- use the dropdown in the toolbar to show only a specific Reacton type
- **Search by name** -- type in the search field to filter nodes by name
- **Hover** -- hover over a node to see a tooltip with its name, type, value type, and dependencies
- **Click** -- click a node to select it (highlighted with a solid border)
- **Double-click** -- double-click a node to navigate directly to its declaration in the editor
- **Legend** -- a color legend in the bottom-right corner identifies each type
- **Arrowheads** -- edges include arrowheads indicating the direction of data flow (from dependency to dependent)

The graph automatically re-renders when the underlying data changes (on file save with `reacton.autoRefreshGraph` enabled).

---

### Explorer Sidebar

The **Reacton States** tree view appears in the Explorer sidebar when a Reacton project is detected.

- **Grouped by type** -- Reactons are organized under collapsible headers: Reactons, Computed, Async, Families, Selectors, Effects, and State Machines. Each header shows a count.
- **Click to navigate** -- click any item to open its declaration in the editor.
- **Rich tooltips** -- hover over an item to see its type, value type, file location, dependencies, subscribers, and documentation comments.
- **Expandable dependencies** -- Reactons with dependencies can be expanded to show their dependency sub-items, each of which is also clickable.
- **Toolbar actions** -- the view title bar includes buttons to refresh the scanner and open the dependency graph.

---

### Widget Wrapping

Right-click on selected widget code in a Dart file to access widget wrapping commands from the context menu:

| Command | Wraps selection with |
|---------|---------------------|
| **Wrap with ReactonBuilder** | `ReactonBuilder<Type>(reacton: ..., builder: (context, value) { ... })` |
| **Wrap with ReactonConsumer** | `ReactonConsumer(builder: (context, ref) { ... })` |
| **Wrap with ReactonScope** | `ReactonScope(store: ReactonStore(), child: ...)` |

These commands appear in the editor context menu when a Dart file is active and text is selected.

---

### Quick Navigation

#### Go to Reacton

Press `Cmd+Shift+R` (macOS) or `Ctrl+Shift+R` (Windows/Linux) to open a quick picker listing all Reacton declarations in the workspace. Each entry shows:

- The Reacton name with a type-specific icon
- The value type as a description
- The Reacton kind and file location as detail text

The picker supports fuzzy matching on the name, type, and file path. Select an entry to navigate directly to its declaration.

#### Show Dependency Chain

Run the **Reacton: Show Dependency Chain** command from the Command Palette. Select a Reacton from the picker, and a tree-formatted dependency chain is displayed in the Output panel. The output includes:

- The full dependency hierarchy rendered with box-drawing characters
- Each node annotated with its type and value type
- Circular references clearly marked
- Subscriber lists for each node

---

### Status Bar

A status bar item appears on the left side of the VS Code status bar.

- **Idle state** -- displays the total Reacton count (e.g., "12 Reactons")
- **Scanning state** -- shows a spinner animation with "Scanning..." while the workspace scanner is running
- **Click action** -- click the item to open the dependency graph
- **Tooltip** -- hover to see a summary table with a count breakdown by Reacton type (Writable, Computed, Async, Family, Selector, Effect, State Machine)

---

### Code Snippets

The extension ships with **25 code snippets** for Dart files, all using the `r` prefix for quick access.

#### Reacton Declarations

| Prefix | Description |
|--------|-------------|
| `rreacton` | Create a writable Reacton |
| `rcomputed` | Create a computed Reacton |
| `rcomputedm` | Create a computed Reacton with a multiline body |
| `rasync` | Create an async Reacton |
| `rfamily` | Create a Reacton family |
| `reffect` | Create a Reacton effect |
| `rselector` | Create a Reacton selector |
| `rstatemachine` | Create a Reacton state machine |
| `rquery` | Create a Reacton query atom |

#### Flutter Widgets

| Prefix | Description |
|--------|-------------|
| `rscope` | Wrap widget with `ReactonScope` |
| `rbuilder` | Create a `ReactonBuilder` widget |
| `rconsumer` | Create a `ReactonConsumer` widget |
| `rlistener` | Create a `ReactonListener` widget |
| `rselectorw` | Create a `ReactonSelector` widget |

#### Context Extensions

| Prefix | Description |
|--------|-------------|
| `rwatch` | Watch a Reacton with `context.watch()` |
| `rread` | Read a Reacton with `context.read()` |
| `rset` | Set a Reacton value with `context.set()` |
| `rupdate` | Update a Reacton value with `context.update()` |

#### Architecture and Testing

| Prefix | Description |
|--------|-------------|
| `rmiddleware` | Create a Reacton middleware class |
| `rtestsetup` | Set up a `TestReactonStore` with `setUp`/`tearDown` |
| `rawhen` | Pattern match on `AsyncValue` with `when()` |
| `rmodule` | Create a Reacton module class |
| `rform` | Create a Reacton form atom |
| `rstore` | Create a `ReactonStore` instance |
| `rimport` | Import `package:reacton/reacton.dart` |
| `rimportf` | Import `package:flutter_reacton/flutter_reacton.dart` |

---

## Supported Reacton Types

The workspace scanner detects the following seven Reacton types from Dart source files:

| Type | Declaration Pattern | Value Type | Description |
|------|---------------------|------------|-------------|
| **Writable** | `reacton<T>(...)` | `T` | A read-write reactive state container |
| **Computed** | `computed<T>((read) => ...)` | `T` | A derived value that automatically recalculates when dependencies change |
| **Async** | `asyncReacton<T>((read) async { ... })` | `T` | An asynchronous reactive value (e.g., network requests) |
| **Family** | `family<T, Arg>((arg) => ...)` | `T, Arg` | A parameterized factory that creates Reactons on demand |
| **Selector** | `selector<S, T>(source, (v) => ...)` | `S -> T` | A fine-grained projection that selects a subset of another Reacton's value |
| **Effect** | `createEffect(store, (read) { ... })` | `void` | A side-effect that runs when its dependencies change |
| **State Machine** | `stateMachine<S, E>(...)` | `S, E` | A finite state machine with typed states and events |

---

## Configuration

All settings are under the `reacton.*` namespace. Open **Settings** (`Cmd+,` / `Ctrl+,`) and search for "Reacton" to configure.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `reacton.showCodeLens` | `boolean` | `true` | Show Code Lens annotations above Reacton declarations (type info, dependency count, graph link, find references) |
| `reacton.showDiagnostics` | `boolean` | `true` | Show diagnostics for common Reacton anti-patterns (missing names, Reacton in build, circular dependencies, unused Reactons, too many watchers) |
| `reacton.showStatusBar` | `boolean` | `true` | Show the Reacton count in the status bar |
| `reacton.autoRefreshGraph` | `boolean` | `true` | Automatically refresh the dependency graph and explorer tree view when a Dart file is saved |
| `reacton.graphLayout` | `string` | `"hierarchical"` | Layout algorithm for the dependency graph visualization. Options: `"hierarchical"`, `"force-directed"` |

**Example `settings.json`:**

```json
{
  "reacton.showCodeLens": true,
  "reacton.showDiagnostics": true,
  "reacton.showStatusBar": true,
  "reacton.autoRefreshGraph": true,
  "reacton.graphLayout": "hierarchical"
}
```

---

## Keyboard Shortcuts

| Shortcut (macOS) | Shortcut (Windows/Linux) | Command | Description |
|------------------|--------------------------|---------|-------------|
| `Cmd+Shift+R` | `Ctrl+Shift+R` | Reacton: Go to Reacton... | Open the quick picker to search and navigate to any Reacton declaration |
| `Cmd+Shift+G` | `Ctrl+Shift+G` | Reacton: Show Dependency Graph | Open the interactive dependency graph panel |

Additional commands available from the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`):

| Command | Description |
|---------|-------------|
| Reacton: Refresh Dependency Graph | Force a full workspace re-scan and refresh the graph and explorer |
| Reacton: Show Dependency Chain | Select a Reacton and view its full dependency chain in the Output panel |
| Reacton: Find All References | Find all usages of a specific Reacton across the workspace |
| Reacton: Wrap with ReactonBuilder | Wrap the selected widget code with a `ReactonBuilder` |
| Reacton: Wrap with ReactonConsumer | Wrap the selected widget code with a `ReactonConsumer` |
| Reacton: Wrap with ReactonScope | Wrap the selected widget code with a `ReactonScope` |

---

## Requirements

- **VS Code** 1.80 or later
- A **Flutter** or **Dart** project with `reacton` or `flutter_reacton` listed as a dependency in `pubspec.yaml`

The extension activates automatically when a `pubspec.yaml` file is detected in the workspace. Feature-specific UI elements (explorer sidebar, context menus) appear only when the project is confirmed to depend on the Reacton library.

---

## Installation

### From the VS Code Marketplace

1. Open VS Code.
2. Go to the **Extensions** view (`Cmd+Shift+X` / `Ctrl+Shift+X`).
3. Search for **"Reacton State Management"**.
4. Click **Install**.

### From a VSIX File

If you have a `.vsix` package (e.g., from a local build or a release artifact):

1. Open VS Code.
2. Go to the **Extensions** view (`Cmd+Shift+X` / `Ctrl+Shift+X`).
3. Click the `...` menu in the top-right corner of the Extensions view.
4. Select **Install from VSIX...**.
5. Navigate to the `.vsix` file and select it.

Alternatively, install from the command line:

```bash
code --install-extension reacton-vscode-0.1.0.vsix
```

### Building from Source

```bash
cd extensions/reacton_vscode
npm install
npm run compile
```

To generate a VSIX package:

```bash
npx @vscode/vsce package
```

---

## Contributing

Contributions are welcome. Please open an issue or submit a pull request on the [GitHub repository](https://github.com/sitharaj/atomix).

When contributing, ensure the following:

1. Run `npm run lint` and resolve all lint warnings.
2. Run `npm run compile` to verify the TypeScript build succeeds.
3. Test your changes manually in the Extension Development Host (`F5`).

---

## License

This extension is released under the [MIT License](../../LICENSE).
