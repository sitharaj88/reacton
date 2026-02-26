# Changelog

Version history for all Reacton packages. All packages in the monorepo share the same version number.

**Packages:** `reacton`, `flutter_reacton`, `reacton_test`, `reacton_cli`, `reacton_devtools`, `reacton_generator`, `reacton_lint`

---

## 0.1.2

_February 26, 2026_

Maintenance release focused on pub.dev compatibility and dependency hygiene.

### All Packages
- Bumped version to 0.1.2 across all packages
- Updated `reacton_devtools` dependency constraints for compatibility with latest DevTools SDK

### reacton_devtools
- Updated DevTools extension dependency constraints
- Fixed compatibility with latest `devtools_extensions` package

### How to Upgrade

```yaml
# pubspec.yaml
dependencies:
  flutter_reacton: ^0.1.2

dev_dependencies:
  reacton_test: ^0.1.2
  reacton_lint: ^0.1.2
```

Then run:

```bash
flutter pub upgrade
```

---

## 0.1.1

_February 26, 2026_

Quality improvements targeting pub.dev static analysis scores and documentation.

### All Packages
- Added `example/` files to all packages for pub.dev example tab
- Updated dependency constraints for tighter version pinning
- Fixed static analysis warnings reported by `dart analyze`
- Improved package descriptions in `pubspec.yaml`

### reacton_generator
- **Bug fix:** Added missing `glob` dependency that caused `build_runner` failures
  - Previously, running `dart run build_runner build` would fail with `Could not find package "glob"` if the host project did not depend on `glob` directly
  - The `glob` package is now listed as a direct dependency of `reacton_generator`

### reacton_lint
- Fixed lint rule registration for compatibility with `custom_lint` runner
- Ensured all three lint rules (`avoid_reacton_in_build`, `prefer_named_reacton`, `unnecessary_reacton_rebuild`) are properly discovered by the analysis server

---

## 0.1.0

_February 26, 2026_

Initial public release of the Reacton state management library for Flutter and Dart. This release includes the full feature set across seven packages.

### reacton (Core Library)

The foundational reactive primitives, usable in any Dart project (no Flutter dependency).

**Reactive Primitives:**
- `reacton<T>(initial, {name, options})` -- writable reactive state atoms
- `computed<T>((read) => ...)` -- automatically-tracked derived state that recomputes only when dependencies change
- `selector<T, S>(source, (value) => ...)` -- sub-state selection with customizable equality checks to prevent unnecessary downstream propagation
- `family<T, Arg>((arg) => ...)` -- parameterized reacton factories that create or retrieve cached instances based on an argument
- `createEffect((read) => ..., effect: ...)` -- reactive side effects that re-run when tracked dependencies change

**Store and Graph:**
- `ReactonStore` -- centralized store that manages the reactive dependency graph, value storage, subscriptions, and batch processing
- `store.batch(() { ... })` -- coalesce multiple writes into a single propagation pass for efficiency
- `store.snapshot()` / `store.restore(snapshot)` -- capture and restore the entire store state

**Async:**
- `AsyncValue<T>` -- algebraic data type representing loading, data, or error states with `when()` pattern matching
- `asyncReacton<T>((read) async => ...)` -- declarative async data fetching that automatically tracks dependencies and manages loading/error states
- `QueryReacton` -- query-style async reactons with built-in caching, stale-while-revalidate, and manual refetch
- `RetryPolicy` -- configurable retry logic with exponential backoff, max attempts, and retry-on predicates
- `OptimisticUpdate` -- apply changes optimistically with automatic rollback on failure
- `Debouncer` -- delay execution until a quiet period elapses (useful for search-as-you-type)
- `Throttler` -- limit execution frequency to at most once per interval

**Middleware:**
- `ReactonMiddleware` interface for intercepting all state reads and writes
- Built-in `LoggingMiddleware` for development debugging
- Middleware chain is composable: multiple middleware run in order

**Persistence:**
- `StorageAdapter` interface with `read`, `write`, `delete`, `clear`, `containsKey`
- `ReactonOptions.persistKey` -- opt-in persistence per reacton
- `PrimitiveSerializer<T>` for simple types (int, double, bool, String)
- Pluggable serializers for complex types via `ReactonSerializer<T>`

**Time and Space:**
- `HistoryReacton` -- undo/redo with configurable maximum history depth
- `StateBranch` -- create branches of state for speculative edits, then merge or discard
- Snapshot diffs for efficient state comparison

**State Patterns:**
- `StateMachine<State, Event>` -- declarative state machines with typed events, a transition table, and guard functions
- `ObservableList<T>`, `ObservableMap<K, V>`, `ObservableSet<T>` -- reactive collections that notify on add, remove, and update
- `Lens<S, A>` -- composable optics for reading and updating deeply nested immutable state without boilerplate

**Architecture:**
- `ReactonModule` -- module system for grouping related reactons with `onInit` and `onDispose` lifecycle hooks
- Saga system for orchestrating multi-step async workflows with cancellation, retry, and compensation
- CRDT (Conflict-free Replicated Data Type) support for collaborative, distributed state synchronization

### flutter_reacton (Flutter Integration)

Flutter-specific bindings built on the core `reacton` package.

**Scope:**
- `ReactonScope` -- widget that provides a `ReactonStore` to the widget tree; every Reacton app needs one at the root
- `ReactonOverride` -- override reacton values in nested scopes for dependency injection or testing

**Widget Builders:**
- `ReactonBuilder<T>` -- single-reacton builder that rebuilds when the watched reacton changes
- `ReactonConsumer` -- multi-reacton consumer widget with a builder callback
- `ReactonListener<T>` -- side-effect listener that does not rebuild the child; useful for navigation, snackbars, and analytics
- `ReactonSelector<T, S>` -- widget that extracts a slice of a reacton value and only rebuilds when the slice changes

