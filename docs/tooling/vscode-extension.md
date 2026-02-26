# VS Code Extension

The **Reacton State Management** VS Code extension provides full IDE support for Reacton projects: code lens, hover information, diagnostics, dependency graph visualization, code snippets, explorer sidebar, and widget wrapping commands.

## Installation

### From the VS Code Marketplace

1. Open VS Code
2. Go to the **Extensions** view (`Cmd+Shift+X` / `Ctrl+Shift+X`)
3. Search for **"Reacton State Management"**
4. Click **Install**

### From a VSIX File

```bash
code --install-extension reacton-vscode-0.1.0.vsix
```

### Building from Source

```bash
cd extensions/reacton_vscode
npm install
npm run compile
```

## Requirements

- **VS Code** 1.80 or later
- A **Flutter** or **Dart** project with `reacton` or `flutter_reacton` in `pubspec.yaml`

The extension activates automatically when a `pubspec.yaml` file is detected in the workspace.

---

## Code Lens

Inline annotations appear above every Reacton declaration, providing at-a-glance metadata without leaving the editor.

Each Code Lens row displays:

| Item | Description |
|------|-------------|
| **Type information** | The Reacton kind (Writable, Computed, Async, Family, Selector, Effect, or State Machine) |
| **Dependency count** | Number and names of Reactons this declaration depends on |
| **Subscriber count** | How many other Reactons subscribe to this declaration |
| **Show in Graph** | Click to open the interactive dependency graph with this Reacton highlighted |
| **Find References** | Click to find all usages of this Reacton across the workspace |

---

## Hover Information

Hovering over any Reacton name (declaration or reference) displays a rich tooltip:

| Field | Description |
|-------|-------------|
| Type | The Reacton kind (e.g., Writable Reacton, Computed Reacton) |
| Value Type | The Dart generic type parameter (e.g., `int`, `List<String>`) |
| Doc Comment | Any `///` documentation comments above the declaration |
| Dependencies | List of Reactons this declaration reads from, with their types |
| Subscribers | List of Reactons that depend on this declaration |
| File Location | Clickable link to the source file and line number |
| Graph Link | "Show in Graph" action to open the dependency graph |

---

## Diagnostics

Five built-in diagnostic rules detect common anti-patterns and potential bugs in real time. Diagnostics appear as squiggly underlines in the editor, in the Problems panel, and in the minimap.

| Code | Severity | Description |
|------|----------|-------------|
| `reacton-missing-name` | Warning | A Reacton declaration is missing the `name` parameter. Adding a name improves debugging and DevTools experience. |
| `reacton-in-build` | Error | `reacton()`, `computed()`, or `asyncReacton()` is called inside a `build()` method. This creates a new Reacton on every rebuild. |
| `reacton-circular-dependency` | Error | A circular dependency exists between two or more Reactons. Detected via iterative DFS on the full dependency graph. |
| `reacton-unused` | Hint | A Reacton is declared but never referenced. Effects are excluded from this rule. Unused Reactons are rendered with a faded style. |
| `reacton-too-many-watchers` | Information | A single `build()` method contains 3+ `context.watch()` calls. Consider combining into a `computed()` Reacton. |

---

## Dependency Graph

An interactive, canvas-based visualization of the entire Reacton dependency graph in your workspace. Open it with `Cmd+Shift+G` / `Ctrl+Shift+G` or by clicking the status bar item.

### Color Coding

| Color | Type |
|-------|------|
| Blue (`#4fc3f7`) | Writable Reacton |
| Green (`#81c784`) | Computed Reacton |
| Orange (`#ffb74d`) | Async Reacton |
| Purple (`#ce93d8`) | Family |
| Pink (`#f06292`) | Selector |
| Red (`#ef5350`) | Effect |
| Violet (`#7e57c2`) | State Machine |

### Interactions

- **Filter by type** -- Use the dropdown in the toolbar to show only a specific Reacton type
- **Search by name** -- Type in the search field to filter nodes
- **Hover** -- See a tooltip with name, type, value type, and dependencies
- **Click** -- Select a node (highlighted with a solid border)
- **Double-click** -- Navigate directly to its declaration in the editor
- **Legend** -- Color legend in the bottom-right corner

The graph automatically re-renders on file save when `reacton.autoRefreshGraph` is enabled.

---

## Snippets

The extension ships with 25 code snippets for Dart files, all using the `r` prefix.

### Reacton Declarations

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
| `rquery` | Create a Reacton query |

### Flutter Widgets

| Prefix | Description |
|--------|-------------|
| `rscope` | Wrap widget with `ReactonScope` |
| `rbuilder` | Create a `ReactonBuilder` widget |
| `rconsumer` | Create a `ReactonConsumer` widget |
| `rlistener` | Create a `ReactonListener` widget |
| `rselectorw` | Create a `ReactonSelector` widget |

