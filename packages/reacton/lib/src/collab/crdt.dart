/// Core CRDT (Conflict-free Replicated Data Type) primitives for the Reacton
/// collaborative state system.
///
/// This module provides the foundational building blocks for distributed
/// state synchronization:
///
/// - [VectorClock] for causal ordering of events across nodes
/// - [CrdtValue] for wrapping application values with CRDT metadata
/// - [MergeStrategy] for pluggable conflict resolution policies
/// - [SyncMessage] for the wire protocol between peers
/// - [SyncChannel] for abstract transport layer
///
/// ## Consistency Model
///
/// This implementation provides **strong eventual consistency**: all nodes
/// that have received the same set of updates will converge to the same
/// state, regardless of the order in which updates were received.
///
/// ## Wire Protocol
///
/// All sync messages are JSON-serializable for transport over WebSocket,
/// HTTP, or any other channel that can carry UTF-8 strings.
library;

import 'dart:async';
import 'dart:convert';

// ---------------------------------------------------------------------------
// VectorClock
// ---------------------------------------------------------------------------

/// A vector clock for establishing causal ordering between distributed events.
///
/// Each node in the system maintains a counter, and the vector clock tracks
/// the latest known counter for every node. This enables determining whether
/// two events are causally related or concurrent.
///
/// Vector clocks are **immutable** — all mutation methods return new instances.
///
/// ```dart
/// var clock = VectorClock.zero();
/// clock = clock.increment('node-a');  // {node-a: 1}
/// clock = clock.increment('node-a');  // {node-a: 2}
/// ```
///
/// ## Comparison Semantics
///
/// Given clocks A and B:
/// - A **happens before** B if every counter in A is <= the corresponding
///   counter in B, and at least one is strictly less.
/// - A and B are **concurrent** if neither happens before the other.
/// - A **equals** B if all counters are identical.
class VectorClock implements Comparable<VectorClock> {
  /// The internal map of node identifiers to their logical counters.
  ///
  /// This map is unmodifiable; all mutations produce new [VectorClock] instances.
  final Map<String, int> _entries;

  /// Creates a vector clock from the given entries.
  ///
  /// The [entries] map is defensively copied and made unmodifiable.
  VectorClock(Map<String, int> entries)
      : _entries = Map.unmodifiable(Map<String, int>.of(entries));

  /// Creates an empty vector clock (all counters at zero).
  factory VectorClock.zero() => VectorClock(const {});

  /// Returns an unmodifiable view of the clock entries.
  Map<String, int> get entries => _entries;

  /// Returns the counter value for the given [nodeId], or 0 if unknown.
  int operator [](String nodeId) => _entries[nodeId] ?? 0;

  /// Returns a new [VectorClock] with the counter for [nodeId] incremented
  /// by one.
  ///
  /// This should be called on the local node before each state mutation
  /// to advance the causal history.
  VectorClock increment(String nodeId) {
    final updated = Map<String, int>.of(_entries);
    updated[nodeId] = (updated[nodeId] ?? 0) + 1;
    return VectorClock(updated);
  }

  /// Returns a new [VectorClock] that is the pointwise maximum of this clock
  /// and [other].
  ///
  /// The merged clock represents knowledge of all events known to either
  /// clock. This is used when receiving a remote update to advance the
  /// local clock.
  ///
  /// ```dart
  /// final a = VectorClock({'x': 2, 'y': 1});
  /// final b = VectorClock({'x': 1, 'y': 3});
  /// final merged = a.merge(b); // {x: 2, y: 3}
  /// ```
  VectorClock merge(VectorClock other) {
    final merged = Map<String, int>.of(_entries);
    for (final entry in other._entries.entries) {
      final current = merged[entry.key] ?? 0;
      if (entry.value > current) {
        merged[entry.key] = entry.value;
      }
    }
    return VectorClock(merged);
  }

  /// Returns `true` if this clock causally **happens before** [other].
  ///
  /// Formally: every counter in `this` is <= the corresponding counter in
  /// [other], and at least one counter is strictly less.
  bool happensBefore(VectorClock other) {
    bool hasStrictlyLess = false;
    final allKeys = {..._entries.keys, ...other._entries.keys};

    for (final key in allKeys) {
      final local = this[key];
      final remote = other[key];
      if (local > remote) return false;
      if (local < remote) hasStrictlyLess = true;
    }
    return hasStrictlyLess;
  }

