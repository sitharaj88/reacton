import 'dart:async';
import 'dart:convert';

import '../core/reacton_base.dart';
import '../core/writable_reacton.dart';
import '../persistence/serializer.dart';
import '../store/store.dart';
import '../utils/disposable.dart';
import 'crdt.dart';

// ---------------------------------------------------------------------------
// CollaborativeReacton
// ---------------------------------------------------------------------------

/// A reactive state unit that synchronizes across distributed nodes using
/// CRDT (Conflict-free Replicated Data Type) semantics.
///
/// [CollaborativeReacton] extends [WritableReacton] with CRDT metadata
/// tracking, automatic merge on incoming remote updates, and configurable
/// conflict resolution via [CrdtMergeStrategy].
///
/// ## Usage
///
/// ```dart
/// final counter = collaborativeReacton<int>(
///   0,
///   name: 'counter',
///   strategy: MaxValue<int>(),
///   serializer: PrimitiveSerializer<int>(),
/// );
///
/// final store = ReactonStore();
/// final session = store.collaborate(
///   channel: myWebSocketChannel,
///   reactons: [counter],
/// );
///
/// // Local writes automatically sync to peers
/// store.set(counter, 42);
///
/// // Remote writes are merged using the configured strategy
/// session.onConflict.listen((event) {
///   print('Conflict resolved: ${event.resolvedValue}');
/// });
/// ```
///
/// ## Conflict Resolution
///
/// When a remote update is concurrent with the local state (neither
/// vector clock dominates), the configured [CrdtMergeStrategy] determines
/// the outcome:
///
/// - [LastWriterWins] (default) — most recent wall-clock timestamp wins
/// - [MaxValue] — numerically larger value wins (GCounter)
/// - [UnionMerge] — set union (GSet)
/// - [CustomMerge] — user-provided merge function
///
/// If the remote update is causally newer (its vector clock dominates
/// the local clock), it is applied directly without invoking the merge
/// strategy.
class CollaborativeReacton<T> extends WritableReacton<T> {
  /// The merge strategy used to resolve concurrent updates.
  final CrdtMergeStrategy<T> strategy;

  /// Serializer for converting [T] to/from JSON-compatible representations.
  ///
  /// Required for wire transport. If not provided, values must be natively
  /// JSON-serializable (primitives, lists, maps).
  final Serializer<T>? serializer;

  /// The collaborative name used to identify this reacton across peers.
  ///
  /// Must be unique within a [CollaborativeSession]. Defaults to
  /// [ReactonBase.ref]'s debug name.
  final String collaborativeName;

  /// Creates a [CollaborativeReacton].
  ///
  /// Prefer using the [collaborativeReacton] factory function instead
  /// of calling this constructor directly.
  CollaborativeReacton(
    super.initialValue, {
    required this.collaborativeName,
    CrdtMergeStrategy<T>? strategy,
    this.serializer,
    super.name,
    super.options,
  }) : strategy = strategy ?? LastWriterWins<T>();
}

/// Creates a [CollaborativeReacton] with the given initial value and
/// CRDT configuration.
///
/// The [name] parameter serves double duty: it is used as the debug name
/// for the reacton and as the collaborative identifier for sync. If you
/// need different values, construct [CollaborativeReacton] directly.
///
/// ```dart
/// final counter = collaborativeReacton(0, name: 'counter');
///
/// final tags = collaborativeReacton<Set<String>>(
///   {},
///   name: 'tags',
///   strategy: UnionMerge<Set<String>>(),
///   serializer: JsonSerializer<Set<String>>(
///     toJson: (s) => {'items': s.toList()},
///     fromJson: (j) => (j['items'] as List).cast<String>().toSet(),
///   ),
/// );
/// ```
CollaborativeReacton<T> collaborativeReacton<T>(
  T initialValue, {
  String? name,
  CrdtMergeStrategy<T>? strategy,
  Serializer<T>? serializer,
  ReactonOptions<T>? options,
}) {
  final collabName = name ?? 'collab_${ReactonRef(debugName: name)}';
  return CollaborativeReacton<T>(
    initialValue,
    collaborativeName: collabName,
    strategy: strategy,
    serializer: serializer,
    name: name,
    options: options,
  );
}

