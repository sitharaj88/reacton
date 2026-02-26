import 'dart:async';

import '../core/reacton_base.dart';
import '../core/writable_reacton.dart';
import '../store/store.dart';

// ---------------------------------------------------------------------------
// SagaEffect — Declarative effect descriptors (sealed hierarchy)
// ---------------------------------------------------------------------------

/// A declarative description of a side effect to be performed by the saga
/// runtime.
///
/// [SagaEffect] forms a sealed hierarchy so the runtime can exhaustively
/// match on effect types. User code should not need to interact with this
/// hierarchy directly; instead use the imperative helpers on [SagaContext].
sealed class SagaEffect<T> {
  const SagaEffect();
}

/// Wait for the next event of type [E] dispatched to the saga.
///
/// The saga suspends until an event matching [E] arrives, then resumes
/// with that event as the result.
final class Take<E> extends SagaEffect<E> {
  /// Optional predicate to further filter events.
  final bool Function(E event)? predicate;

  /// Creates a [Take] effect.
  const Take({this.predicate});
}

/// Dispatch a [value] to a [WritableReacton] in the store.
///
/// This is the primary way sagas write state back into the reactive graph.
final class Put<T> extends SagaEffect<void> {
  /// The target reacton to write to.
  final WritableReacton<T> reacton;

  /// The value to set.
  final T value;

  /// Creates a [Put] effect.
  const Put(this.reacton, this.value);
}

/// Execute an asynchronous function and return its result.
///
/// The future is monitored for cancellation: if the enclosing saga task is
/// cancelled while the [Call] is pending, a [SagaCancelledException] is
/// thrown.
final class Call<T> extends SagaEffect<T> {
  /// The async function to execute.
  final Future<T> Function() fn;

  /// Creates a [Call] effect.
  const Call(this.fn);
}

/// Fork a child saga to run concurrently (non-blocking).
///
/// The parent saga continues immediately after forking; the child runs
/// independently. Cancelling the parent cascades cancellation to all
/// forked children.
final class Fork extends SagaEffect<SagaTask> {
  /// The saga handler to run as a forked child.
  final SagaHandler handler;

  /// Optional debug name for the forked task.
  final String? name;

  /// Creates a [Fork] effect.
  const Fork(this.handler, {this.name});
}

/// Wait for a previously forked [SagaTask] to complete.
///
/// If the target task was cancelled, a [SagaCancelledException] is thrown.
final class Join extends SagaEffect<dynamic> {
  /// The task to wait for.
  final SagaTask task;

  /// Creates a [Join] effect.
  const Join(this.task);
}

/// Cancel a running [SagaTask].
///
/// Cancellation cascades to all child tasks forked by the target task.
final class Cancel extends SagaEffect<void> {
  /// The task to cancel.
  final SagaTask task;

  /// Creates a [Cancel] effect.
  const Cancel(this.task);
}

/// Suspend the saga for the given [duration].
///
/// The delay is cancellable: if the saga is cancelled while delayed, a
/// [SagaCancelledException] is thrown immediately.
final class Delay extends SagaEffect<void> {
  /// How long to wait.
  final Duration duration;

  /// Creates a [Delay] effect.
  const Delay(this.duration);
}

/// Race multiple futures against each other. The first to complete wins,
/// and the others are discarded.
///
/// Returns a [Map] with a single entry whose key is the winner's key
/// and whose value is the winner's result.
final class Race<T> extends SagaEffect<Map<String, T>> {
  /// Named futures to race.
  final Map<String, Future<T> Function()> competitors;

  /// Creates a [Race] effect.
  const Race(this.competitors);
}

/// Run multiple futures in parallel and wait for all of them to complete.
///
/// If any future throws, the entire [All] effect fails. Cancellation of the
/// enclosing task aborts all pending futures.
final class All<T> extends SagaEffect<List<T>> {
  /// The futures to run in parallel.
  final List<Future<T> Function()> effects;

  /// Creates an [All] effect.
  const All(this.effects);
}

