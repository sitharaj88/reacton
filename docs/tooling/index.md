# Tooling Overview

Reacton provides a comprehensive developer tooling ecosystem that covers every stage of development -- from project scaffolding to runtime debugging.

## Tooling Packages

| Tool | Package / Extension | Description |
|------|---------------------|-------------|
| **CLI** | `reacton_cli` | Command-line tool for project initialization, code scaffolding, dependency graph analysis, and diagnostics |
| **Code Generation** | `reacton_generator` | Build runner generators for serializers and static graph analysis |
| **Lint Rules** | `reacton_lint` | Custom lint rules that catch common Reacton anti-patterns |
| **DevTools** | `reacton_devtools` | Flutter DevTools extension with graph visualization, inspector, timeline, and performance tabs |
| **VS Code Extension** | `reacton-vscode` | Full IDE support with code lens, hover info, diagnostics, dependency graph, snippets, and explorer sidebar |

## Quick Links

- [CLI](./cli) -- `reacton init`, `reacton create`, `reacton graph`, `reacton doctor`, `reacton analyze`
- [Code Generation](./code-generation) -- Annotations and build_runner integration
- [Lint Rules](./lint-rules) -- Three built-in rules for Reacton best practices
- [DevTools](./devtools) -- Runtime graph visualization, inspector, and performance monitoring
- [VS Code Extension](./vscode-extension) -- IDE-level code intelligence, diagnostics, and snippets

## What's Next

- [CLI](./cli) -- Start by setting up a project with the CLI
- [Lint Rules](./lint-rules) -- Add lint rules to your `analysis_options.yaml`
- [DevTools](./devtools) -- Set up runtime debugging
