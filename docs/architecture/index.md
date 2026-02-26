# Architecture Overview

Good architecture is what separates a prototype from a production application. This section of the documentation covers how to structure Reacton applications that are maintainable, performant, and ready to scale from a solo developer to a large engineering organization.

## Why Architecture Matters in State Management

State management is the backbone of every non-trivial application. Get it wrong and you end up with:

- **Spaghetti dependencies** -- widgets reaching into unrelated state, making it impossible to reason about what changes when
- **Performance cliffs** -- a single state change triggering hundreds of unnecessary widget rebuilds
- **Testing nightmares** -- state so entangled with UI code that unit testing becomes impractical
- **Onboarding friction** -- new team members unable to understand where state lives or how it flows

Reacton's fine-grained reactive graph solves the _technical_ side of these problems, but architecture solves the _organizational_ side. You still need to decide where to put your reactons, how to group them, and how they interact with your data layer.

## Reacton's Architectural Philosophy

Reacton does not prescribe a single "correct" architecture. Instead, it provides a set of composable primitives that work well with many architectural styles. That said, Reacton's design encourages several principles:

### 1. Declarative Over Imperative

State relationships are declared, not manually orchestrated. A computed reacton declares _what_ it derives; the engine handles _when_ it recomputes. This eliminates an entire class of bugs related to stale state and out-of-order updates.

### 2. Fine-Grained Over Coarse-Grained

Each reacton is a small, focused unit of state. Widgets subscribe to exactly the state they need. This gives you surgical precision in controlling rebuilds, which is critical for smooth 60fps Flutter apps.

### 3. Separation of Concerns

State logic (reactons, computed values, effects) is separate from UI code (widgets). This makes state testable in isolation and reusable across different widget trees.

### 4. Progressive Complexity

You start with simple reactons and adopt advanced patterns (modules, sagas, CRDT) only when your problem demands it. The underlying graph engine is the same at every level of complexity.

## The Three Architectural Tiers

As your application grows, your architecture should evolve through three tiers:

### Tier 1: Simple (1-5 screens, solo developer)

```
lib/
  state/
    counter_state.dart       # Top-level reactons
    theme_state.dart
  widgets/
    counter_page.dart
    settings_page.dart
  main.dart
```

At this tier, top-level reacton declarations in a `state/` directory are sufficient. No modules, no complex patterns. The reactive graph handles dependencies automatically.

**Key APIs:** `reacton()`, `computed()`, `context.watch()`, `store.set()`

### Tier 2: Modular (5-20 screens, small team)

```
lib/
  features/
    auth/
      auth_state.dart        # Feature-scoped reactons
      auth_service.dart
      login_page.dart
    cart/
      cart_module.dart        # ReactonModule for lifecycle
      cart_state.dart
      cart_page.dart
  shared/
    api/
      api_client.dart
    state/
      app_state.dart         # Cross-cutting state
  main.dart
```

At this tier, state is organized by feature domain. `ReactonModule` provides lifecycle management and namespace isolation. Shared state that crosses feature boundaries lives in a `shared/` directory.

**Key APIs:** `ReactonModule`, `family()`, `asyncReacton`, `selector()`

### Tier 3: Enterprise (20+ screens, multiple teams)

```
packages/
  core/                      # Shared reacton primitives, middleware
  auth/                      # Auth domain package
  cart/                      # Cart domain package
  analytics/                 # Analytics package with effects
app/
  lib/
    app.dart                 # Composes packages
    routing/
```

At this tier, domain modules become separate Dart packages with explicit dependency boundaries. Teams own packages independently. CRDT sync, sagas, and state branching come into play for complex requirements.

**Key APIs:** `saga()`, `StateBranch`, `collaborativeReacton()`, `Interceptor`

## Architecture Decision Records

When working with a team, document your architectural decisions. Here are common questions that arise in Reacton projects:

| Decision | Options | Recommendation |
|---|---|---|
| Where do reactons live? | Top-level, in modules, in packages | Start top-level, migrate to modules when you have 20+ reactons |
| How do features communicate? | Shared reactons, effects, sagas | Shared computed reactons for data flow; sagas for workflows |
| How is async data fetched? | `asyncReacton`, `QueryReacton`, effects | `QueryReacton` for standard CRUD; sagas for complex flows |
| How is state tested? | `TestReactonStore`, `MockReacton` | Always test state logic independently from widgets |
| How are errors handled? | `AsyncValue.error`, middleware, effects | Middleware for global error logging; `AsyncValue` for per-query errors |

## What's in This Section

| Page | What You'll Learn |
|---|---|
| [Project Structure](/architecture/project-structure) | Recommended directory layouts for small, medium, and large apps |
| [Common Patterns](/architecture/patterns) | Repository pattern, service layer, DI, event bus, CQRS, and more |
| [Performance](/architecture/performance) | Selectors vs computed, batching, memory management, profiling |
| [Debugging](/architecture/debugging) | LoggingMiddleware, ActionLog, DevTools, snapshot comparison |
| [Scaling to Enterprise](/architecture/scaling) | Module boundaries, scoped stores, multi-package monorepos, CRDT |

## Quick Reference: Choosing the Right Primitive

When designing your architecture, this table helps you pick the right Reacton primitive for each concern:

| Concern | Primitive | Why |
|---|---|---|
| Mutable application state | `reacton()` | The fundamental writable unit |
| Derived/computed values | `computed()` | Automatically tracks and updates dependencies |
| Sub-value from complex state | `selector()` | Prevents unnecessary rebuilds |
| Parameterized state (per-ID) | `family()` | Creates and caches instances per argument |
| Async data loading | `asyncReacton` / `QueryReacton` | Built-in loading/error/data lifecycle |
| Side effects (logging, analytics) | `createEffect()` | Runs when dependencies change |
| Complex async workflows | `saga()` | Cancellation, concurrency patterns |
| Cross-cutting concerns | `Middleware` | Logging, validation, persistence |
| Nested state access | `lens()` | Bidirectional, composable focus |
| Grouped feature state | `ReactonModule` | Lifecycle, namespacing, clean uninstall |
| Speculative/preview changes | `StateBranch` | Isolated overlay, merge when ready |
| Distributed state | `collaborativeReacton()` | CRDT-based sync across devices |
| Time-travel debugging | `History` | Undo/redo with full audit trail |