  /// Returns `true` if this clock and [other] are **concurrent** — neither
  /// causally precedes the other.
  ///
  /// Concurrent events represent a conflict that must be resolved by a
  /// [MergeStrategy].
  bool isConcurrent(VectorClock other) {
    return !happensBefore(other) && !other.happensBefore(this) && this != other;
  }

  /// Compares two vector clocks for causal ordering.
  ///
  /// Returns:
  /// - A negative value if `this` happens before [other].
  /// - A positive value if [other] happens before `this`.
  /// - Zero if the clocks are equal or concurrent.
  ///
  /// **Note:** A return value of zero does not distinguish between equality
  /// and concurrency. Use [isConcurrent] for that distinction.
  @override
  int compareTo(VectorClock other) {
    if (happensBefore(other)) return -1;
    if (other.happensBefore(this)) return 1;
    return 0;
  }

  /// Returns the sum of all counters, useful as a rough "total events" metric.
  int get sum => _entries.values.fold(0, (a, b) => a + b);

  /// Serializes this vector clock to a JSON-compatible map.
  Map<String, dynamic> toJson() => Map<String, dynamic>.of(_entries);

  /// Deserializes a [VectorClock] from a JSON-compatible map.
  factory VectorClock.fromJson(Map<String, dynamic> json) {
    return VectorClock(
      json.map((key, value) => MapEntry(key, value as int)),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VectorClock) return false;

    final allKeys = {..._entries.keys, ...other._entries.keys};
    for (final key in allKeys) {
      if (this[key] != other[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        _entries.entries.map((e) => Object.hash(e.key, e.value)),
      );

  @override
  String toString() => 'VectorClock($_entries)';
}

// ---------------------------------------------------------------------------
// CrdtValue
// ---------------------------------------------------------------------------

/// A value annotated with CRDT metadata for distributed conflict resolution.
///
/// Every state mutation in the collaborative system produces a [CrdtValue]
/// that carries enough information to determine causal ordering and resolve
/// conflicts:
///
/// - [value] — the application-level state
/// - [clock] — the vector clock at the time of the mutation
/// - [nodeId] — the identifier of the node that produced this mutation
/// - [timestamp] — wall-clock time for last-writer-wins tiebreaking
///
/// [CrdtValue] is immutable. Use [copyWith] to produce modified copies.
class CrdtValue<T> {
  /// The application-level value.
  final T value;

  /// The vector clock capturing the causal context of this value.
  final VectorClock clock;

  /// The identifier of the node that produced this value.
  final String nodeId;

  /// Wall-clock timestamp (milliseconds since epoch) for LWW tiebreaking.
  ///
  /// Wall-clock time is not reliable for ordering in distributed systems,
  /// but serves as a deterministic tiebreaker when vector clocks indicate
  /// concurrency.
  final int timestamp;

  /// Creates a [CrdtValue] with the given metadata.
  const CrdtValue({
    required this.value,
    required this.clock,
    required this.nodeId,
    required this.timestamp,
  });

  /// Creates a copy of this [CrdtValue] with optionally replaced fields.
  CrdtValue<T> copyWith({
    T? value,
    VectorClock? clock,
    String? nodeId,
    int? timestamp,
  }) {
    return CrdtValue<T>(
      value: value ?? this.value,
      clock: clock ?? this.clock,
      nodeId: nodeId ?? this.nodeId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Serializes this [CrdtValue] to a JSON-compatible map.
  ///
  /// The [serializeValue] function is used to convert [T] to a
  /// JSON-compatible representation.
  Map<String, dynamic> toJson(Object? Function(T) serializeValue) {
    return {
      'value': serializeValue(value),
      'clock': clock.toJson(),
      'nodeId': nodeId,
      'timestamp': timestamp,
    };
  }

  /// Deserializes a [CrdtValue] from a JSON-compatible map.
  ///
  /// The [deserializeValue] function is used to convert the JSON
  /// representation back to [T].
  factory CrdtValue.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) deserializeValue,
  ) {
    return CrdtValue<T>(
      value: deserializeValue(json['value']),
      clock: VectorClock.fromJson(json['clock'] as Map<String, dynamic>),
      nodeId: json['nodeId'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  @override
  String toString() => 'CrdtValue(value: $value, node: $nodeId, '
      'clock: $clock, ts: $timestamp)';
}

// ---------------------------------------------------------------------------
// MergeStrategy
// ---------------------------------------------------------------------------

/// A sealed hierarchy of conflict resolution strategies for concurrent CRDT
/// updates.
///
/// When two nodes make changes concurrently (their vector clocks are
/// incomparable), a [CrdtMergeStrategy] determines which value wins.
///
/// Built-in strategies:
/// - [LastWriterWins] — wall-clock timestamp decides (simple, widely used)
/// - [MaxValue] — picks the numerically larger value (GCounter pattern)
/// - [UnionMerge] — takes the union of two sets (GSet pattern)
/// - [CustomMerge] — user-provided merge function
///
/// ```dart
/// // Default: last writer wins
/// final counter = collaborativeReacton(0);
///
/// // GCounter: always take the max
/// final visits = collaborativeReacton(0, strategy: MaxValue<int>());
///
/// // GSet: union of tags
/// final tags = collaborativeReacton(<String>{},
///   strategy: UnionMerge<Set<String>>(),
/// );
/// ```
sealed class CrdtMergeStrategy<T> {
  /// Resolves a conflict between a local and remote value.
  ///
  /// Both [localClock] and [remoteClock] are provided so that strategies
  /// can inspect causal relationships if needed.
  T resolve(
    T localValue,
    T remoteValue,
    VectorClock localClock,
    VectorClock remoteClock,
    int localTimestamp,
    int remoteTimestamp,
  );
}

/// Last-writer-wins conflict resolution based on wall-clock timestamps.
///
/// When timestamps are equal, the value from the lexicographically greater
/// node ID wins, ensuring deterministic resolution across all peers.
///
/// This is the default [MergeStrategy] and is suitable for most use cases
/// where "most recent write wins" semantics are acceptable.
class LastWriterWins<T> extends CrdtMergeStrategy<T> {
  /// Optional node ID tiebreaker override.
  ///
  /// By default, when timestamps are equal, the lexicographically greater
  /// node ID wins.
  final String? localNodeId;

  /// Creates a [LastWriterWins] strategy.
  LastWriterWins({this.localNodeId});

  @override
  T resolve(
    T localValue,
    T remoteValue,
    VectorClock localClock,
    VectorClock remoteClock,
    int localTimestamp,
    int remoteTimestamp,
  ) {
    if (remoteTimestamp > localTimestamp) return remoteValue;
    if (localTimestamp > remoteTimestamp) return localValue;

    // Tiebreak on node ID for determinism.
    // Both peers must reach the same result, so we pick the value from
    // the lexicographically greater node.
    final localNode = localNodeId ?? '';
    final remoteNode =
        remoteClock.entries.keys.where((k) => k != localNode).firstOrNull ?? '';
    return remoteNode.compareTo(localNode) > 0 ? remoteValue : localValue;
  }
}

/// Max-value conflict resolution (GCounter pattern).
///
/// Always picks the numerically greater value. Suitable for monotonically
/// increasing counters where each node increments independently.
///
/// [T] must implement [Comparable].
class MaxValue<T extends Comparable<T>> extends CrdtMergeStrategy<T> {
  /// Creates a [MaxValue] strategy.
  MaxValue();

  @override
  T resolve(
    T localValue,
    T remoteValue,
    VectorClock localClock,
    VectorClock remoteClock,
    int localTimestamp,
    int remoteTimestamp,
  ) {
    return localValue.compareTo(remoteValue) >= 0 ? localValue : remoteValue;
  }
}

/// Union-merge conflict resolution (GSet pattern).
///
/// Takes the union of two [Set] values. Elements are never removed;
/// this implements grow-only set (GSet) semantics.
///
/// ```dart
/// final tags = collaborativeReacton<Set<String>>(
///   {},
///   strategy: UnionMerge<Set<String>>(),
/// );
/// ```
class UnionMerge<T extends Set> extends CrdtMergeStrategy<T> {
  /// Creates a [UnionMerge] strategy.
  UnionMerge();

  @override
  T resolve(
    T localValue,
    T remoteValue,
    VectorClock localClock,
    VectorClock remoteClock,
    int localTimestamp,
    int remoteTimestamp,
  ) {
    // The union is safe because Set.union returns Set<E>, which we cast to T.
    // ignore: unnecessary_cast
    return localValue.union(remoteValue) as T;
  }
}

/// Custom merge function for application-specific conflict resolution.
///
/// Use this when the built-in strategies are insufficient. The merge function
/// receives both values and their vector clocks, giving full control over
/// the resolution logic.
///
/// **Important:** The merge function must be **deterministic** and
/// **commutative** — `merge(a, b)` must equal `merge(b, a)` for all
/// inputs — to guarantee convergence across all peers.
///
/// ```dart
/// final doc = collaborativeReacton(
///   Document.empty(),
///   strategy: CustomMerge<Document>((local, remote, lc, rc) {
///     return Document.merge(local, remote);
///   }),
/// );
/// ```
class CustomMerge<T> extends CrdtMergeStrategy<T> {
  /// The user-provided merge function.
  final T Function(
    T local,
    T remote,
    VectorClock localClock,
    VectorClock remoteClock,
  ) _mergeFn;

  /// Creates a [CustomMerge] strategy with the given merge function.
  CustomMerge(this._mergeFn);

  @override
  T resolve(
    T localValue,
    T remoteValue,
    VectorClock localClock,
    VectorClock remoteClock,
    int localTimestamp,
    int remoteTimestamp,
  ) {
    return _mergeFn(localValue, remoteValue, localClock, remoteClock);
  }
}

// ---------------------------------------------------------------------------
// SyncMessage
// ---------------------------------------------------------------------------

/// A sealed hierarchy of wire-protocol messages for CRDT state synchronization.
///
/// All messages are JSON-serializable via [toJson] and can be deserialized
/// via [SyncMessage.fromJson].
///
/// ## Protocol Flow
///
/// 1. New peer connects and sends [SyncRequestFull] to request full state.
/// 2. Existing peer responds with [SyncFull] containing all tracked state.
/// 3. Subsequent mutations are sent as [SyncDelta] messages.
/// 4. Receiver sends [SyncAck] to confirm receipt (optional, for delivery
///    guarantees).
///
/// ## Message Types
///
/// - [SyncFull] — Complete state snapshot for a specific reacton.
/// - [SyncDelta] — Incremental update for a specific reacton.
/// - [SyncAck] — Acknowledgment of a received message.
/// - [SyncRequestFull] — Request for full state of specific reactons.
sealed class SyncMessage {
  /// The type discriminator for JSON serialization.
  String get type;

  /// Serializes this message to a JSON-compatible map.
  Map<String, dynamic> toJson();

  /// Serializes this message to a JSON string for wire transport.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes a [SyncMessage] from a JSON-compatible map.
  ///
  /// The [deserializeValue] callback is used to reconstruct application-level
  /// values from their JSON representation.
  ///
  /// Throws [FormatException] if the message type is unknown.
  static SyncMessage fromJson(
    Map<String, dynamic> json, {
    required Object? Function(String reactonName, Object? raw)
        deserializeValue,
  }) {
    final type = json['type'] as String;
    switch (type) {
      case 'sync_full':
        return SyncFull._fromJson(json, deserializeValue);
      case 'sync_delta':
        return SyncDelta._fromJson(json, deserializeValue);
      case 'sync_ack':
        return SyncAck._fromJson(json);
      case 'sync_request_full':
        return SyncRequestFull._fromJson(json);
      default:
        throw FormatException('Unknown SyncMessage type: $type');
    }
  }

  /// Deserializes a [SyncMessage] from a JSON string.
  static SyncMessage fromJsonString(
    String raw, {
    required Object? Function(String reactonName, Object? raw)
        deserializeValue,
  }) {
    return fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      deserializeValue: deserializeValue,
    );
  }
}

/// Full state synchronization message.
///
/// Sent in response to a [SyncRequestFull] to bring a new peer up to date,
/// or periodically as a consistency checkpoint.
class SyncFull extends SyncMessage {
  /// The name identifying the collaborative reacton.
  final String reactonName;

  /// The complete current value with CRDT metadata.
  final CrdtValue<Object?> crdtValue;

  /// The source node that sent this message.
  final String sourceNodeId;

  /// Creates a [SyncFull] message.
  SyncFull({
    required this.reactonName,
    required this.crdtValue,
    required this.sourceNodeId,
  });

  @override
  String get type => 'sync_full';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'reactonName': reactonName,
        'crdtValue': crdtValue.toJson((v) => v),
        'sourceNodeId': sourceNodeId,
      };

  static SyncFull _fromJson(
    Map<String, dynamic> json,
    Object? Function(String, Object?) deserializeValue,
  ) {
    final name = json['reactonName'] as String;
    return SyncFull(
      reactonName: name,
      crdtValue: CrdtValue.fromJson(
        json['crdtValue'] as Map<String, dynamic>,
        (raw) => deserializeValue(name, raw),
      ),
      sourceNodeId: json['sourceNodeId'] as String,
    );
  }
}

/// Incremental state update message.
///
/// Sent whenever a collaborative reacton's value changes locally.
/// The receiver merges the delta using its configured [MergeStrategy].
class SyncDelta extends SyncMessage {
  /// The name identifying the collaborative reacton.
  final String reactonName;

  /// The updated value with CRDT metadata.
  final CrdtValue<Object?> crdtValue;

  /// The source node that produced this delta.
  final String sourceNodeId;

  /// Creates a [SyncDelta] message.
  SyncDelta({
    required this.reactonName,
    required this.crdtValue,
    required this.sourceNodeId,
  });

  @override
  String get type => 'sync_delta';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'reactonName': reactonName,
        'crdtValue': crdtValue.toJson((v) => v),
        'sourceNodeId': sourceNodeId,
      };

  static SyncDelta _fromJson(
    Map<String, dynamic> json,
    Object? Function(String, Object?) deserializeValue,
  ) {
    final name = json['reactonName'] as String;
    return SyncDelta(
      reactonName: name,
      crdtValue: CrdtValue.fromJson(
        json['crdtValue'] as Map<String, dynamic>,
        (raw) => deserializeValue(name, raw),
      ),
      sourceNodeId: json['sourceNodeId'] as String,
    );
  }
}

/// Acknowledgment message confirming receipt of a sync update.
///
/// Sent by the receiver after successfully processing a [SyncFull] or
/// [SyncDelta]. The sender can use this to track delivery status and
/// implement at-least-once delivery semantics.
class SyncAck extends SyncMessage {
  /// The name of the reacton whose update was acknowledged.
  final String reactonName;

  /// The vector clock of the acknowledged state.
  final VectorClock ackedClock;

  /// The node that sent the acknowledgment.
  final String sourceNodeId;

  /// Creates a [SyncAck] message.
  SyncAck({
    required this.reactonName,
    required this.ackedClock,
    required this.sourceNodeId,
  });

  @override
  String get type => 'sync_ack';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'reactonName': reactonName,
        'ackedClock': ackedClock.toJson(),
        'sourceNodeId': sourceNodeId,
      };

  static SyncAck _fromJson(Map<String, dynamic> json) {
    return SyncAck(
      reactonName: json['reactonName'] as String,
      ackedClock:
          VectorClock.fromJson(json['ackedClock'] as Map<String, dynamic>),
      sourceNodeId: json['sourceNodeId'] as String,
    );
  }
}

/// Request for full state synchronization.
///
/// Sent by a newly connected peer to request the complete current state
/// of one or more collaborative reactons.
class SyncRequestFull extends SyncMessage {
  /// The names of the reactons to request full state for.
  ///
  /// If empty, the receiver should send full state for all tracked reactons.
  final List<String> reactonNames;

  /// The node requesting the full sync.
  final String sourceNodeId;

  /// Creates a [SyncRequestFull] message.
  SyncRequestFull({
    required this.reactonNames,
    required this.sourceNodeId,
  });

  @override
  String get type => 'sync_request_full';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'reactonNames': reactonNames,
        'sourceNodeId': sourceNodeId,
      };

  static SyncRequestFull _fromJson(Map<String, dynamic> json) {
    return SyncRequestFull(
      reactonNames: (json['reactonNames'] as List).cast<String>(),
      sourceNodeId: json['sourceNodeId'] as String,
    );
  }
}

// ---------------------------------------------------------------------------
// SyncChannel
// ---------------------------------------------------------------------------

/// Abstract transport layer for CRDT synchronization.
///
/// Implementations wrap a specific transport mechanism (WebSocket, HTTP
/// long-polling, BLE, etc.) and provide a bidirectional string-based
/// message channel.
///
/// The channel contract:
/// - [incoming] delivers messages from remote peers.
/// - [send] transmits a message to remote peers.
/// - [close] gracefully shuts down the transport.
/// - [localNodeId] uniquely identifies this endpoint.
///
/// ## Implementing a Custom Channel
///
/// ```dart
/// class MyChannel extends SyncChannel {
///   @override
///   String get localNodeId => _myUniqueId;
///
///   @override
///   Stream<String> get incoming => _myIncomingStream;
///
///   @override
///   void send(String message) => _myTransport.send(message);
///
///   @override
///   Future<void> close() async => await _myTransport.close();
/// }
/// ```
abstract class SyncChannel {
  /// A unique identifier for this node in the distributed system.
  ///
  /// This is used as the key in [VectorClock] entries and must be stable
  /// across reconnections for the same logical node.
  String get localNodeId;