// ---------------------------------------------------------------------------
// CollaborativeSession
// ---------------------------------------------------------------------------

/// Manages CRDT-based state synchronization for a set of
/// [CollaborativeReacton] instances over a [SyncChannel].
///
/// A session is created via [ReactonStoreCollab.collaborate] and handles:
///
/// - Subscribing to local changes and broadcasting deltas to peers
/// - Receiving remote deltas and merging them into local state
/// - Full-state sync for newly connected peers
/// - Conflict detection and notification
/// - Graceful disconnect and resource cleanup
///
/// ## Lifecycle
///
/// ```dart
/// // 1. Create the session (starts syncing immediately)
/// final session = store.collaborate(
///   channel: channel,
///   reactons: [counter, tags],
/// );
///
/// // 2. Monitor sync status
/// session.syncStatus.listen((status) => print('Status: $status'));
///
/// // 3. Monitor conflicts
/// session.onConflict.listen((event) => print('Conflict: $event'));
///
/// // 4. Disconnect when done
/// await session.disconnect();
/// ```
class CollaborativeSession with Disposable {
  final ReactonStore _store;
  final SyncChannel _channel;
  final Map<String, _TrackedReacton> _tracked = {};
  final List<Unsubscribe> _storeSubscriptions = [];
  StreamSubscription<String>? _incomingSubscription;

  final _conflictController =
      StreamController<ConflictEvent<Object?>>.broadcast();
  final _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _currentStatus = SyncStatus.disconnected;
  final Set<String> _knownPeers = {};

  CollaborativeSession._({
    required ReactonStore store,
    required SyncChannel channel,
  })  : _store = store,
        _channel = channel;

  /// A stream of [ConflictEvent]s emitted whenever a concurrent update is
  /// detected and resolved by a [CrdtMergeStrategy].
  ///
  /// Use this to display user-facing conflict notifications or log
  /// analytics.
  Stream<ConflictEvent<Object?>> get onConflict => _conflictController.stream;

  /// A stream of [SyncStatus] changes reflecting the session's connection
  /// state.
  Stream<SyncStatus> get syncStatus => _statusController.stream;

  /// The current synchronization status.
  SyncStatus get currentStatus => _currentStatus;

  /// Whether the session is currently connected and actively syncing.
  bool get isConnected => _currentStatus == SyncStatus.connected;

  /// The set of known peer node IDs that have communicated with this session.
  Set<String> get peers => Set.unmodifiable(_knownPeers);

  /// The local node identifier from the underlying [SyncChannel].
  String get localNodeId => _channel.localNodeId;

