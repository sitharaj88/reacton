## 0.2.0

- New: `ReactonSuspense<T>` — unwraps an `AsyncValue<T>` reacton so builders receive `T` directly. Supports stale-while-revalidate via `keepPreviousData`.
- New: `ReactonErrorBoundary` — groups multiple async reactons under one loading/error surface with a `reset` callback for retry.
- Bump: `reacton: ^0.2.0`.

## 0.1.2

- Maintenance release with version bump

## 0.1.1

- Add example file for pub.dev scoring
- Update dependencies to latest compatible versions
- Fix static analysis warnings in documentation comments

## 0.1.0

- Initial release
