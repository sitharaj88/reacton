/// Session Recording & Replay for Reacton.
///
/// Provides production-quality state change recording and deterministic
/// replay capabilities. Use this to capture user sessions for debugging,
/// analytics, or QA review.
///
/// ## Quick Start
///
/// ```dart
/// final store = ReactonStore();
/// final counter = reacton(0, name: 'counter');
///
/// // Record
/// final recorder = store.startRecording(metadata: {'user': 'alice'});
/// store.set(counter, 1);
/// store.set(counter, 2);
/// final session = recorder.stop();
///
/// // Export
/// final json = session.exportJson();
///
/// // Replay
/// final player = store.createPlayer();
/// player.load(session);
/// await player.play(speed: 2.0);
/// ```
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show GZipCodec;

import '../core/reacton_base.dart';
import '../store/store.dart';
import '../utils/disposable.dart';

// ---------------------------------------------------------------------------
// StateEvent
// ---------------------------------------------------------------------------

/// A single recorded state change within a session.
///
/// Each [StateEvent] captures the full context of a reacton mutation:
/// which reacton changed, its previous and new values, precise timing
/// information, and optional user-supplied metadata.
///
/// Events are immutable after creation and fully serializable to JSON.
///
/// ```dart
/// final event = StateEvent(
///   refId: 1,
///   refName: 'counter',
///   oldValue: 0,
///   newValue: 1,
///   timestamp: Duration(milliseconds: 1500),
///   wallClock: DateTime.now(),
///   metadata: {'action': 'increment'},
/// );
///
/// final json = event.toJson();
/// final restored = StateEvent.fromJson(json);
/// ```
class StateEvent {
  /// The numeric identifier of the [ReactonRef] that changed.
  final int refId;

  /// The debug name of the reacton, or `'reacton_{id}'` if unnamed.
  final String refName;

  /// The value before this mutation (JSON-encodable).
  final dynamic oldValue;

  /// The value after this mutation (JSON-encodable).
  final dynamic newValue;

  /// Elapsed time since the session recording started.
  final Duration timestamp;

  /// Absolute wall-clock time when this change occurred.
  final DateTime wallClock;

  /// Optional application-supplied annotations.
  ///
  /// Common keys include `'action'`, `'screen'`, `'userId'`, etc.
  /// All values must be JSON-encodable.
  final Map<String, dynamic>? metadata;

  /// Creates a [StateEvent] with the given parameters.
  StateEvent({
    required this.refId,
    required this.refName,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    required this.wallClock,
    this.metadata,
  });

  /// Serializes this event to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'refId': refId,
        'refName': refName,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': timestamp.inMilliseconds,
        'wallClock': wallClock.toUtc().toIso8601String(),
        if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes a [StateEvent] from a JSON map.
  ///
  /// Throws [FormatException] if required fields are missing.
  factory StateEvent.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('refId') || !json.containsKey('refName')) {
      throw const FormatException(
        'StateEvent JSON must contain "refId" and "refName".',
      );
    }
    return StateEvent(
      refId: json['refId'] as int,
      refName: json['refName'] as String,
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      timestamp: Duration(milliseconds: json['timestamp'] as int),
      wallClock: DateTime.parse(json['wallClock'] as String),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  String toString() =>
      'StateEvent($refName: $oldValue -> $newValue @ ${timestamp.inMilliseconds}ms)';
}

// ---------------------------------------------------------------------------
// SessionMark
// ---------------------------------------------------------------------------

/// A named bookmark in a recorded session timeline.
///
/// Markers let callers annotate specific moments in a recording with
/// human-readable labels, making it easy to navigate long sessions during
/// replay.
///
/// ```dart
/// recorder.mark('user_clicked_buy');
/// // Later during replay:
/// player.seekTo(session.markers.first.timestamp);
/// ```
class SessionMark {
  /// The human-readable label for this marker.
  final String label;

  /// The elapsed time from session start when this marker was placed.
  final Duration timestamp;

  /// Optional data associated with this marker.
  final Map<String, dynamic>? metadata;

  /// Creates a [SessionMark] with the given parameters.
  SessionMark({
    required this.label,
    required this.timestamp,
    this.metadata,
  });