### Context Extensions

| Prefix | Description |
|--------|-------------|
| `rwatch` | Watch a Reacton with `context.watch()` |
| `rread` | Read a Reacton with `context.read()` |
| `rset` | Set a Reacton value with `context.set()` |
| `rupdate` | Update a Reacton value with `context.update()` |

### Architecture and Testing

| Prefix | Description |
|--------|-------------|
| `rmiddleware` | Create a Reacton middleware class |
| `rtestsetup` | Set up a `TestReactonStore` with `setUp`/`tearDown` |
| `rawhen` | Pattern match on `AsyncValue` with `when()` |
| `rmodule` | Create a Reacton module class |
| `rform` | Create a Reacton form |
| `rstore` | Create a `ReactonStore` instance |
| `rimport` | Import `package:reacton/reacton.dart` |
| `rimportf` | Import `package:flutter_reacton/flutter_reacton.dart` |

---

## Commands and Keybindings

### Keyboard Shortcuts

| macOS | Windows/Linux | Command | Description |
|-------|---------------|---------|-------------|
| `Cmd+Shift+R` | `Ctrl+Shift+R` | Go to Reacton... | Quick picker to search and navigate to any Reacton declaration |
| `Cmd+Shift+G` | `Ctrl+Shift+G` | Show Dependency Graph | Open the interactive dependency graph panel |

### Command Palette Commands

Available from `Cmd+Shift+P` / `Ctrl+Shift+P`:

| Command | Description |
|---------|-------------|
| Reacton: Show Dependency Graph | Open the interactive dependency graph |
| Reacton: Refresh Dependency Graph | Force a full workspace re-scan and refresh |
| Reacton: Go to Reacton... | Open quick picker for all Reacton declarations |
| Reacton: Show Dependency Chain | View the full dependency chain for a selected Reacton in the Output panel |
| Reacton: Find All References | Find all usages of a specific Reacton |
| Reacton: Wrap with ReactonBuilder | Wrap selected widget code with `ReactonBuilder` |
| Reacton: Wrap with ReactonConsumer | Wrap selected widget code with `ReactonConsumer` |
| Reacton: Wrap with ReactonScope | Wrap selected widget code with `ReactonScope` |

### Context Menu

Right-click on selected code in a Dart file to access widget wrapping commands:

| Command | Wraps Selection With |
|---------|---------------------|
| Wrap with ReactonBuilder | `ReactonBuilder<Type>(reacton: ..., builder: (context, value) { ... })` |
| Wrap with ReactonConsumer | `ReactonConsumer(builder: (context, ref) { ... })` |
| Wrap with ReactonScope | `ReactonScope(store: ReactonStore(), child: ...)` |

---

## Reacton Explorer Sidebar

The **Reacton States** tree view appears in the Explorer sidebar when a Reacton project is detected.

**Features:**

- **Grouped by type** -- Reactons organized under collapsible headers: Reactons, Computed, Async, Families, Selectors, Effects, and State Machines. Each header shows a count.
- **Click to navigate** -- Click any item to open its declaration in the editor
- **Rich tooltips** -- Hover to see type, value type, file location, dependencies, subscribers, and doc comments
- **Expandable dependencies** -- Reactons with dependencies can be expanded to show sub-items, each clickable
- **Toolbar actions** -- Refresh button and graph button in the view title bar

### Status Bar

A status bar item shows:

- **Idle:** Total Reacton count (e.g., "12 Reactons")
- **Scanning:** Spinner animation with "Scanning..."
- **Click:** Opens the dependency graph
- **Tooltip:** Count breakdown by Reacton type

---

## Configuration

All settings are under the `reacton.*` namespace. Open **Settings** (`Cmd+,` / `Ctrl+,`) and search for "Reacton".

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `reacton.showCodeLens` | `boolean` | `true` | Show Code Lens annotations above Reacton declarations |
| `reacton.showDiagnostics` | `boolean` | `true` | Show diagnostics for common anti-patterns |
| `reacton.showStatusBar` | `boolean` | `true` | Show the Reacton count in the status bar |
| `reacton.autoRefreshGraph` | `boolean` | `true` | Auto-refresh the dependency graph and explorer on file save |
| `reacton.graphLayout` | `string` | `"hierarchical"` | Layout algorithm: `"hierarchical"` or `"force-directed"` |

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

## What's Next

- [DevTools](./devtools) -- Runtime debugging from Flutter DevTools
- [CLI](./cli) -- Command-line tools for Reacton
- [Lint Rules](./lint-rules) -- Analysis-time lint rules