**Context Extensions:**
- `context.watch(reacton)` -- subscribe to a reacton and rebuild on every change
- `context.read(reacton)` -- one-time read without subscribing (for callbacks and event handlers)
- `context.set(reacton, value)` -- write a new value to a writable reacton
- `context.update(reacton, (old) => newValue)` -- functional update that receives the current value

**Lifecycle:**
- Auto-dispose support for reactons scoped to a widget subtree
- Proper cleanup of subscriptions when widgets unmount

### reacton_test (Testing Utilities)

A dedicated testing package for writing fast, deterministic tests.

**Test Store:**
- `TestReactonStore` -- isolated store with in-memory storage that resets between tests
- `ReactonTestOverride<T>` -- override a writable reacton's initial value
- `AsyncReactonTestOverride<T>` -- override async reactons with `.data(value)`, `.loading()`, or `.error(exception)`

**Storage:**
- `MemoryStorage` -- in-memory implementation of `StorageAdapter` for testing persistence without the filesystem

**Mocking and Tracking:**
- `MockReacton<T>` -- mock reacton for verifying read/write interactions
- `EffectTracker` -- capture side effects fired by `createEffect` and assert on them
- `GraphAssertion` -- assert the structure of the reactive dependency graph (node existence, edge connections)

**Widget Test Helpers:**
- `pumpReactonWidget(tester, widget, {overrides})` -- convenience helper that wraps a widget in `ReactonScope` and pumps it
- `store.expectReacton(reacton, matcher)` -- fluent assertion shorthand
- `store.waitFor(asyncReacton)` -- await an async reacton until it resolves or errors

### reacton_cli (Command-Line Interface)

Project scaffolding, analysis, and diagnostics from the terminal.

**Commands:**
- `reacton init` -- add Reacton dependencies to `pubspec.yaml`, create `lib/reactons/`, scaffold starter files, and configure `analysis_options.yaml`
- `reacton create reacton <name>` -- generate a writable reacton file from a template
- `reacton create computed <name>` -- generate a computed reacton file
- `reacton create async <name>` -- generate an async reacton file
- `reacton create selector <name>` -- generate a selector reacton file
- `reacton create family <name>` -- generate a reacton family file
- `reacton create feature <name>` -- generate a full feature module (reactons file, page widget, test file)
- `reacton graph` -- scan `lib/` and print the dependency graph in text or DOT (Graphviz) format
- `reacton doctor` -- check project health (dependencies, `ReactonScope` presence, directory structure)
- `reacton analyze` -- detect dead reactons, circular dependencies, high complexity, and naming convention violations; supports `--fix` for auto-fixing and `--format json` for CI integration

See the [CLI API Reference](/api/reacton-cli) for full command documentation with flags, options, and example output.

### reacton_devtools (DevTools Extension)

A Dart DevTools extension for runtime inspection.

**Setup:**
- `ReactonDevToolsExtension.install(store)` -- register all service extensions for a store

**DevTools Panels:**
- **Graph View** -- live visualization of the reactive dependency graph with node types, levels, and subscriber counts
- **Inspector** -- browse all reactons, view current values, and edit writable reacton values live
- **Timeline** -- chronological log of all state changes with old/new values, timestamps, and propagation timing (ring buffer of 500 entries)
- **Performance** -- per-reacton metrics including recompute count, average propagation time, and subscriber count

**Service Extensions:**
- `ext.reacton.getGraph` -- fetch the full dependency graph
- `ext.reacton.getReactonValue` -- read a specific reacton value
- `ext.reacton.setReactonValue` -- write a value for live debugging
- `ext.reacton.getReactonList` -- list all reactons with metadata
- `ext.reacton.getStats` -- store-level statistics
- `ext.reacton.getTimeline` -- state change history (supports incremental fetch)
- `ext.reacton.clearTimeline` -- clear history and optionally pause/resume capture
- `ext.reacton.getPerformance` -- per-reacton performance data

**Client Library:**
- `ReactonDevToolsService` -- typed client for calling service extensions from custom tools
- Data classes: `GraphData`, `GraphNodeData`, `GraphEdgeData`, `ReactonValueData`, `ReactonListEntry`, `StoreStats`, `TimelineData`, `TimelineEntryData`, `PerformanceEntry`

See the [DevTools API Reference](/api/reacton-devtools) for full documentation.

### reacton_generator (Code Generation)

Optional code generation for serialization and immutable state classes.

- `@ReactonSerializable()` annotation for marking state classes
- Generates `toJson()` and `fromJson()` factory constructor for use with persistence
- Generates `copyWith()` for immutable state updates
- Compatible with `build_runner`: run `dart run build_runner build` to generate
- Generated files use the `.g.dart` part file convention

### reacton_lint (Lint Rules)

Custom lint rules that catch common mistakes at analysis time.

| Rule | Severity | Description |
|------|----------|-------------|
| `avoid_reacton_in_build` | Warning | Warns when `reacton()`, `computed()`, or `asyncReacton()` is called inside a `build()` method, which creates a new reacton on every rebuild |
| `prefer_named_reacton` | Info | Suggests adding a `name` parameter to reacton declarations for better DevTools and logging output |
| `unnecessary_reacton_rebuild` | Warning | Detects widgets that call `context.watch(reacton)` but never use the returned value, causing unnecessary rebuilds |

Integration:
- Uses the `custom_lint` package for IDE and CI support
- Add `custom_lint` to `analysis_options.yaml` plugins (done automatically by `reacton init`)
- Lint rules run in the IDE (VS Code, IntelliJ) and during `dart analyze`
