# Cookbook

Practical, end-to-end examples that demonstrate Reacton patterns for common application scenarios. Each recipe includes complete, runnable code with line-by-line explanations.

## Recipes

| Recipe | Difficulty | Concepts |
|--------|------------|----------|
| [Counter App](./counter) | Beginner | `reacton()`, `computed()`, `context.watch()`, `context.update()`, `ReactonScope` |
| [Todo App](./todo-app) | Intermediate | CRUD operations, filtering, computed counts, `ReactonConsumer` |
| [Authentication](./authentication) | Intermediate | `stateMachine()`, typed states and events, guard functions, async transitions |
| [Form Validation](./form-validation) | Intermediate | `FormReacton`, `FieldReacton`, validators, async validation, form submission |
| [Search with Debounce](./search-with-debounce) | Intermediate | `Debouncer`, `reactonQuery`, `computed`, `AsyncValue` pattern matching |
| [Shopping Cart](./shopping-cart) | Intermediate | `ReactonModule`, `PersistenceMiddleware`, `computed` chains, `store.optimistic` |
| [Pagination](./pagination) | Advanced | `QueryReacton`, paginated fetching, infinite scroll, stale-while-revalidate |
| [Offline-First](./offline-first) | Advanced | Persistence, optimistic updates, `StorageAdapter`, `Serializer`, sync with server |
| [Multi-Step Wizard](./multi-step-wizard) | Advanced | `stateMachine`, `reactonField`, `store.enableHistory`, `store.createBranch` |
| [Real-Time Chat](./real-time-chat) | Advanced | `saga`, `reactonList`, typing indicators, connection management |
| [Analytics Dashboard](./dashboard) | Advanced | `selector`, `lens`, `reactonQuery` with polling, `computed` aggregations |

## What's Next

Start with the [Counter App](./counter) to learn the basics, then progress through the recipes in order.
