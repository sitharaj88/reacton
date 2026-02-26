import '../core/reacton_base.dart';
import '../core/readonly_reacton.dart';
import '../core/writable_reacton.dart';
import '../derived/effect.dart';
import '../graph/reactive_graph.dart';
import '../middleware/middleware.dart';
import '../persistence/storage_adapter.dart';
import '../utils/disposable.dart';
import 'store_snapshot.dart';

/// The central value container for all reactons in the Reacton system.
///
/// [ReactonStore] holds reacton values, manages subscriptions, and bridges
/// user code with the reactive graph engine. It's the single source of
/// truth for all state.
///
/// ```dart
/// final store = ReactonStore();
/// store.set(counterReacton, 42);
/// print(store.get(counterReacton)); // 42
/// ```
class ReactonStore with Disposable {
  final ReactiveGraph _graph;
  final Map<ReactonRef, dynamic> _values = {};
  final Map<ReactonRef, List<void Function(dynamic)>> _listeners = {};
  final Map<ReactonRef, ReadonlyReacton> _computedReactons = {};
  final Map<ReactonRef, EffectNode> _effects = {};
  final List<Middleware> _globalMiddleware = [];
  final StorageAdapter? _storageAdapter;

  /// Optional DevTools listener for tracking value changes.
  /// Called with (ref, oldValue, newValue) whenever any reacton value changes.
  void Function(ReactonRef ref, dynamic oldValue, dynamic newValue)?
      _devToolsListener;

  /// Create a new ReactonStore.
  ///
  /// Optionally provide a [storageAdapter] for persistence and
  /// [globalMiddleware] that applies to all reactons.
  ReactonStore({
    StorageAdapter? storageAdapter,
    List<Middleware>? globalMiddleware,
  })  : _graph = ReactiveGraph(),
        _storageAdapter = storageAdapter {
    if (globalMiddleware != null) {
      _globalMiddleware.addAll(globalMiddleware);
    }
    _graph.onNodeChanged = _onNodeChanged;
  }

  /// The reactive graph (exposed for DevTools and testing).
  ReactiveGraph get graph => _graph;

  /// The storage adapter (if configured).
  StorageAdapter? get storageAdapter => _storageAdapter;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Read the current value of a reacton.
  ///
  /// If the reacton hasn't been initialized yet, it will be lazily initialized.
  T get<T>(ReactonBase<T> reacton) {
    if (!_values.containsKey(reacton.ref)) {
      _initialize(reacton);
    }
    return _values[reacton.ref] as T;
  }

  /// Read a value by ReactonRef (for internal use).
  dynamic getByRef(ReactonRef ref) => _values[ref];

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Set a writable reacton's value.
  ///
  /// Triggers reactive propagation to all dependent computed reactons
  /// and subscriber callbacks.
  void set<T>(WritableReacton<T> reacton, T value) {
    assertNotDisposed();

    if (!_values.containsKey(reacton.ref)) {
      _initialize(reacton);
    }

    final currentValue = _values[reacton.ref] as T;

    // Check equality - skip if unchanged
    if (reacton.equals(currentValue, value)) return;

    // Run middleware beforeWrite
    var finalValue = value;
    for (final mw in _getMiddleware(reacton)) {
      finalValue = mw.onBeforeWrite(reacton, currentValue, finalValue);
    }

    // Custom write handler
    if (reacton.onWrite != null) {
      reacton.onWrite!(<V>(WritableReacton<V> a, V v) => set(a, v), finalValue);
      return;
    }

    // Store the value
    _values[reacton.ref] = finalValue;

    // Notify DevTools listener
    _devToolsListener?.call(reacton.ref, currentValue, finalValue);

    // Mark dirty in graph (triggers Phase 1 + schedules Phase 2)
    _graph.markDirty(reacton.ref);

    // Notify direct listeners
    _notifyListeners(reacton.ref, finalValue);

    // Run middleware afterWrite
    for (final mw in _getMiddleware(reacton)) {
      mw.onAfterWrite(reacton, finalValue);
    }
  }

  /// Set a value by ReactonRef id (for internal/DevTools use).
  void setByRefId(int refId, dynamic value) {
    final ref = _values.keys.firstWhere(
      (r) => r.id == refId,
      orElse: () => throw StateError('No reacton with ref id $refId'),
    );
    _values[ref] = value;
    _graph.markDirty(ref);
    _notifyListeners(ref, value);
  }