  /// Starts the synchronization session.
  ///
  /// This method:
  /// 1. Subscribes to the [SyncChannel.incoming] stream.
  /// 2. Subscribes to local store changes for each tracked reacton.
  /// 3. Sends a [SyncRequestFull] to request initial state from peers.
  void _start(
    List<CollaborativeReacton<Object?>> reactons, {
    CrdtMergeStrategy<Object?>? defaultStrategy,
  }) {
    _setStatus(SyncStatus.connecting);

    // Register all collaborative reactons
    for (final reacton in reactons) {
      final name = reacton.collaborativeName;
      final currentValue = _store.get(reacton);
      final clock = VectorClock.zero().increment(_channel.localNodeId);

      _tracked[name] = _TrackedReacton(
        reacton: reacton,
        crdtValue: CrdtValue<Object?>(
          value: currentValue,
          clock: clock,
          nodeId: _channel.localNodeId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
        strategy: reacton.strategy,
      );

      // Subscribe to local changes on this reacton
      final unsub = _store.subscribe(reacton, (value) {
        _onLocalChange(name, value);
      });
      _storeSubscriptions.add(unsub);
    }

    // Listen for incoming remote messages
    _incomingSubscription = _channel.incoming.listen(
      _onRemoteMessage,
      onError: _onChannelError,
      onDone: _onChannelDone,
    );

    // Request full state from peers
    _channel.send(SyncRequestFull(
      reactonNames: _tracked.keys.toList(),
      sourceNodeId: _channel.localNodeId,
    ).toJsonString());

    _setStatus(SyncStatus.connected);
  }

  /// Disconnects the session and releases all resources.
  ///
  /// After disconnecting, the session cannot be restarted. Create a new
  /// session via [ReactonStoreCollab.collaborate] to reconnect.
  Future<void> disconnect() async {
    if (isDisposed) return;

    _setStatus(SyncStatus.disconnected);

    // Cancel store subscriptions
    for (final unsub in _storeSubscriptions) {
      unsub();
    }
    _storeSubscriptions.clear();

    // Cancel incoming stream subscription
    await _incomingSubscription?.cancel();
    _incomingSubscription = null;

    // Close the channel
    await _channel.close();

    // Close stream controllers
    await _conflictController.close();
    await _statusController.close();

    _tracked.clear();
    _knownPeers.clear();

    dispose();
  }

  // -------------------------------------------------------------------------
  // Local change handling
  // -------------------------------------------------------------------------

  /// Called when a tracked reacton's value changes locally (via store.set).
  void _onLocalChange(String reactonName, Object? newValue) {
    if (isDisposed) return;

    final tracked = _tracked[reactonName];
    if (tracked == null) return;

    // Guard against re-entrant calls during remote merge.
    // When we apply a remote value via _store.set, the subscription fires
    // back into this method. We detect this by checking if the value is
    // the same object we just applied from a remote update.
    if (identical(newValue, tracked.lastAppliedRemoteValue)) {
      tracked.lastAppliedRemoteValue = null; // reset sentinel
      return;
    }

    // Advance the local vector clock
    final newClock = tracked.crdtValue.clock.increment(_channel.localNodeId);
    final now = DateTime.now().millisecondsSinceEpoch;

    tracked.crdtValue = CrdtValue<Object?>(
      value: newValue,
      clock: newClock,
      nodeId: _channel.localNodeId,
      timestamp: now,
    );

    // Serialize and broadcast the delta
    final serialized = _serializeValue(tracked, newValue);
    final delta = SyncDelta(
      reactonName: reactonName,
      crdtValue: CrdtValue<Object?>(
        value: serialized,
        clock: newClock,
        nodeId: _channel.localNodeId,
        timestamp: now,
      ),
      sourceNodeId: _channel.localNodeId,
    );

    try {
      _channel.send(delta.toJsonString());
    } on StateError {
      // Channel is closed; transition to disconnected.
      _setStatus(SyncStatus.disconnected);
    }
  }

  // -------------------------------------------------------------------------
  // Remote message handling
  // -------------------------------------------------------------------------

  /// Dispatches an incoming JSON message from the sync channel.
  void _onRemoteMessage(String raw) {
    if (isDisposed) return;

    final SyncMessage message;
    try {
      message = SyncMessage.fromJson(
        _decodeJson(raw),
        deserializeValue: _deserializeValue,
      );
    } on FormatException {
      // Malformed message; skip silently.
      return;
    }

    switch (message) {
      case SyncDelta(:final reactonName, :final crdtValue, :final sourceNodeId):
        _knownPeers.add(sourceNodeId);
        _handleDelta(reactonName, crdtValue, sourceNodeId);

      case SyncFull(:final reactonName, :final crdtValue, :final sourceNodeId):
        _knownPeers.add(sourceNodeId);
        _handleFull(reactonName, crdtValue, sourceNodeId);

      case SyncAck(:final sourceNodeId):
        _knownPeers.add(sourceNodeId);
        // Acks are informational; no action required for basic sync.

      case SyncRequestFull(:final reactonNames, :final sourceNodeId):
        _knownPeers.add(sourceNodeId);
        _handleFullRequest(reactonNames, sourceNodeId);
    }
  }

  /// Handles an incremental delta from a remote peer.
  void _handleDelta(
    String reactonName,
    CrdtValue<Object?> remoteCrdt,
    String sourceNodeId,
  ) {
    final tracked = _tracked[reactonName];
    if (tracked == null) return;

    final localCrdt = tracked.crdtValue;

    // Deserialize the remote value
    final remoteValue = _deserializeTrackedValue(tracked, remoteCrdt.value);
    final remoteCrdtTyped = remoteCrdt.copyWith(value: remoteValue);

    // Determine causal relationship
    if (localCrdt.clock.happensBefore(remoteCrdtTyped.clock)) {
      // Remote is strictly newer — apply directly
      _applyRemoteValue(tracked, reactonName, remoteCrdtTyped);
    } else if (remoteCrdtTyped.clock.happensBefore(localCrdt.clock)) {
      // Remote is strictly older — ignore (we already have newer state)
    } else {
      // Concurrent — invoke merge strategy
      _mergeConflict(tracked, reactonName, remoteCrdtTyped);
    }

    // Send acknowledgment
    try {
      _channel.send(SyncAck(
        reactonName: reactonName,
        ackedClock: tracked.crdtValue.clock,
        sourceNodeId: _channel.localNodeId,
      ).toJsonString());
    } on StateError {
      // Channel closed; ignore.
    }
  }

  /// Handles a full-state sync message from a remote peer.
  void _handleFull(
    String reactonName,
    CrdtValue<Object?> remoteCrdt,
    String sourceNodeId,
  ) {
    final tracked = _tracked[reactonName];
    if (tracked == null) return;

    final remoteValue = _deserializeTrackedValue(tracked, remoteCrdt.value);
    final remoteCrdtTyped = remoteCrdt.copyWith(value: remoteValue);

    final localCrdt = tracked.crdtValue;

    if (localCrdt.clock.happensBefore(remoteCrdtTyped.clock)) {
      _applyRemoteValue(tracked, reactonName, remoteCrdtTyped);
    } else if (remoteCrdtTyped.clock.happensBefore(localCrdt.clock)) {
      // We have newer state; ignore the full sync.
    } else if (localCrdt.clock.isConcurrent(remoteCrdtTyped.clock)) {
      _mergeConflict(tracked, reactonName, remoteCrdtTyped);
    }
    // If clocks are equal, state is already consistent.
  }

  /// Handles a full-state request from a newly connected peer.
  void _handleFullRequest(List<String> reactonNames, String sourceNodeId) {
    final names =
        reactonNames.isEmpty ? _tracked.keys.toList() : reactonNames;

    for (final name in names) {
      final tracked = _tracked[name];
      if (tracked == null) continue;

      final serialized =
          _serializeValue(tracked, tracked.crdtValue.value);

      final fullMsg = SyncFull(
        reactonName: name,
        crdtValue: CrdtValue<Object?>(
          value: serialized,
          clock: tracked.crdtValue.clock,
          nodeId: _channel.localNodeId,
          timestamp: tracked.crdtValue.timestamp,
        ),
        sourceNodeId: _channel.localNodeId,
      );

      try {
        _channel.send(fullMsg.toJsonString());
      } on StateError {
        // Channel closed.
        _setStatus(SyncStatus.disconnected);
        return;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Merge logic
  // -------------------------------------------------------------------------

  /// Applies a remote CRDT value that is causally newer than the local state.
  void _applyRemoteValue(
    _TrackedReacton tracked,
    String reactonName,
    CrdtValue<Object?> remoteCrdt,
  ) {
    // Merge clocks (pointwise max)
    final mergedClock = tracked.crdtValue.clock.merge(remoteCrdt.clock);

    tracked.crdtValue = CrdtValue<Object?>(
      value: remoteCrdt.value,
      clock: mergedClock,
      nodeId: remoteCrdt.nodeId,
      timestamp: remoteCrdt.timestamp,
    );

    // Set a sentinel so _onLocalChange knows this is a remote-originated write
    tracked.lastAppliedRemoteValue = remoteCrdt.value;

    // Write into the store (triggers reactive graph propagation)
    _store.set(tracked.reacton, remoteCrdt.value);
  }

  /// Resolves a conflict between concurrent local and remote state using
  /// the tracked reacton's [CrdtMergeStrategy].
  void _mergeConflict(
    _TrackedReacton tracked,
    String reactonName,
    CrdtValue<Object?> remoteCrdt,
  ) {
    final localCrdt = tracked.crdtValue;

    // Resolve using the merge strategy
    final resolved = tracked.strategy.resolve(
      localCrdt.value,
      remoteCrdt.value,
      localCrdt.clock,
      remoteCrdt.clock,
      localCrdt.timestamp,
      remoteCrdt.timestamp,
    );

    // Merge clocks and advance local
    final mergedClock = localCrdt.clock
        .merge(remoteCrdt.clock)
        .increment(_channel.localNodeId);
    final now = DateTime.now().millisecondsSinceEpoch;

    tracked.crdtValue = CrdtValue<Object?>(
      value: resolved,
      clock: mergedClock,
      nodeId: _channel.localNodeId,
      timestamp: now,
    );

    // Emit conflict event
    _conflictController.add(ConflictEvent<Object?>(
      reactonName: reactonName,
      localValue: localCrdt.value,
      remoteValue: remoteCrdt.value,
      resolvedValue: resolved,
      strategy: tracked.strategy,
      localClock: localCrdt.clock,
      remoteClock: remoteCrdt.clock,
    ));

    // Apply the resolved value to the store
    tracked.lastAppliedRemoteValue = resolved;
    _store.set(tracked.reacton, resolved);
  }

  // -------------------------------------------------------------------------
  // Serialization helpers
  // -------------------------------------------------------------------------

  /// Serializes a value for wire transport using the tracked reacton's
  /// serializer, or passes it through if no serializer is configured.
  Object? _serializeValue(_TrackedReacton tracked, Object? value) {
    final serializer = tracked.reacton.serializer;
    if (serializer != null && value != null) {
      return serializer.serialize(value);
    }
    return value;
  }

  /// Deserializes a value received from the wire using the tracked reacton's
  /// serializer.
  Object? _deserializeTrackedValue(_TrackedReacton tracked, Object? raw) {
    final serializer = tracked.reacton.serializer;
    if (serializer != null && raw is String) {
      return serializer.deserialize(raw);
    }
    return raw;
  }

  /// Callback for [SyncMessage.fromJson] that routes deserialization to the
  /// correct tracked reacton's serializer.
  Object? _deserializeValue(String reactonName, Object? raw) {
    final tracked = _tracked[reactonName];
    if (tracked == null) return raw;
    return _deserializeTrackedValue(tracked, raw);
  }

  /// Decodes a JSON string into a map, handling parse errors gracefully.
  Map<String, dynamic> _decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object');
  }

  // -------------------------------------------------------------------------
  // Channel lifecycle
  // -------------------------------------------------------------------------

  /// Called when the channel stream emits an error.
  void _onChannelError(Object error, StackTrace stackTrace) {
    if (isDisposed) return;
    _setStatus(SyncStatus.reconnecting);
  }

  /// Called when the channel stream is done (connection closed).
  void _onChannelDone() {
    if (isDisposed) return;
    _setStatus(SyncStatus.disconnected);
  }

  /// Updates the sync status and emits on the status stream.
  void _setStatus(SyncStatus status) {
    if (_currentStatus == status) return;
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}

// ---------------------------------------------------------------------------
// Internal tracking state
// ---------------------------------------------------------------------------

/// Internal bookkeeping for a single collaborative reacton within a session.
class _TrackedReacton {
  /// The underlying collaborative reacton definition.
  final CollaborativeReacton<Object?> reacton;

  /// The current CRDT value with metadata.
  CrdtValue<Object?> crdtValue;

  /// The merge strategy for this reacton.
  final CrdtMergeStrategy<Object?> strategy;

  /// Sentinel value set when applying a remote update, to prevent the
  /// store subscription from re-broadcasting the same change as a local
  /// delta.
  Object? lastAppliedRemoteValue;

  _TrackedReacton({
    required this.reacton,
    required this.crdtValue,
    required this.strategy,
  });
}

// ---------------------------------------------------------------------------
// ReactonStore extension for collaborative features
// ---------------------------------------------------------------------------

/// Extension on [ReactonStore] providing collaborative state synchronization
/// capabilities.
///
/// This extension uses the [Expando] pattern (consistent with
/// [ReactonStoreModules]) to attach collaborative session state to a store
/// without modifying the core [ReactonStore] class.
///
/// ## Usage
///
/// ```dart
/// final store = ReactonStore();
/// final counter = collaborativeReacton(0, name: 'counter');
///
/// // Start a collaborative session
/// final session = store.collaborate(
///   channel: myChannel,
///   reactons: [counter],
/// );
///
/// // Query sync state
/// print(store.isSynced(counter));
/// print(store.clockOf(counter));
///
/// // Disconnect
/// await session.disconnect();
/// ```
extension ReactonStoreCollab on ReactonStore {
  /// Expando-based storage for collaborative sessions associated with stores.
  static final _sessions =
      Expando<List<CollaborativeSession>>('collabSessions');

  /// Returns the list of active collaborative sessions for this store,
  /// creating the list if it does not yet exist.
  List<CollaborativeSession> _getSessions() {
    var sessions = _sessions[this];
    if (sessions == null) {
      sessions = [];
      _sessions[this] = sessions;
    }
    return sessions;
  }

  /// Creates and starts a [CollaborativeSession] that synchronizes the
  /// given [reactons] over the provided [channel].
  ///
  /// The session begins syncing immediately. It subscribes to local changes
  /// on each reacton and listens for remote updates on the channel.
  ///
  /// An optional [defaultStrategy] is provided for reactons that do not
  /// specify their own [CrdtMergeStrategy] (defaults to [LastWriterWins]).
  ///
  /// Returns the [CollaborativeSession] for monitoring status, conflicts,
  /// and disconnection.
  ///
  /// ```dart
  /// final session = store.collaborate(
  ///   channel: webSocketChannel,
  ///   reactons: [counter, tags, config],
  ///   defaultStrategy: LastWriterWins(),
  /// );
  /// ```
  CollaborativeSession collaborate({
    required SyncChannel channel,
    required List<CollaborativeReacton<Object?>> reactons,
    CrdtMergeStrategy<Object?>? defaultStrategy,
  }) {
    // Ensure all reactons are initialized in the store
    for (final reacton in reactons) {
      get(reacton);
    }

    final session = CollaborativeSession._(
      store: this,
      channel: channel,
    );

    session._start(reactons, defaultStrategy: defaultStrategy);
    _getSessions().add(session);

    return session;
  }

  /// Returns `true` if the given [CollaborativeReacton] is currently being
  /// synchronized by an active session.
  ///
  /// A reacton is considered synced if it is tracked by at least one
  /// connected [CollaborativeSession].
  bool isSynced(CollaborativeReacton<Object?> reacton) {
    final sessions = _sessions[this];
    if (sessions == null) return false;

    for (final session in sessions) {
      if (session.isConnected &&
          session._tracked.containsKey(reacton.collaborativeName)) {
        return true;
      }
    }
    return false;
  }

  /// Returns the current [VectorClock] for the given [CollaborativeReacton],
  /// or [VectorClock.zero] if the reacton is not being tracked by any
  /// active session.
  VectorClock clockOf(CollaborativeReacton<Object?> reacton) {
    final sessions = _sessions[this];
    if (sessions == null) return VectorClock.zero();

    for (final session in sessions) {
      final tracked = session._tracked[reacton.collaborativeName];
      if (tracked != null) {
        return tracked.crdtValue.clock;
      }
    }
    return VectorClock.zero();
  }

  /// Returns all active (non-disposed) [CollaborativeSession] instances
  /// associated with this store.
  List<CollaborativeSession> get collaborativeSessions {
    final sessions = _sessions[this];
    if (sessions == null) return const [];
    // Clean up disposed sessions lazily
    sessions.removeWhere((s) => s.isDisposed);
    return List.unmodifiable(sessions);
  }
}