  /// A stream of incoming messages from remote peers.
  ///
  /// Each message is a JSON-encoded string that can be deserialized via
  /// [SyncMessage.fromJsonString].
  ///
  /// The stream should emit a done event when the connection is closed.
  /// Errors on this stream represent transport-level failures.
  Stream<String> get incoming;

  /// Sends a JSON-encoded message string to remote peers.
  ///
  /// Implementations should handle buffering and backpressure as
  /// appropriate for the underlying transport.
  ///
  /// Throws [StateError] if the channel is closed.
  void send(String message);

  /// Gracefully closes the transport connection.
  ///
  /// After calling [close], [send] must not be called and [incoming]
  /// should complete.
  Future<void> close();
}

// ---------------------------------------------------------------------------
// InMemorySyncChannel (for testing and in-process sync)
// ---------------------------------------------------------------------------

/// An in-memory [SyncChannel] backed by Dart streams.
///
/// Useful for testing and for in-process synchronization between isolates
/// or zones. Create a pair of connected channels via [InMemorySyncChannel.pair].
///
/// ```dart
/// final (channelA, channelB) = InMemorySyncChannel.pair('a', 'b');
/// channelA.send('hello'); // channelB.incoming receives 'hello'
/// channelB.send('world'); // channelA.incoming receives 'world'
/// ```
class InMemorySyncChannel extends SyncChannel {
  final String _localNodeId;
  final Stream<String> _incoming;
  final void Function(String) _sendFn;
  final Future<void> Function() _closeFn;
  bool _closed = false;

