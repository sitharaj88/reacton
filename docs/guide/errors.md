# Error Reference

Every error Reacton throws, organized by the exception type and where it originates. Use this page as the companion to [Troubleshooting](/guide/troubleshooting) when you hit a stack trace.

All error messages quoted below are copied verbatim from the current Reacton source. The messages are intentionally specific so you can grep for them.

[[toc]]

## Reactivity Core

### `StateError: No reacton with ref id <id>`

Thrown by `ReactonStore.getByRef(refId)` when the given ref does not exist in the store.

**Typical cause**

- You stored a `ReactonRef` from one store and tried to resolve it in another.
- The reacton was removed via `store.remove(ref)` before the read.

**Fix**

Prefer `store.get(myReacton)` over raw refs in application code. Raw refs are useful for DevTools and low-level tooling only.

## Modules

### `StateError: Module of type <T> is not installed.`

Thrown by `store.moduleOf<T>()` when the requested module type has not been installed.

**Fix**

Install modules once at app start, before any widget tries to consume them:

```dart
final store = ReactonStore();
store.installModule(AuthModule());
store.installModule(CartModule());
runApp(ReactonScope(store: store, child: const MyApp()));
```

## Forms

### `StateError: Field "<name>" not found in form "<ref>"`

Thrown when `FormReacton.field(name)` is called with a name that was never registered.

**Fix**

Register every field upfront and reference them by the exact string:

```dart
final loginForm = formReacton(fields: {
  'email':    fieldReacton(''),
  'password': fieldReacton(''),
});

loginForm.field('email'); // ok
loginForm.field('user');  // throws — not registered
```

## Collections

### `StateError: Key "<key>" not found in map reacton "<ref>"`

Thrown by `MapReacton.require(key)` when the key is absent. Use `get(key)` for a nullable read if the key may be missing.

## Queries

### `QueryCancelledException`

Thrown when a query is cancelled — either because its dependencies changed before the fetch resolved, or because the last subscriber unsubscribed during `cacheTime`.

**Fix**

Cancellation is not an error in the application sense. Do **not** surface it to the user. Check `ctx.isCancelled` at yield points inside your `queryFn`, or use `ctx.throwIfCancelled()` to bail out cleanly.

```dart
reactonQuery<User>(
  queryFn: (ctx) async {
    final profile = await api.fetchProfile();
    ctx.throwIfCancelled();         // ← bail cleanly
    final orders = await api.fetchOrders(profile.id);
    return User.merge(profile, orders);
  },
);
```

### `StateError: Query exhausted all retry attempts`

Thrown when `RetryPolicy.maxAttempts` is reached without a successful response. The underlying error is attached as the cause.

**Fix**

- Inspect the cause — the real failure is wrapped.
- Raise `maxAttempts`, or relax `shouldRetry` to retry on more error types.
- If the endpoint is known to fail for the given input, avoid running the query altogether.

## Sagas

### `SagaCancelledException`

Thrown inside a saga when the saga is cancelled. Like `QueryCancelledException`, this is a normal control flow signal, not an application error — let it propagate.

## Recording (Session Recorder)

`SessionRecorder` guards its lifecycle with `StateError` so you cannot accidentally load/pause/resume out of order.

| Message | When |
|---------|------|
| `Recording has already been stopped.`            | You called `stop()` twice. |
| `Recording is already paused.`                   | You called `pause()` while already paused. |
| `Recording is not paused.`                       | You called `resume()` without a prior `pause()`. |
| `Cannot pause: not currently playing.`           | You called `pause()` before `play()`. |
| `Cannot pause: recording has been stopped.`      | The recorder was stopped before pause. |
| `Cannot mark: recording has been stopped.`       | You tried to add a mark after `stop()`. |
| `Cannot annotate: recording has been stopped.`   | Same, for annotations. |
| `Cannot load while playing. Call stop() first.`  | You tried to swap sessions during playback. |
| `No session loaded. Call load() first.`          | You tried to play/pause before loading a session. |

**Fix**

Track the recorder state explicitly and call methods in order: `start → … mark/annotate … → stop → load → play/pause/resume`.

## Sync / Multi-Isolate

### `StateError: Cannot send on a closed InMemorySyncChannel`

Thrown when writing to a sync channel after `close()`. Re-create the channel, or gate your writes on `channel.isOpen`.

### `FormatException: Unknown SyncMessage type: <type>`

Thrown during deserialization of a sync message. You are likely mixing Reacton versions across isolates — upgrade every side to the same version.

### `FormatException: Expected a JSON object`

Thrown by the built-in JSON decoder when the payload is not a JSON object (e.g. a number or list at the top level). Check the serializer on the sending side.

## Widget Tree

### `AssertionError: No ReactonScope found in widget tree.`

Thrown by `ReactonScope.of(context)` (and the `context.watch/read/set/update` extensions) when the widget tree has no ancestor `ReactonScope`.

**Fix**

Wrap your root (or the subtree that uses Reacton) with `ReactonScope`:

```dart
runApp(ReactonScope(child: const MyApp()));
```

For tests, wrap with `ReactonScope(store: TestReactonStore(), child: …)`.

## Generic failure modes (not Reacton-specific)

A few Dart-level errors surface often while learning Reacton. They are not Reacton errors, but worth knowing.

| Error | Usually means |
|-------|---------------|
| `LateInitializationError` | You read a `late` field before assigning it — often a reacton you forgot to declare at top level. |
| `_CastError: type 'Null' is not a subtype of type '…'` | You subscribed to a nullable reacton and forgot to handle the null case. |
| `setState() called after dispose()` | Async callback fired after the widget disposed. Use `ReactonListener` or guard with `mounted`. |

## Have an error not listed here?

Open an [issue on GitHub](https://github.com/sitharaj88/reacton/issues) with the full stack trace and a minimal reproduction. If the message looks library-internal, it may be worth a more specific error type — we track that kind of polish actively.