  /// Update a writable reacton using a function.
  void update<T>(WritableReacton<T> reacton, T Function(T current) updater) {
    set(reacton, updater(get(reacton)));
  }

  // ---------------------------------------------------------------------------
  // Subscribe
  // ---------------------------------------------------------------------------

  /// Subscribe to value changes of a reacton.
  ///
  /// Returns an [Unsubscribe] function that should be called to cancel.
  Unsubscribe subscribe<T>(ReactonBase<T> reacton, void Function(T value) listener) {
    if (!_values.containsKey(reacton.ref)) {
      _initialize(reacton);
    }

    void wrappedListener(dynamic value) => listener(value as T);
    _listeners.putIfAbsent(reacton.ref, () => []).add(wrappedListener);

    // Track subscriber count in graph node
    final node = _graph.getNode(reacton.ref);
    node?.addSubscriber();

    return () {
      _listeners[reacton.ref]?.remove(wrappedListener);
      node?.removeSubscriber();
    };
  }

  // ---------------------------------------------------------------------------
  // Effects
  // ---------------------------------------------------------------------------

  /// Register an effect that runs when its dependencies change.
  ///
  /// Returns an [Unsubscribe] function to dispose the effect.
  Unsubscribe registerEffect(EffectNode effect) {
    _effects[effect.ref] = effect;
    _runEffect(effect);

    return () {
      effect.cleanup?.call();
      _effects.remove(effect.ref);
      _graph.unregister(effect.ref);
    };
  }

  void _runEffect(EffectNode effectNode) {
    // Clean up previous run
    effectNode.cleanup?.call();

    // Track dependencies during execution
    final deps = <ReactonRef>[];
    final reader = _createTrackingReader(deps);

    final cleanup = effectNode.run(reader);
    effectNode.cleanup = cleanup;

    // Register in graph with tracked dependencies
    _graph.registerEffect(effectNode.ref, deps);
  }

  // ---------------------------------------------------------------------------
  // Batch
  // ---------------------------------------------------------------------------

  /// Execute multiple mutations atomically.
  ///
  /// All changes within the batch are propagated together at the end,
  /// preventing intermediate states from being observed.
  ///
  /// ```dart
  /// store.batch(() {
  ///   store.set(firstNameReacton, 'John');
  ///   store.set(lastNameReacton, 'Doe');
  ///   // fullNameReacton recomputes only once, after both are set
  /// });
  /// ```
  void batch(void Function() fn) {
    _graph.scheduler.batch(fn);
  }

  // ---------------------------------------------------------------------------
  // Snapshot
  // ---------------------------------------------------------------------------

  /// Take an immutable snapshot of all current reacton values.
  StoreSnapshot snapshot() {
    return StoreSnapshot(Map.unmodifiable(Map.of(_values)));
  }

  /// Restore state from a snapshot.
  ///
  /// Only writable (source) reacton values are restored directly.
  /// Computed reactons recompute naturally through graph propagation.
  /// Notifications are deferred until all values are set and the graph
  /// has fully propagated, preventing mid-restore notifications to
  /// widgets that may reference inconsistent state.
  void restore(StoreSnapshot snapshot) {
    final changedRefs = <ReactonRef, dynamic>{};

    batch(() {
      for (final entry in snapshot.values.entries) {
        final node = _graph.getNode(entry.key);
        // Skip computed nodes — they will recompute via graph propagation.
        // Also skip refs not registered in the graph (stale snapshot entries).
        if (node == null || node.isComputed) continue;

        final oldValue = _values[entry.key];
        if (oldValue == entry.value) continue;

        _values[entry.key] = entry.value;
        _graph.markDirty(entry.key);
        changedRefs[entry.key] = entry.value;
      }
    });

    // Notify listeners after the batch completes and graph has propagated.
    // This ensures all state is consistent before any widget rebuilds.
    for (final entry in changedRefs.entries) {
      _notifyListeners(entry.key, entry.value);
    }
  }

  // ---------------------------------------------------------------------------
  // Override (for testing)
  // ---------------------------------------------------------------------------

  /// Force-set a reacton's value without triggering middleware.
  /// Used primarily for testing overrides.
  void forceSet<T>(ReactonBase<T> reacton, T value) {
    if (!_graph.contains(reacton.ref)) {
      if (reacton is WritableReacton<T>) {
        _graph.registerWritable(reacton);
      }
    }
    _values[reacton.ref] = value;
  }

  // ---------------------------------------------------------------------------
  // Removal
  // ---------------------------------------------------------------------------