  InMemorySyncChannel._({
    required String localNodeId,
    required Stream<String> incoming,
    required void Function(String) sendFn,
    required Future<void> Function() closeFn,
  })  : _localNodeId = localNodeId,
        _incoming = incoming,
        _sendFn = sendFn,
        _closeFn = closeFn;

  /// Creates a pair of connected in-memory channels.
  ///
  /// Messages sent on one channel appear on the other's [incoming] stream.
  static (InMemorySyncChannel, InMemorySyncChannel) pair(
    String nodeIdA,
    String nodeIdB,
  ) {
    final controllerAToB =
        _BroadcastStreamController<String>();
    final controllerBToA =
        _BroadcastStreamController<String>();

    final channelA = InMemorySyncChannel._(
      localNodeId: nodeIdA,
      incoming: controllerBToA.stream,
      sendFn: (msg) {
        if (!controllerAToB.isClosed) {
          controllerAToB.add(msg);
        }
      },
      closeFn: () async {
        await controllerAToB.close();
        await controllerBToA.close();
      },
    );

    final channelB = InMemorySyncChannel._(
      localNodeId: nodeIdB,
      incoming: controllerAToB.stream,
      sendFn: (msg) {
        if (!controllerBToA.isClosed) {
          controllerBToA.add(msg);
        }
      },
      closeFn: () async {
        await controllerAToB.close();
        await controllerBToA.close();
      },
    );

    return (channelA, channelB);
  }