/// Read the current value of a [ReactonBase] from the store without
/// subscribing to changes.
///
/// This is a synchronous, point-in-time read. It does not create a
/// reactive dependency.
final class Select<T> extends SagaEffect<T> {
  /// The reacton to read.
  final ReactonBase<T> reacton;

  /// Creates a [Select] effect.
  const Select(this.reacton);
}

// ---------------------------------------------------------------------------
// SagaCancelledException
// ---------------------------------------------------------------------------

/// Thrown when a saga task is cancelled.
///
/// Saga handlers should generally not catch this exception. The saga runtime
/// uses it internally for cancellation flow control.
class SagaCancelledException implements Exception {
  /// Human-readable message describing why the cancellation occurred.
  final String message;

  /// Creates a [SagaCancelledException].
  const SagaCancelledException([this.message = 'Saga was cancelled']);

  @override
  String toString() => 'SagaCancelledException: $message';
}

// ---------------------------------------------------------------------------
// SagaHandler typedef
// ---------------------------------------------------------------------------

/// Signature for a saga handler function.
///
/// A handler receives a [SagaContext] for issuing effects and an optional
/// event payload that triggered this particular invocation.
typedef SagaHandler = Future<void> Function(SagaContext ctx, [dynamic event]);

// ---------------------------------------------------------------------------
// SagaTask
// ---------------------------------------------------------------------------

/// Represents a running saga instance.
///
/// Every call to [SagaContext.fork] or [ReactonStoreSaga.runSaga] produces a
/// [SagaTask]. Tasks can be joined, cancelled, and inspected.
class SagaTask {
  /// Auto-incrementing counter for unique IDs.
  static int _idCounter = 0;

  /// Unique identifier for this task.
  final int id;

  /// Optional debug name.
  final String? name;

  final Completer<void> _completer = Completer<void>();
  final List<SagaTask> _children = [];
  _SagaTaskStatus _status = _SagaTaskStatus.running;

  /// Creates a new [SagaTask] with a unique [id].
  SagaTask({this.name}) : id = _idCounter++;

  /// Whether this task is currently running.
  bool get isRunning => _status == _SagaTaskStatus.running;

  /// Whether this task completed successfully.
  bool get isCompleted => _status == _SagaTaskStatus.completed;

  /// Whether this task was cancelled.
  bool get isCancelled => _status == _SagaTaskStatus.cancelled;

  /// A future that completes when the task finishes (either by completing
  /// normally or being cancelled).
  Future<void> get result => _completer.future;

  /// Register a child task forked from within this task.
  ///
  /// This is an internal API used by the saga runtime. Application code
  /// should not call this directly.
  void addChild(SagaTask child) {
    _children.add(child);
  }

  /// Cancel this task and cascade cancellation to all children.
  ///
  /// Cancellation is idempotent: calling [cancel] on an already-cancelled
  /// or already-completed task is a no-op.
  void cancel() {
    if (_status != _SagaTaskStatus.running) return;
    _status = _SagaTaskStatus.cancelled;

    // Cascade cancellation to all child tasks.
    for (final child in _children) {
      child.cancel();
    }

    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// Mark this task as successfully completed.
  ///
  /// This is an internal API used by the saga runtime. Application code
  /// should not call this directly.
  void complete() {
    if (_status != _SagaTaskStatus.running) return;
    _status = _SagaTaskStatus.completed;

    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// Mark this task as completed with an error.
  ///
  /// This is an internal API used by the saga runtime. Application code
  /// should not call this directly.
  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_status != _SagaTaskStatus.running) return;
    _status = _SagaTaskStatus.completed;

    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }

  @override
  String toString() =>
      'SagaTask(id: $id, name: ${name ?? '<unnamed>'}, status: $_status)';
}

enum _SagaTaskStatus { running, completed, cancelled }

// ---------------------------------------------------------------------------
// SagaContext
// ---------------------------------------------------------------------------

