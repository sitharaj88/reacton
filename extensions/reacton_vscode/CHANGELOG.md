# Changelog

All notable changes to the **Reacton** VS Code extension. The extension follows
its own versioning track, independent of the Reacton Dart/Flutter packages.

## 0.2.0

Aligned the extension track to Reacton **0.2.0** and refreshed snippets for the
new widgets that landed in that release.

### Added

- Snippets for `ReactonSuspense<T>` and `ReactonErrorBoundary` — including
  single-reacton and multi-reacton variants.
- Snippet for `VersionedJsonSerializer<T>` persistence migrations.
- Marketplace metadata polish: repository/homepage/bugs links, MIT license
  manifest, normalized keywords.
- Publishing tooling: `vsce` as a dev dependency, `package` and `publish`
  scripts, hardened `.vscodeignore` so tests and source maps stay out of the
  shipped bundle.

### Changed

- Bumped the VS Code engine minimum to `^1.80.0` (no behavioral change).

## 0.1.0

Initial release.

- Code lens on every reacton declaration (type, dependency count, graph link).
- Hover info for reactons, computed values, effects, and context extensions.
- Diagnostics for classic mistakes (`atom`/`asyncAtom` old-API references,
  reacton in `build()`, `context.read()` in `build()`, missing names).
- Explorer tree view: every reacton in the workspace grouped by file.
- Dependency graph webview (hierarchical and force-directed layouts).
- Commands: go to reacton, show graph, refresh graph, wrap with Builder /
  Consumer / Scope, find all references.
- Snippets for every core primitive: `reacton`, `computed`, `effect`,
  `selector`, `asyncReacton`, `reactonQuery`, `stateMachine`, and more.
- Configuration: code lens, diagnostics, status bar, auto-refresh, graph layout.