  @override
  String get localNodeId => _localNodeId;

  @override
  Stream<String> get incoming => _incoming;

  @override
  void send(String message) {
    if (_closed) {
      throw StateError('Cannot send on a closed InMemorySyncChannel');
    }
    _sendFn(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _closeFn();
  }
}

/// Internal wrapper around a broadcast [StreamController] that tracks
/// its closed state without relying on [StreamController.isClosed] timing.
class _BroadcastStreamController<T> {
  final _controller = _SyncBroadcastController<T>();
  bool _isClosed = false;

  bool get isClosed => _isClosed;

  Stream<T> get stream => _controller.stream;

  void add(T event) {
    if (!_isClosed) {
      _controller.add(event);
    }
  }

  Future<void> close() async {
    if (!_isClosed) {
      _isClosed = true;
      await _controller.close();
    }
  }
}

/// A synchronous broadcast stream controller that does not buffer events.
///
/// This avoids the microtask scheduling overhead of the default
/// [StreamController.broadcast] and ensures that messages are delivered
/// synchronously in tests.
class _SyncBroadcastController<T> {
  final _listeners = <void Function(T)>[];
  bool _isClosed = false;

  /// A broadcast stream backed by this controller.
  late final Stream<T> stream = _SyncBroadcastStream<T>(this);