/// Provides saga handlers with an imperative API for issuing effects.
///
/// Each running saga task has its own [SagaContext]. The context methods
/// are cancellation-aware: they check whether the enclosing task has been
/// cancelled before and after performing work, throwing
/// [SagaCancelledException] if it has.
///
/// ```dart
/// saga<LoginEvent>(
///   name: 'authSaga',
///   builder: (on) {
///     on.onLatest<LoginRequested>((ctx, event) async {
///       ctx.put(authStatusReacton, AuthStatus.loading);
///       try {
///         final user = await ctx.call(() => authApi.login(event.credentials));
///         ctx.put(userReacton, user);
///         ctx.put(authStatusReacton, AuthStatus.authenticated);
///       } catch (e) {
///         ctx.put(authStatusReacton, AuthStatus.error);
///       }
///     });
///   },
/// );
/// ```
class SagaContext {
  /// The store this saga operates against.
  final ReactonStore store;

  /// The task this context belongs to.
  final SagaTask task;

  /// Controller through which events are dispatched.
  final StreamController<dynamic> _eventBus;

  /// Creates a [SagaContext].
  SagaContext({
    required this.store,
    required this.task,
    required StreamController<dynamic> eventBus,
  }) : _eventBus = eventBus;

  // ---- Cancellation guard --------------------------------------------------

  /// Throws [SagaCancelledException] if the current task is cancelled.
  void _checkCancellation() {
    if (task.isCancelled) {
      throw const SagaCancelledException();
    }
  }

  // ---- Effect methods ------------------------------------------------------