  /// Serializes this marker to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'label': label,
        'timestamp': timestamp.inMilliseconds,
        if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes a [SessionMark] from a JSON map.
  factory SessionMark.fromJson(Map<String, dynamic> json) {
    return SessionMark(
      label: json['label'] as String,
      timestamp: Duration(milliseconds: json['timestamp'] as int),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  String toString() =>
      'SessionMark($label @ ${timestamp.inMilliseconds}ms)';
}

// ---------------------------------------------------------------------------
// RecordedSession
// ---------------------------------------------------------------------------

/// A complete, immutable recording of state changes within a [ReactonStore].
///
/// A [RecordedSession] contains every [StateEvent] that occurred between
/// the call to [SessionRecorder.stop] (or the recording start) and the
/// session end, plus the initial store snapshot and session-level metadata.
///
/// Sessions support full JSON serialization (including gzip compression)
/// for storage, transport, and later replay.
///
/// ```dart
/// // Export
/// final json = session.exportJson();
/// final compressed = session.exportCompressed();
///
/// // Import
/// final restored = RecordedSession.fromJson(json);
/// final decompressed = RecordedSession.fromCompressed(compressed);
///
/// // Slice
/// final first5Seconds = session.slice(Duration.zero, Duration(seconds: 5));
///
/// // Filter
/// final counterEvents = session.filter(reactonNames: ['counter']);
/// ```
class RecordedSession {
  /// Unique identifier for this session.
  final String id;

  /// Absolute time when the recording started.
  final DateTime startTime;

  /// Absolute time when the recording stopped, or `null` if still recording.
  final DateTime? endTime;

  /// All state change events, ordered by [StateEvent.timestamp].
  final List<StateEvent> events;

  /// The store snapshot at the moment recording began.
  ///
  /// Keys are reacton debug names, values are their JSON-encodable values.
  final Map<String, dynamic> initialSnapshot;

  /// Named markers placed during the recording.
  final List<SessionMark> markers;

  /// Application-supplied session-level metadata.
  ///
  /// Typical keys: `'appVersion'`, `'userId'`, `'deviceInfo'`, `'platform'`.
  final Map<String, dynamic>? metadata;

  /// Serialization format version. Increment when the schema changes.
  static const int _formatVersion = 1;

  /// Creates a [RecordedSession] with the given data.
  RecordedSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.events,
    required this.initialSnapshot,
    this.markers = const [],
    this.metadata,
  });