  void add(T event) {
    if (_isClosed) return;
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }

  Future<void> close() async {
    _isClosed = true;
    _listeners.clear();
  }

  void _addListener(void Function(T) onData) {
    _listeners.add(onData);
  }

  void _removeListener(void Function(T) onData) {
    _listeners.remove(onData);
  }
}

class _SyncBroadcastStream<T> extends Stream<T> {
  final _SyncBroadcastController<T> _controller;

  _SyncBroadcastStream(this._controller);

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final sub = _SyncBroadcastSubscription<T>(
      _controller,
      onData,
      onDone,
    );
    if (onData != null) {
      _controller._addListener(onData);
    }
    return sub;
  }
}

class _SyncBroadcastSubscription<T> implements StreamSubscription<T> {
  final _SyncBroadcastController<T> _controller;
  void Function(T)? _onData;

  // ignore: unused_field, stored for asFuture completion callback
  void Function()? _onDone;
  bool _cancelled = false;

  _SyncBroadcastSubscription(this._controller, this._onData, this._onDone);

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    if (_onData != null) {
      _controller._removeListener(_onData!);
    }
  }

  @override
  void onData(void Function(T data)? handleData) {
    if (_onData != null) {
      _controller._removeListener(_onData!);
    }
    _onData = handleData;
    if (handleData != null) {
      _controller._addListener(handleData);
    }
  }