  /// Wait for the next event of type [E] dispatched to this saga.
  ///
  /// Optionally pass a [predicate] to further filter events.
  ///
  /// Throws [SagaCancelledException] if the task is cancelled while waiting.
  Future<E> take<E>({bool Function(E event)? predicate}) async {
    _checkCancellation();

    final completer = Completer<E>();
    late final StreamSubscription<dynamic> subscription;

    subscription = _eventBus.stream.listen((event) {
      if (task.isCancelled) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(const SagaCancelledException());
        }
        return;
      }
      if (event is E && (predicate == null || predicate(event))) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      }
    });

    // If the task gets cancelled externally, clean up the subscription.
    task.result.whenComplete(() {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(const SagaCancelledException());
      }
    });

    return completer.future;
  }

  /// Write a [value] to a [WritableReacton] in the store.
  ///
  /// Throws [SagaCancelledException] if the task is cancelled.
  void put<T>(WritableReacton<T> reacton, T value) {
    _checkCancellation();
    store.set(reacton, value);
  }

  /// Execute an async function with cancellation awareness.
  ///
  /// If the task is cancelled while [fn] is executing, a
  /// [SagaCancelledException] is thrown once the underlying future
  /// settles (the future itself is not forcibly terminated, since Dart
  /// does not support killing isolate-free futures).
  ///
  /// Throws [SagaCancelledException] if the task is cancelled.
  Future<T> call<T>(Future<T> Function() fn) async {
    _checkCancellation();

    final resultCompleter = Completer<T>();

    // Run the actual future.
    fn().then((value) {
      if (!resultCompleter.isCompleted) {
        if (task.isCancelled) {
          resultCompleter.completeError(const SagaCancelledException());
        } else {
          resultCompleter.complete(value);
        }
      }
    }).catchError((Object error, StackTrace stackTrace) {
      if (!resultCompleter.isCompleted) {
        resultCompleter.completeError(error, stackTrace);
      }
    });

    // Monitor cancellation concurrently.
    task.result.whenComplete(() {
      if (!resultCompleter.isCompleted && task.isCancelled) {
        resultCompleter.completeError(const SagaCancelledException());
      }
    });

    return resultCompleter.future;
  }

  /// Fork a child saga to run concurrently.
  ///
  /// Returns a [SagaTask] representing the forked saga. Cancellation of
  /// the parent task cascades to the child.
  ///
  /// Throws [SagaCancelledException] if the parent task is already cancelled.
  SagaTask fork(SagaHandler handler, {String? name}) {
    _checkCancellation();

    final childTask = SagaTask(name: name);
    task.addChild(childTask);

    final childContext = SagaContext(
      store: store,
      task: childTask,
      eventBus: _eventBus,
    );

    // Launch the child asynchronously without awaiting it.
    _runChildSaga(childContext, handler, childTask);

    return childTask;
  }

  /// Wait for a forked [task] to complete.
  ///
  /// Throws [SagaCancelledException] if this task is cancelled while
  /// waiting, or if the target task was cancelled.
  Future<void> join(SagaTask targetTask) async {
    _checkCancellation();

    final completer = Completer<void>();

    targetTask.result.then((_) {
      if (!completer.isCompleted) {
        if (task.isCancelled) {
          completer.completeError(const SagaCancelledException());
        } else if (targetTask.isCancelled) {
          completer.completeError(
            const SagaCancelledException('Joined task was cancelled'),
          );
        } else {
          completer.complete();
        }
      }
    }).catchError((Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });

    // Parent cancellation while waiting.
    task.result.whenComplete(() {
      if (!completer.isCompleted && task.isCancelled) {
        completer.completeError(const SagaCancelledException());
      }
    });

    return completer.future;
  }

  /// Cancel a running [SagaTask].
  ///
  /// Cancellation cascades to all child tasks of the target task.
  ///
  /// Throws [SagaCancelledException] if this task is already cancelled.
  void cancelTask(SagaTask targetTask) {
    _checkCancellation();
    targetTask.cancel();
  }

  /// Suspend the saga for [duration].
  ///
  /// The delay is cancellable. If the saga is cancelled during the delay,
  /// a [SagaCancelledException] is thrown immediately.
  Future<void> delay(Duration duration) async {
    _checkCancellation();

    final completer = Completer<void>();
    final timer = Timer(duration, () {
      if (!completer.isCompleted) {
        if (task.isCancelled) {
          completer.completeError(const SagaCancelledException());
        } else {
          completer.complete();
        }
      }
    });

    // If cancelled while delayed, resolve immediately.
    task.result.whenComplete(() {
      if (!completer.isCompleted && task.isCancelled) {
        timer.cancel();
        completer.completeError(const SagaCancelledException());
      }
    });

    return completer.future;
  }

  /// Race multiple named async operations against each other.
  ///
  /// Returns a single-entry [Map] whose key is the winner's label and
  /// whose value is its result. Losers are discarded (their futures are
  /// not forcibly cancelled since Dart does not support that, but their
  /// results are ignored).
  ///
  /// Throws [SagaCancelledException] if the task is cancelled.
  Future<Map<String, T>> race<T>(Map<String, Future<T> Function()> effects) async {
    _checkCancellation();

    final completer = Completer<Map<String, T>>();

    for (final entry in effects.entries) {
      entry.value().then((value) {
        if (!completer.isCompleted) {
          if (task.isCancelled) {
            completer.completeError(const SagaCancelledException());
          } else {
            completer.complete({entry.key: value});
          }
        }
      }).catchError((Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      });
    }

    // Cancellation guard.
    task.result.whenComplete(() {
      if (!completer.isCompleted && task.isCancelled) {
        completer.completeError(const SagaCancelledException());
      }
    });

    return completer.future;
  }

  /// Run multiple async operations in parallel and wait for all to complete.
  ///
  /// If any operation throws, the entire [all] call fails with that error.
  ///
  /// Throws [SagaCancelledException] if the task is cancelled.
  Future<List<T>> all<T>(List<Future<T> Function()> effects) async {
    _checkCancellation();

    final completer = Completer<List<T>>();
    final results = List<T?>.filled(effects.length, null);
    var remaining = effects.length;

    if (remaining == 0) {
      return <T>[];
    }

    for (var i = 0; i < effects.length; i++) {
      effects[i]().then((value) {
        if (completer.isCompleted) return;
        if (task.isCancelled) {
          completer.completeError(const SagaCancelledException());
          return;
        }

        results[i] = value;
        remaining--;

        if (remaining == 0) {
          completer.complete(results.cast<T>());
        }
      }).catchError((Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      });
    }

    // Cancellation guard.
    task.result.whenComplete(() {
      if (!completer.isCompleted && task.isCancelled) {
        completer.completeError(const SagaCancelledException());
      }
    });

    return completer.future;
  }

  /// Read the current value of a reacton from the store.
  ///
  /// This is a synchronous, point-in-time read with no subscription.
  ///
  /// Throws [SagaCancelledException] if the task is cancelled.
  T select<T>(ReactonBase<T> reacton) {
    _checkCancellation();
    return store.get(reacton);
  }
}

