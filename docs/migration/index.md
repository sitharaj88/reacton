# Migration Overview

Guides for migrating to Reacton from other Flutter state management libraries. Each guide provides side-by-side comparisons of concepts, APIs, and code patterns.

## Available Guides

| From | Guide | Key Differences |
|------|-------|-----------------|
| **Riverpod** | [From Riverpod](./from-riverpod) | Providers become top-level `reacton()` calls; `ref.watch` becomes `context.watch()`; no provider wrappers needed |
| **BLoC** | [From BLoC](./from-bloc) | Bloc classes become `stateMachine()` or `reacton()` + `computed()`; events become direct `set()`/`update()` calls; `BlocBuilder` becomes `context.watch()` |
| **Provider** | [From Provider](./from-provider) | `ChangeNotifier` is replaced by immutable reacton values; `Provider.of` becomes `context.watch()`/`context.read()`; `MultiProvider` becomes a single `ReactonScope` |

## General Migration Strategy

1. **Start small** -- Pick one feature or screen to migrate first
2. **Keep both running** -- Reacton can coexist with other state management libraries during migration
3. **Top-level declarations** -- Reacton state is declared at the top level, not inside classes or provider scopes
4. **Immutable values** -- Reacton works with plain Dart values, not mutable objects
5. **Test as you go** -- Reacton's testing tools make it easy to verify each migrated piece

## What's Next

- [From Riverpod](./from-riverpod) -- If you are coming from Riverpod
- [From BLoC](./from-bloc) -- If you are coming from BLoC
- [From Provider](./from-provider) -- If you are coming from Provider