  /// Total duration of this session.
  ///
  /// If [endTime] is available, returns the difference from [startTime].
  /// If the session has events, returns the timestamp of the last event.
  /// Otherwise returns [Duration.zero].
  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    if (events.isNotEmpty) {
      return events.last.timestamp;
    }
    return Duration.zero;
  }

  /// The number of state change events in this session.
  int get eventCount => events.length;

  /// The set of unique reacton debug names that were modified.
  Set<String> get reactonsChanged =>
      events.map((e) => e.refName).toSet();

  /// Returns a sub-session containing only events within [from] .. [to].
  ///
  /// Events are re-timestamped relative to [from]. The initial snapshot
  /// is preserved from the original session. Markers within the range
  /// are included and re-timestamped.
  RecordedSession slice(Duration from, Duration to) {
    assert(!from.isNegative, 'from must not be negative');
    assert(to >= from, 'to must be >= from');

    final slicedEvents = events
        .where((e) => e.timestamp >= from && e.timestamp <= to)
        .map((e) => StateEvent(
              refId: e.refId,
              refName: e.refName,
              oldValue: e.oldValue,
              newValue: e.newValue,
              timestamp: e.timestamp - from,
              wallClock: e.wallClock,
              metadata: e.metadata,
            ))
        .toList(growable: false);

    final slicedMarkers = markers
        .where((m) => m.timestamp >= from && m.timestamp <= to)
        .map((m) => SessionMark(
              label: m.label,
              timestamp: m.timestamp - from,
              metadata: m.metadata,
            ))
        .toList(growable: false);

    return RecordedSession(
      id: '${id}_slice',
      startTime: startTime.add(from),
      endTime: startTime.add(to),
      events: slicedEvents,
      initialSnapshot: Map<String, dynamic>.of(initialSnapshot),
      markers: slicedMarkers,
      metadata: metadata,
    );
  }

  /// Returns a sub-session containing only events for the named reactons.
  ///
  /// If [reactonNames] is null or empty, returns the original session.
  RecordedSession filter({List<String>? reactonNames}) {
    if (reactonNames == null || reactonNames.isEmpty) return this;

    final nameSet = reactonNames.toSet();
    final filteredEvents = events
        .where((e) => nameSet.contains(e.refName))
        .toList(growable: false);

    return RecordedSession(
      id: '${id}_filtered',
      startTime: startTime,
      endTime: endTime,
      events: filteredEvents,
      initialSnapshot: Map<String, dynamic>.of(initialSnapshot),
      markers: markers,
      metadata: metadata,
    );
  }

  /// Serializes this session to a JSON string.
  ///
  /// The output conforms to the Reacton Session Recording format v1.
  String exportJson() => jsonEncode(_toJsonMap());

  /// Serializes this session to a gzip-compressed byte list.
  ///
  /// Use [fromCompressed] to restore. Typical compression ratios are
  /// 5x-10x for sessions with many events.
  List<int> exportCompressed() {
    final jsonBytes = utf8.encode(exportJson());
    return GZipCodec().encode(jsonBytes);
  }

  /// Deserializes a [RecordedSession] from a JSON string.
  ///
  /// Throws [FormatException] if the format version is unsupported or
  /// required fields are missing.
  static RecordedSession fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return _fromJsonMap(map);
  }

  /// Decompresses and deserializes a [RecordedSession] from gzip bytes.
  static RecordedSession fromCompressed(List<int> bytes) {
    final jsonBytes = GZipCodec().decode(bytes);
    final json = utf8.decode(jsonBytes);
    return fromJson(json);
  }

  Map<String, dynamic> _toJsonMap() => {
        'id': id,
        'version': _formatVersion,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime?.toUtc().toIso8601String(),
        if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
        'initialSnapshot': initialSnapshot,
        'markers': markers.map((m) => m.toJson()).toList(growable: false),
        'events': events.map((e) => e.toJson()).toList(growable: false),
      };

  static RecordedSession _fromJsonMap(Map<String, dynamic> map) {
    final version = map['version'] as int? ?? 1;
    if (version > _formatVersion) {
      throw FormatException(
        'Unsupported session format version $version '
        '(max supported: $_formatVersion).',
      );
    }

    final eventList = (map['events'] as List)
        .map((e) => StateEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    final markerList = (map['markers'] as List? ?? [])
        .map((m) => SessionMark.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList(growable: false);

    return RecordedSession(
      id: map['id'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      events: eventList,
      initialSnapshot:
          Map<String, dynamic>.from(map['initialSnapshot'] as Map? ?? {}),
      markers: markerList,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  @override
  String toString() =>
      'RecordedSession($id, $eventCount events, ${duration.inMilliseconds}ms)';
}

// ---------------------------------------------------------------------------
// SessionRecorder
// ---------------------------------------------------------------------------

/// Records state changes from a [ReactonStore] in real time.
///
/// The recorder attaches as a listener to the store and captures every
/// state mutation as a [StateEvent]. When stopped, it produces an
/// immutable [RecordedSession] that can be serialized, stored, and
/// later replayed via [SessionPlayer].
///
/// ## Memory efficiency
///
/// Use [maxEvents] to enable circular-buffer mode. When the limit is
/// reached, the oldest events are discarded. This is critical for
/// long-running sessions (e.g., production monitoring).
///
/// ## Batch awareness
///
/// The recorder captures the final values after a [ReactonStore.batch]
/// completes, not the intermediate states within the batch. This matches
/// user-visible behavior.
///
/// ```dart
/// final recorder = store.startRecording(
///   metadata: {'userId': 'alice'},
///   maxEvents: 10000,
/// );
///
/// // ... app runs, state changes are captured ...
///
/// recorder.annotate('screen', 'checkout');
/// recorder.mark('payment_submitted');
///
/// final session = recorder.stop();
/// ```
class SessionRecorder {
  final ReactonStore _store;
  final String _sessionId;
  final Map<String, dynamic>? _sessionMetadata;
  final int? _maxEvents;
  final Set<int>? _reactonRefIds;

  final DateTime _startTime;
  final Map<String, dynamic> _initialSnapshot;

  final List<StateEvent> _events = [];
  final List<SessionMark> _markers = [];
  final List<Unsubscribe> _subscriptions = [];

  Map<String, dynamic>? _pendingAnnotation;

  bool _recording = true;
  bool _paused = false;
  Duration _pausedElapsed = Duration.zero;
  DateTime? _pauseStart;
  DateTime? _stopTime;

  /// Creates a new [SessionRecorder] attached to [store].
  ///
  /// This constructor is intended for internal use. Prefer
  /// [ReactonStoreRecording.startRecording].
  SessionRecorder._({
    required ReactonStore store,
    required String sessionId,
    Map<String, dynamic>? metadata,
    int? maxEvents,
    List<ReactonBase>? reactonsToRecord,
  })  : _store = store,
        _sessionId = sessionId,
        _sessionMetadata = metadata,
        _maxEvents = maxEvents,
        _reactonRefIds = reactonsToRecord?.map((r) => r.ref.id).toSet(),
        _startTime = DateTime.now(),
        _initialSnapshot = _captureSnapshot(store) {
    _attachListeners();
  }

  /// Captures the current store state as a `Map<String, dynamic>`.
  static Map<String, dynamic> _captureSnapshot(ReactonStore store) {
    final snapshot = <String, dynamic>{};
    for (final ref in store.reactonRefs) {
      snapshot[ref.toString()] = store.getByRef(ref);
    }
    return snapshot;
  }

  /// Subscribes to every reacton currently registered in the store.
  void _attachListeners() {
    for (final ref in _store.reactonRefs) {
      if (_reactonRefIds != null && !_reactonRefIds!.contains(ref.id)) {
        continue;
      }
      _subscribeToRef(ref);
    }
  }

  void _subscribeToRef(ReactonRef ref) {
    // Capture the old value at subscription time.
    dynamic previousValue = _store.getByRef(ref);

    void listener(dynamic newValue) {
      if (!_recording || _paused) {
        previousValue = newValue;
        return;
      }

      if (_reactonRefIds != null && !_reactonRefIds!.contains(ref.id)) {
        previousValue = newValue;
        return;
      }

      final event = StateEvent(
        refId: ref.id,
        refName: ref.toString(),
        oldValue: previousValue,
        newValue: newValue,
        timestamp: elapsed,
        wallClock: DateTime.now(),
        metadata: _pendingAnnotation,
      );
      _pendingAnnotation = null;
      _addEvent(event);
      previousValue = newValue;
    }

    // Create a shim ReactonBase that shares the same ReactonRef as the
    // target. This ensures that store.subscribe registers the listener
    // under the correct ref key in the store's internal listener map.
    final shim = _RefShim(ref);
    final unsub = _store.subscribe<dynamic>(shim, listener);
    _subscriptions.add(unsub);
  }

  /// Adds an event, enforcing the circular buffer limit if configured.
  void _addEvent(StateEvent event) {
    _events.add(event);
    if (_maxEvents != null && _events.length > _maxEvents!) {
      _events.removeAt(0);
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether the recorder is actively capturing events.
  ///
  /// Returns `false` after [stop] has been called.
  bool get isRecording => _recording;

  /// Whether the recorder is temporarily paused.
  ///
  /// While paused, state changes are silently skipped.
  bool get isPaused => _paused;

  /// The number of events captured so far.
  int get eventCount => _events.length;

  /// All markers placed during this recording so far.
  List<SessionMark> get markers => List.unmodifiable(_markers);

  /// Elapsed recording time, excluding paused intervals.
  Duration get elapsed {
    if (!_recording) {
      return _stopTime!.difference(_startTime) - _pausedElapsed;
    }
    final now = DateTime.now();
    final total = now.difference(_startTime);
    final paused = _paused
        ? _pausedElapsed + now.difference(_pauseStart!)
        : _pausedElapsed;
    return total - paused;
  }

  /// Temporarily pause recording.
  ///
  /// State changes that occur while paused are not captured.
  /// Call [resume] to continue recording.
  ///
  /// Throws [StateError] if not currently recording or already paused.
  void pause() {
    if (!_recording) {
      throw StateError('Cannot pause: recording has been stopped.');
    }
    if (_paused) {
      throw StateError('Recording is already paused.');
    }
    _paused = true;
    _pauseStart = DateTime.now();
  }

  /// Resume recording after a [pause].
  ///
  /// Throws [StateError] if not currently paused.
  void resume() {
    if (!_paused) {
      throw StateError('Recording is not paused.');
    }
    _pausedElapsed += DateTime.now().difference(_pauseStart!);
    _pauseStart = null;
    _paused = false;
  }

  /// Attach metadata to the next recorded event.
  ///
  /// The annotation map is consumed by the next [StateEvent] and then
  /// cleared. If no event fires before another [annotate] call, the
  /// previous annotation is replaced.
  ///
  /// ```dart
  /// recorder.annotate('action', 'add_to_cart');
  /// store.set(cartItems, updatedItems); // this event gets the annotation
  /// ```
  void annotate(String key, dynamic value) {
    if (!_recording) {
      throw StateError('Cannot annotate: recording has been stopped.');
    }
    _pendingAnnotation ??= {};
    _pendingAnnotation![key] = value;
  }

  /// Place a named marker at the current point in the timeline.
  ///
  /// Markers appear in the [RecordedSession.markers] list and can be
  /// used to navigate during replay via [SessionPlayer.seekTo].
  ///
  /// ```dart
  /// recorder.mark('checkout_started');
  /// ```
  void mark(String label, {Map<String, dynamic>? metadata}) {
    if (!_recording) {
      throw StateError('Cannot mark: recording has been stopped.');
    }
    _markers.add(SessionMark(
      label: label,
      timestamp: elapsed,
      metadata: metadata,
    ));
  }

  /// Stop recording and return the completed [RecordedSession].
  ///
  /// After calling [stop], no further events are captured and the
  /// recorder cannot be restarted. All store subscriptions are cleaned up.
  ///
  /// Throws [StateError] if already stopped.
  RecordedSession stop() {
    if (!_recording) {
      throw StateError('Recording has already been stopped.');
    }

    // If paused, finalize the pause duration.
    if (_paused) {
      _pausedElapsed += DateTime.now().difference(_pauseStart!);
      _paused = false;
      _pauseStart = null;
    }

    _recording = false;
    _stopTime = DateTime.now();

    // Clean up subscriptions.
    for (final unsub in _subscriptions) {
      unsub();
    }
    _subscriptions.clear();

    return RecordedSession(
      id: _sessionId,
      startTime: _startTime,
      endTime: _stopTime,
      events: List<StateEvent>.unmodifiable(_events),
      initialSnapshot: Map<String, dynamic>.unmodifiable(_initialSnapshot),
      markers: List<SessionMark>.unmodifiable(_markers),
      metadata: _sessionMetadata,
    );
  }
}

// ---------------------------------------------------------------------------
// _RefShim (internal)
// ---------------------------------------------------------------------------

/// A lightweight [ReactonBase] shim that reuses an existing [ReactonRef].
///
/// Used internally by [SessionRecorder] to subscribe to reacton changes
/// when only the [ReactonRef] is available (without the original
/// [ReactonBase] instance). The shim shares the same [ReactonRef] identity
/// so that [ReactonStore.subscribe] registers the listener under the
/// correct key in the store's internal listener map.
class _RefShim extends ReactonBase<dynamic> {
  _RefShim(super.ref) : super.fromRef();
}

// ---------------------------------------------------------------------------
// SessionPlayer
// ---------------------------------------------------------------------------

/// Replays a [RecordedSession] against a [ReactonStore].
///
/// The player applies recorded [StateEvent]s to the store in chronological
/// order, respecting the original timing (scaled by [speed]). It supports
/// pause/resume, seeking to arbitrary positions, and single-step navigation.
///
/// Progress and events are exposed as [Stream]s for UI integration
/// (e.g., a scrubber bar or event inspector).
///
/// ## Resource management
///
/// Always call [stop] or [dispose] when done. The player cancels all
/// internal timers and closes all stream controllers on disposal.
///
/// ```dart
/// final player = store.createPlayer();
/// player.load(session);
///
/// player.onProgress.listen((p) => print('${(p * 100).toInt()}%'));
/// await player.play(speed: 2.0);
/// await player.onComplete;
/// player.dispose();
/// ```
class SessionPlayer with Disposable {
  final ReactonStore _store;

  RecordedSession? _session;
  int _eventIndex = 0;
  double _speed = 1.0;
  Timer? _timer;

  bool _playing = false;
  bool _playerPaused = false;

  final StreamController<StateEvent> _onEventController =
      StreamController<StateEvent>.broadcast();
  final StreamController<double> _onProgressController =
      StreamController<double>.broadcast();
  Completer<void>? _completer;

  /// Creates a [SessionPlayer] bound to [store].
  ///
  /// This constructor is intended for internal use. Prefer
  /// [ReactonStoreRecording.createPlayer].
  SessionPlayer(this._store);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Load a [RecordedSession] for replay.
  ///
  /// This resets any previous playback state. The store is restored to
  /// the session's [RecordedSession.initialSnapshot] so that replay
  /// starts from the correct baseline.
  ///
  /// Throws [StateError] if currently playing.
  void load(RecordedSession session) {
    assertNotDisposed();
    if (_playing) {
      throw StateError('Cannot load while playing. Call stop() first.');
    }
    _session = session;
    _eventIndex = 0;
    _playing = false;
    _playerPaused = false;
    _completer = null;

    // Restore the initial snapshot into the store.
    _restoreInitialSnapshot(session);
  }

  void _restoreInitialSnapshot(RecordedSession session) {
    for (final ref in _store.reactonRefs) {
      final name = ref.toString();
      if (session.initialSnapshot.containsKey(name)) {
        _store.setByRefId(ref.id, session.initialSnapshot[name]);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Playback control
  // ---------------------------------------------------------------------------

  /// Start (or restart) replay at the given [speed].
  ///
  /// [speed] is a multiplier: `1.0` = real-time, `2.0` = double speed,
  /// `0.5` = half speed. Supported range: 0.25x to 16x.
  ///
  /// Returns a [Future] that completes when replay finishes or is stopped.
  ///
  /// Throws [StateError] if no session is loaded.
  Future<void> play({double speed = 1.0}) {
    assertNotDisposed();
    if (_session == null) {
      throw StateError('No session loaded. Call load() first.');
    }
    assert(
      speed >= 0.25 && speed <= 16.0,
      'Speed must be between 0.25 and 16.0',
    );

    _speed = speed;
    _playing = true;
    _playerPaused = false;
    _completer = Completer<void>();
    _scheduleNext();
    return _completer!.future;
  }

  /// Pause playback at the current position.
  ///
  /// Throws [StateError] if not currently playing.
  void pause() {
    assertNotDisposed();
    if (!_playing || _playerPaused) {
      throw StateError('Cannot pause: not currently playing.');
    }
    _playerPaused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Resume playback after [pause].
  ///
  /// Throws [StateError] if not currently paused.
  void resume() {
    assertNotDisposed();
    if (!_playerPaused) {
      throw StateError('Cannot resume: not paused.');
    }
    _playerPaused = false;
    _scheduleNext();
  }

  /// Stop playback and leave the store in its current state.
  ///
  /// The [onComplete] future is completed when [stop] is called.
  void stop() {
    assertNotDisposed();
    _timer?.cancel();
    _timer = null;
    _playing = false;
    _playerPaused = false;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
  }

  /// Jump to a specific [position] in the session timeline.
  ///
  /// All events up to [position] are applied to the store immediately
  /// (without delays). Events after [position] are skipped.
  ///
  /// If the player is playing, playback continues from the new position.
  ///
  /// Throws [StateError] if no session is loaded.
  void seekTo(Duration position) {
    assertNotDisposed();
    if (_session == null) {
      throw StateError('No session loaded. Call load() first.');
    }

    _timer?.cancel();
    _timer = null;

    // Restore initial snapshot first.
    _restoreInitialSnapshot(_session!);

    // Apply all events up to the target position.
    _eventIndex = 0;
    for (var i = 0; i < _session!.events.length; i++) {
      final event = _session!.events[i];
      if (event.timestamp > position) break;
      _applyEvent(event, broadcast: false);
      _eventIndex = i + 1;
    }
    _onProgressController.add(progress);

    // If playing, schedule the next event from the new position.
    if (_playing && !_playerPaused) {
      _scheduleNext();
    }
  }

  /// Apply the next event and advance by one step.
  ///
  /// Returns `true` if an event was applied, `false` if the session is
  /// complete (no more events).
  bool stepForward() {
    assertNotDisposed();
    if (_session == null) {
      throw StateError('No session loaded.');
    }
    if (_eventIndex >= _session!.events.length) return false;

    final event = _session!.events[_eventIndex];
    _applyEvent(event, broadcast: true);
    _eventIndex++;
    _onProgressController.add(progress);

    if (_eventIndex >= _session!.events.length) {
      _completePlayback();
    }
    return true;
  }

  /// Undo the most recent event and step backward by one.
  ///
  /// The reacton is set to its [StateEvent.oldValue].
  /// Returns `true` if a step was taken, `false` if already at the start.
  bool stepBackward() {
    assertNotDisposed();
    if (_session == null) {
      throw StateError('No session loaded.');
    }
    if (_eventIndex <= 0) return false;

    _eventIndex--;
    final event = _session!.events[_eventIndex];
    // Apply the old value to reverse this event.
    _applyEventReverse(event);
    _onProgressController.add(progress);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Whether the player is currently playing (including paused state).
  bool get isPlaying => _playing;

  /// Whether the player is currently paused.
  bool get isPaused => _playerPaused;

  /// The current playback position as a [Duration].
  Duration get position {
    if (_session == null || _session!.events.isEmpty) return Duration.zero;
    if (_eventIndex == 0) return Duration.zero;
    if (_eventIndex >= _session!.events.length) return _session!.duration;
    return _session!.events[_eventIndex - 1].timestamp;
  }

  /// Playback progress as a value from `0.0` (start) to `1.0` (end).
  double get progress {
    if (_session == null || _session!.events.isEmpty) return 0.0;
    return _eventIndex / _session!.events.length;
  }

  /// Stream of [StateEvent]s as they are replayed.
  Stream<StateEvent> get onEvent => _onEventController.stream;

  /// Stream of progress updates (0.0 to 1.0).
  Stream<double> get onProgress => _onProgressController.stream;

  /// A [Future] that completes when the current replay finishes.
  ///
  /// Returns a completed future if no replay is in progress.
  Future<void> get onComplete {
    if (_completer == null || _completer!.isCompleted) {
      return Future<void>.value();
    }
    return _completer!.future;
  }

  /// The current playback speed multiplier.
  double get speed => _speed;

  // ---------------------------------------------------------------------------
  // Internal scheduling
  // ---------------------------------------------------------------------------

  void _scheduleNext() {
    if (!_playing || _playerPaused) return;
    if (_session == null) return;
    if (_eventIndex >= _session!.events.length) {
      _completePlayback();
      return;
    }

    final event = _session!.events[_eventIndex];

    // Calculate delay: time between current position and next event,
    // scaled by speed.
    final Duration currentPosition;
    if (_eventIndex == 0) {
      currentPosition = Duration.zero;
    } else {
      currentPosition = _session!.events[_eventIndex - 1].timestamp;
    }

    final rawDelay = event.timestamp - currentPosition;
    final scaledDelay = _scaleDuration(rawDelay, 1.0 / _speed);

    // Clamp to zero (avoid negative durations from rounding).
    final delay = scaledDelay.isNegative ? Duration.zero : scaledDelay;

    _timer = Timer(delay, () {
      if (!_playing || _playerPaused) return;
      _applyEvent(event, broadcast: true);
      _eventIndex++;
      _onProgressController.add(progress);

      if (_eventIndex >= _session!.events.length) {
        _completePlayback();
      } else {
        _scheduleNext();
      }
    });
  }

  void _applyEvent(StateEvent event, {required bool broadcast}) {
    // Apply the new value to the store by ref id.
    try {
      _store.setByRefId(event.refId, event.newValue);
    } on StateError {
      // The reacton may not exist in the store (e.g., if it was removed
      // since the recording). Skip silently during replay.
    }
    if (broadcast) {
      _onEventController.add(event);
    }
  }

  void _applyEventReverse(StateEvent event) {
    try {
      _store.setByRefId(event.refId, event.oldValue);
    } on StateError {
      // Skip if the reacton no longer exists.
    }
  }

  void _completePlayback() {
    _playing = false;
    _playerPaused = false;
    _timer?.cancel();
    _timer = null;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
  }

  @override
  void dispose() {
    stop();
    _onEventController.close();
    _onProgressController.close();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Duration scaling helper
// ---------------------------------------------------------------------------

/// Returns a new [Duration] whose length is [d] scaled by [factor].
///
/// Used by [SessionPlayer] to adjust replay timing based on the
/// playback speed multiplier.
Duration _scaleDuration(Duration d, double factor) {
  return Duration(microseconds: (d.inMicroseconds * factor).round());
}

// ---------------------------------------------------------------------------
// ReactonStoreRecording extension
// ---------------------------------------------------------------------------

/// Expando-backed storage for active recorders and players.
final Expando<SessionRecorder> _activeRecorder =
    Expando<SessionRecorder>('activeRecorder');
final Expando<SessionPlayer> _activePlayer =
    Expando<SessionPlayer>('activePlayer');

/// Adds session recording and replay capabilities to [ReactonStore].
///
/// This extension uses the Expando pattern (consistent with
/// [ReactonStoreModules]) to attach recording state to a store instance
/// without modifying the [ReactonStore] class itself.
///
/// ```dart
/// final store = ReactonStore();
///
/// // Record
/// final recorder = store.startRecording();
/// store.set(counter, 1);
/// final session = recorder.stop();
///
/// // Replay
/// await store.replay(session, speed: 2.0);
/// ```
extension ReactonStoreRecording on ReactonStore {
  /// Start recording all state changes in this store.
  ///
  /// Returns a [SessionRecorder] that captures every mutation until
  /// [SessionRecorder.stop] is called. Only one recording can be active
  /// at a time per store.
  ///
  /// [sessionId] is an optional unique identifier. If omitted, one is
  /// generated from the current timestamp.
  ///
  /// [metadata] is attached to the resulting [RecordedSession] for
  /// identification (app version, user id, device info, etc.).
  ///
  /// [maxEvents] enables circular-buffer mode: when reached, the oldest
  /// events are discarded. Pass `null` (default) for unbounded recording.
  ///
  /// [reactonsToRecord] limits recording to specific reactons. Pass `null`
  /// (default) to record all reactons in the store.
  ///
  /// Throws [StateError] if a recording is already in progress.
  SessionRecorder startRecording({
    String? sessionId,
    Map<String, dynamic>? metadata,
    int? maxEvents,
    List<ReactonBase>? reactonsToRecord,
  }) {
    if (_activeRecorder[this] != null && _activeRecorder[this]!.isRecording) {
      throw StateError(
        'A recording is already in progress. '
        'Call stop() on the current recorder first.',
      );
    }

    final id = sessionId ??
        'session_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

    final recorder = SessionRecorder._(
      store: this,
      sessionId: id,
      metadata: metadata,
      maxEvents: maxEvents,
      reactonsToRecord: reactonsToRecord,
    );
    _activeRecorder[this] = recorder;
    return recorder;
  }

  /// Create a [SessionPlayer] for replaying recorded sessions against
  /// this store.
  ///
  /// The player is reusable: call [SessionPlayer.load] with different
  /// sessions to replay them sequentially.
  SessionPlayer createPlayer() {
    final player = SessionPlayer(this);
    _activePlayer[this] = player;
    return player;
  }

  /// Convenience method: load a session and play it to completion.
  ///
  /// Returns a [Future] that completes when replay finishes.
  ///
  /// ```dart
  /// await store.replay(session, speed: 4.0);
  /// print('Replay complete');
  /// ```
  Future<void> replay(
    RecordedSession session, {
    double speed = 1.0,
  }) {
    final player = createPlayer();
    player.load(session);
    return player.play(speed: speed).whenComplete(() => player.dispose());
  }

  /// Whether this store currently has an active recording.
  bool get isRecording {
    final recorder = _activeRecorder[this];
    return recorder != null && recorder.isRecording;
  }

  /// Whether this store currently has an active replay.
  bool get isReplaying {
    final player = _activePlayer[this];
    return player != null && player.isPlaying;
  }
}
