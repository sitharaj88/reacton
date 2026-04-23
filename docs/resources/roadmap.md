# Roadmap

A forward look at what the Reacton team is working on, what is being considered, and what has been intentionally left out. Nothing here is a promise — priorities shift as we learn from real-world usage. Track concrete progress in the [GitHub issues](https://github.com/sitharaj88/reacton/issues) and [release notes](/resources/changelog).

## Versioning philosophy

- **0.x** — iterate quickly. Breaking changes are allowed between minor versions but always come with a [migration guide](/migration/).
- **1.0** — API surface is frozen for the core (`reacton`, `flutter_reacton`, `reacton_test`). Minor versions add capabilities without breaking callers.
- **2.0+** — reserved for fundamental architectural shifts. We do not expect one for the foreseeable future.

## Where we are today — 0.1.x

Reacton 0.1.2 ships with:

- A stable reactive graph engine with two-phase glitch-free propagation.
- The Level 1 primitives (`reacton`, `computed`, `effect`, `watch`, `set`, `update`).
- Level 2 features: selectors, families, async + query, optimistic updates, retry.
- Level 3 features: state machines, branching, time travel, middleware, persistence, CRDT, sagas, multi-isolate, session recording.
- The full tooling ecosystem: CLI, DevTools extension, lint rules, VS Code extension, code generator, first-class testing utilities.
- Migration guides for Riverpod, BLoC, Provider, and GetX.
- Twelve cookbook recipes from counter to analytics dashboard.

The public API surface is stable enough to adopt for new projects. Breaking changes, if any, will be small and well-signposted.

## Recently landed (unreleased, next: 0.2.0)

Two additive features merged and tested — awaiting a release tag.

| Feature | What it does |
|---------|--------------|
| **`ReactonSuspense` + `ReactonErrorBoundary`** | Declarative async UI — unwrap a single `AsyncValue` reacton, or group several under one retry-capable boundary. See the [Suspense guide](/flutter/suspense). |
| **Persistence migrations** | `VersionedJsonSerializer<T>` embeds a schema version and runs ordered migrations on load. See the [migrations guide](/advanced/migrations). |

## In progress

These are actively being worked on for an upcoming release.

| Area | What's happening |
|------|------------------|
| **DevTools UX** | Performance flame graphs, inspector filters, timeline annotations for marks emitted from user code. |
| **Benchmarks page** | Reproducible benchmarks comparing Reacton to Riverpod, BLoC, and Provider on rebuild latency, memory footprint, and startup cost. |
| **Hot reload friendliness** | Investigating preservation of writable reacton values across hot reloads (today they reset with the store). |
| **Deeper VS Code integration** | Expand to inline dependency graph hover previews and quick-fixes for lint rules. |
| **Generator ergonomics** | Shorter annotation surface, better error messages from `build_runner`. |

## Being considered

Ideas we're discussing. Open a discussion or thumbs-up an existing one to influence priority.

- **React / web bindings.** The core is pure Dart; a thin bridge for Flutter web or JS via `dart2js`/`dart2wasm` is feasible and has come up more than once.
- **React Native / SwiftUI bridges.** Less likely — the reactive primitives translate, but the idiomatic integration surface is very different.
- **Built-in GraphQL query adapter.** Today you wrap GraphQL calls yourself inside a `reactonQuery`. A first-class adapter could simplify cache invalidation.
- **Structured concurrency helpers.** `reactonCancelScope`, cooperative cancellation DSL layered on top of `QueryCancelledException`.
- **Server-sent events / WebSocket reacton.** A typed `streamReacton` that mirrors `asyncReacton` but emits each event.
- **Redux-style devtools bridge.** Action log export, replay by ID, integration with the Redux DevTools browser extension.

## On the 1.0 path

These are the things we want to nail before 1.0.

1. **Stable DevTools extension.** Covers every feature in the core with a tested UI.
2. **Two quarters of production soak time.** No surprise API changes for 6+ months.
3. **Complete benchmarks.** Reproducible, independently verifiable numbers.
4. **Five real production case studies.** Not just our own — community apps in different domains (consumer, enterprise, offline-first, real-time).
5. **Full lint + codegen hardening.** No false positives, clear auto-fix suggestions.
6. **First-class docs for every public API.** Every method has a doc comment; every doc comment is covered by an example in the docs.

## Explicitly not doing

- **We will not ship a global-store convention.** Reacton encourages top-level reactons and modules; we will not add a `GetIt`-style service locator to the core.
- **We will not ship a router.** There are excellent routers in the ecosystem. Reacton integrates with any of them.
- **We will not add mutable reacton fields.** Values are immutable snapshots, updated via `set`/`update`. Observable collections fill the "mutate in place" use case.
- **We will not add code generation as a requirement.** The library is fully usable without `build_runner`, and will stay that way.

## How to influence the roadmap

- Open an [issue](https://github.com/sitharaj88/reacton/issues) for concrete bugs or proposals.
- Start a [discussion](https://github.com/sitharaj88/reacton/discussions) for open-ended ideas.
- Ship a PR — nothing moves a feature forward faster than a working prototype.

The team reads every issue. Even a "+1" on an existing one helps us prioritize.
