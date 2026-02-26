# Advanced Features

Reacton's core is intentionally small -- `reacton()`, `computed()`, `watch()`, `set()`. But when your application grows, Reacton scales with you through a set of opt-in advanced features that cover enterprise-grade requirements.

## Feature Overview

| Feature | Description | Use Case |
|---------|-------------|----------|
| [Middleware](/advanced/middleware) | Intercept reacton lifecycle events (init, read, write, dispose) | Logging, validation, analytics, persistence |
| [Persistence](/advanced/persistence) | Auto-persist reacton values to storage | User preferences, auth tokens, cached data |
| [History](/advanced/history) | Undo/redo with full action audit log | Form editing, drawing apps, time-travel debugging |
| [State Branching](/advanced/branching) | Git-like branching for state | Form preview, A/B testing, speculative updates |
| [State Machines](/advanced/state-machines) | Typed state/event transitions with guards | Auth flows, wizards, complex workflows |
| [Modules](/advanced/modules) | Group related reactons with lifecycle management | Feature isolation, team boundaries, lazy loading |
| [Observable Collections](/advanced/collections) | Reactive lists and maps with granular change events | Todo lists, user directories, inventories |
| [Multi-Isolate](/advanced/isolates) | Share state across Dart isolates | Heavy computation, background processing |

## Progressive Complexity

You do not need to use any of these features to build a great app with Reacton. They are additive -- adopt them one at a time as your requirements demand.

```
Level 1: reacton() + computed() + watch()           ← 80% of apps
Level 2: effects, selectors, async reactons          ← derived state, API calls
Level 3: middleware, persistence, history, branching  ← enterprise features
```

## What's Next

- [Middleware](/advanced/middleware) -- Intercept and transform reacton operations
- [Persistence](/advanced/persistence) -- Auto-save state to disk
- [History](/advanced/history) -- Add undo/redo to any reacton