  @override
  void onDone(void Function()? handleDone) {
    _onDone = handleDone;
  }

  @override
  void onError(Function? handleError) {
    // Errors are not supported on this simple broadcast stream.
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    // No-op for broadcast subscriptions.
  }

  @override
  void resume() {
    // No-op for broadcast subscriptions.
  }

  @override
  bool get isPaused => false;

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    final completer = Completer<E>();
    _onDone = () => completer.complete(futureValue as E);
    return completer.future;
  }
}

// ---------------------------------------------------------------------------
// ConflictEvent
// ---------------------------------------------------------------------------

/// Describes a conflict that was detected and automatically resolved
/// during CRDT merge.
///
/// Emitted on the [CollaborativeSession.onConflict] stream to allow
/// the application layer to display notifications, log analytics, or
/// take corrective action.
class ConflictEvent<T> {
  /// The name of the collaborative reacton where the conflict occurred.
  final String reactonName;

  /// The local value before merge.
  final T localValue;

  /// The remote value that conflicted.
  final T remoteValue;

  /// The value that was chosen after conflict resolution.
  final T resolvedValue;

  /// The merge strategy that was used.
  final CrdtMergeStrategy<T> strategy;

  /// The local vector clock at the time of conflict.
  final VectorClock localClock;

  /// The remote vector clock at the time of conflict.
  final VectorClock remoteClock;

  /// Creates a [ConflictEvent].
  const ConflictEvent({
    required this.reactonName,
    required this.localValue,
    required this.remoteValue,
    required this.resolvedValue,
    required this.strategy,
    required this.localClock,
    required this.remoteClock,
  });

  @override
  String toString() => 'ConflictEvent($reactonName: '
      'local=$localValue, remote=$remoteValue, '
      'resolved=$resolvedValue)';
}

// ---------------------------------------------------------------------------
// SyncStatus
// ---------------------------------------------------------------------------

/// The synchronization status of a [CollaborativeSession].
enum SyncStatus {
  /// Not connected to any sync channel.
  disconnected,

  /// Connection is being established or full sync is in progress.
  connecting,

  /// Fully connected and actively syncing.
  connected,

  /// Connection was lost; automatic reconnection may be in progress.
  reconnecting,
}