  /// Remove a reacton from the store, freeing its value and subscriptions.
  void remove(ReactonRef ref) {
    _values.remove(ref);
    _listeners.remove(ref);
    _computedReactons.remove(ref);
    _graph.unregister(ref);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Initialize a reacton: set initial value and register in graph.
  void _initialize<T>(ReactonBase<T> reacton) {
    if (reacton is WritableReacton<T>) {
      _initializeWritable(reacton);
    } else if (reacton is ReadonlyReacton<T>) {
      _initializeComputed(reacton);
    }
  }

  void _initializeWritable<T>(WritableReacton<T> reacton) {
    var value = reacton.initialValue;

    // Register in graph
    _graph.registerWritable(reacton);

    // Run middleware onInit
    for (final mw in _getMiddleware(reacton)) {
      value = mw.onInit(reacton, value);
    }

    // Check persistence
    if (reacton.options?.persistKey != null && _storageAdapter != null) {
      final stored = _storageAdapter!.read(reacton.options!.persistKey!);
      if (stored != null && reacton.options?.serializer != null) {
        try {
          value = reacton.options!.serializer!.deserialize(stored);
        } catch (_) {
          // Fall back to initial value if deserialization fails
        }
      }
    }

    _values[reacton.ref] = value;
  }

  void _initializeComputed<T>(ReadonlyReacton<T> reacton) {
    _computedReactons[reacton.ref] = reacton;

    // Track dependencies during initial computation
    final deps = <ReactonRef>[];
    final reader = _createTrackingReader(deps);
    final value = reacton.compute(reader);

    _values[reacton.ref] = value;
    _graph.registerComputed(reacton, deps);
  }

  /// Create a reader that tracks which reactons are read.
  ReactonReader _createTrackingReader(List<ReactonRef> deps) {
    return <T>(ReactonBase<T> depReacton) {
      deps.add(depReacton.ref);
      return get(depReacton);
    };
  }

  /// Called by the reactive graph when a computed node needs recomputation.
  void _onNodeChanged(ReactonRef ref) {
    // Recompute computed reactons
    final computedReacton = _computedReactons[ref];
    if (computedReacton != null) {
      final deps = <ReactonRef>[];
      final reader = _createTrackingReader(deps);
      final oldValue = _values[ref];
      final newValue = computedReacton.compute(reader);

      // Update dependencies (they may have changed if computation is conditional)
      _graph.registerComputed(computedReacton, deps);

      if (oldValue != newValue) {
        _values[ref] = newValue;
        _devToolsListener?.call(ref, oldValue, newValue);
        _notifyListeners(ref, newValue);
      }
      return;
    }

    // Re-run effects
    final effectNode = _effects[ref];
    if (effectNode != null) {
      _runEffect(effectNode);
    }
  }

  /// Notify all listeners for a given reacton ref.
  void _notifyListeners(ReactonRef ref, dynamic value) {
    final listeners = _listeners[ref];
    if (listeners != null) {
      // Iterate over a copy to allow listeners to unsubscribe during notification
      for (final listener in List.of(listeners)) {
        listener(value);
      }
    }
  }

  /// Get all applicable middleware for a reacton.
  List<Middleware<T>> _getMiddleware<T>(ReactonBase<T> reacton) {
    final middleware = <Middleware<T>>[];
    // Global middleware (cast to generic - only type-safe ones will work)
    for (final mw in _globalMiddleware) {
      if (mw is Middleware<T>) {
        middleware.add(mw);
      }
    }
    // Reacton-specific middleware
    if (reacton.options?.middleware != null) {
      middleware.addAll(reacton.options!.middleware);
    }
    return middleware;
  }

  /// Register a DevTools listener for value change tracking.
  ///
  /// The listener is called with (ref, oldValue, newValue) whenever any
  /// reacton value changes. Only one listener is supported at a time.
  void setDevToolsListener(
    void Function(ReactonRef ref, dynamic oldValue, dynamic newValue)? listener,
  ) {
    _devToolsListener = listener;
  }

  /// All registered reacton refs.
  Iterable<ReactonRef> get reactonRefs => _values.keys;

  /// Number of reactons in the store.
  int get reactonCount => _values.length;

  @override
  void dispose() {
    // Clean up all effects
    for (final effect in _effects.values) {
      effect.cleanup?.call();
    }
    _effects.clear();
    _listeners.clear();
    _values.clear();
    _computedReactons.clear();
    _graph.dispose();
    super.dispose();
  }
}