/// Runs a child saga handler on [childTask], catching cancellation.
Future<void> _runChildSaga(
  SagaContext context,
  SagaHandler handler,
  SagaTask childTask,
) async {
  try {
    await handler(context);
    childTask.complete();
  } on SagaCancelledException {
    // Expected during cancellation — ensure the task is marked.
    childTask.cancel();
  } catch (error, stackTrace) {
    childTask.completeError(error, stackTrace);
  }
}

// ---------------------------------------------------------------------------
// SagaBuilder — DSL for registering event handlers
// ---------------------------------------------------------------------------

/// Builder DSL for registering event handlers on a [Saga].
///
/// Provides four handler patterns modelled after Redux-Saga:
///
/// - [on] — handle the first matching event, then stop
/// - [onEvery] — handle every occurrence concurrently (takeEvery)
/// - [onLatest] — cancel previous, run latest only (takeLatest)
/// - [onLeading] — ignore new events while one is already running (takeLeading)
class SagaBuilder<E> {
  final List<SagaRegistration<E>> _registrations = [];

  /// Register a handler that processes a single event of type [S] and
  /// then stops listening.
  ///
  /// This is equivalent to Redux-Saga's `take` + `call` pattern.
  void on<S extends E>(
    Future<void> Function(SagaContext ctx, S event) handler,
  ) {
    _registrations.add(SagaRegistration<E>(
      eventType: S,
      strategy: HandlerStrategy.takeOnce,
      handler: (SagaContext ctx, dynamic event) => handler(ctx, event as S),
    ));
  }

  /// Register a handler that runs for **every** event of type [S]
  /// concurrently (takeEvery pattern).
  ///
  /// Each incoming event spawns a new concurrent handler invocation.
  /// Previous invocations are not cancelled.
  void onEvery<S extends E>(
    Future<void> Function(SagaContext ctx, S event) handler,
  ) {
    _registrations.add(SagaRegistration<E>(
      eventType: S,
      strategy: HandlerStrategy.takeEvery,
      handler: (SagaContext ctx, dynamic event) => handler(ctx, event as S),
    ));
  }

  /// Register a handler that cancels any previous invocation when a new
  /// event of type [S] arrives (takeLatest pattern).
  ///
  /// Only the most recent invocation is allowed to run. This is useful
  /// for debounce-like behaviour such as search-as-you-type.
  void onLatest<S extends E>(
    Future<void> Function(SagaContext ctx, S event) handler,
  ) {
    _registrations.add(SagaRegistration<E>(
      eventType: S,
      strategy: HandlerStrategy.takeLatest,
      handler: (SagaContext ctx, dynamic event) => handler(ctx, event as S),
    ));
  }

  /// Register a handler that ignores new events of type [S] while a
  /// previous invocation is still running (takeLeading pattern).
  ///
  /// This ensures at most one invocation is active at a time. Useful for
  /// preventing duplicate submissions.
  void onLeading<S extends E>(
    Future<void> Function(SagaContext ctx, S event) handler,
  ) {
    _registrations.add(SagaRegistration<E>(
      eventType: S,
      strategy: HandlerStrategy.takeLeading,
      handler: (SagaContext ctx, dynamic event) => handler(ctx, event as S),
    ));
  }
}

// ---------------------------------------------------------------------------
// Saga<E>
// ---------------------------------------------------------------------------

/// A saga definition that describes how to handle events of type [E].
///
/// Sagas are declarative workflow descriptions. They do not run until
/// attached to a [ReactonStore] via the `runSaga` extension method
/// (see `saga_runner.dart`).
///
/// ```dart
/// final authSaga = saga<AuthEvent>(
///   name: 'auth',
///   builder: (on) {
///     on.onLatest<LoginRequested>((ctx, event) async {
///       ctx.put(authStatusReacton, AuthStatus.loading);
///       final user = await ctx.call(() => api.login(event.credentials));
///       ctx.put(userReacton, user);
///     });
///
///     on.onEvery<LogoutRequested>((ctx, event) async {
///       await ctx.call(() => api.logout());
///       ctx.put(userReacton, null);
///     });
///   },
/// );
/// ```
class Saga<E> {
  /// Human-readable name for debugging and logging.
  final String name;

  /// The builder function that registers event handlers.
  final void Function(SagaBuilder<E> on) _builderFn;

  /// Lazily built registrations.
  List<SagaRegistration<E>>? _registrations;

  /// Creates a [Saga] with the given [name] and [builder] function.
  Saga._({required this.name, required void Function(SagaBuilder<E> on) builder})
      : _builderFn = builder;

  /// Build and cache the handler registrations.
  List<SagaRegistration<E>> get registrations {
    if (_registrations == null) {
      final builder = SagaBuilder<E>();
      _builderFn(builder);
      _registrations = List.unmodifiable(builder._registrations);
    }
    return _registrations!;
  }

  @override
  String toString() => 'Saga<$E>(name: $name)';
}

/// Create a [Saga] that handles events of type [E].
///
/// The [builder] callback receives a [SagaBuilder] for registering
/// event-type-specific handlers with different concurrency strategies.
///
/// ```dart
/// final mySaga = saga<MyEvent>(
///   name: 'mySaga',
///   builder: (on) {
///     on.onEvery<FetchRequested>((ctx, event) async {
///       final data = await ctx.call(() => api.fetch(event.id));
///       ctx.put(dataReacton, data);
///     });
///   },
/// );
/// ```
Saga<E> saga<E>({
  String? name,
  required void Function(SagaBuilder<E> on) builder,
}) {
  return Saga<E>._(
    name: name ?? 'saga<$E>',
    builder: builder,
  );
}

// ---------------------------------------------------------------------------
// Handler strategy and registration (visible to saga_runner.dart)
// ---------------------------------------------------------------------------

/// The concurrency strategy used by a saga event handler registration.
///
/// Determines how the saga runner processes incoming events relative to
/// any handler invocations that are already in flight.
enum HandlerStrategy {
  /// Handle only the first matching event, then unregister.
  takeOnce,

  /// Handle every event concurrently (no cancellation).
  takeEvery,

  /// Cancel any in-flight handler when a new event arrives.
  takeLatest,

  /// Ignore new events while a handler is already running.
  takeLeading,
}

/// Describes a single event-handler registration within a [Saga].
///
/// Each registration pairs an event subtype with a concurrency [strategy]
/// and the [handler] function to invoke.
class SagaRegistration<E> {
  /// The runtime [Type] of the event subtype this registration matches.
  final Type eventType;

  /// The concurrency strategy for this handler.
  final HandlerStrategy strategy;

  /// The handler function invoked when a matching event arrives.
  ///
  /// The event parameter is typed as `dynamic` to allow type-erased storage
  /// in [_HandlerSlot]. The actual runtime cast to the specific event subtype
  /// is performed inside the closure created by [SagaBuilder].
  final Future<void> Function(SagaContext ctx, dynamic event) handler;

  /// Creates a [SagaRegistration].
  const SagaRegistration({
    required this.eventType,
    required this.strategy,
    required this.handler,
  });
}
