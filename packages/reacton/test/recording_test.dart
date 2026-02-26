import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  group('SessionRecorder', () {
    late ReactonStore store;
    late WritableReacton<int> counter;
    late WritableReacton<String> label;

    setUp(() {
      store = ReactonStore();
      counter = reacton(0, name: 'counter');
      label = reacton('initial', name: 'label');
      // Initialize reactons in the store.
      store.get(counter);
      store.get(label);
    });

    tearDown(() {
      store.dispose();
    });

    // -----------------------------------------------------------------------
    // Start recording captures initial snapshot
    // -----------------------------------------------------------------------

    group('start recording', () {
      test('captures initial snapshot of all reactons', () {
        final recorder = store.startRecording();
        final session = recorder.stop();

        // The initial snapshot should contain the current values.
        expect(session.initialSnapshot, isNotEmpty);
        expect(session.id, isNotEmpty);
        expect(session.startTime, isNotNull);
        expect(session.endTime, isNotNull);
      });

      test('accepts custom session ID and metadata', () {
        final recorder = store.startRecording(
          sessionId: 'my-session',
          metadata: {'userId': 'alice', 'version': '1.0'},
        );
        final session = recorder.stop();

        expect(session.id, 'my-session');
        expect(session.metadata, isNotNull);
        expect(session.metadata!['userId'], 'alice');
      });

      test('isRecording is true after starting', () {
        final recorder = store.startRecording();
        expect(recorder.isRecording, isTrue);
        expect(store.isRecording, isTrue);
        recorder.stop();
      });

      test('throws StateError if recording is already in progress', () {
        final recorder = store.startRecording();
        expect(
          () => store.startRecording(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already in progress'),
          )),
        );
        recorder.stop();
      });
    });

    // -----------------------------------------------------------------------
    // State changes recorded as StateEvents
    // -----------------------------------------------------------------------

    group('state change recording', () {
      test('records state changes as StateEvents', () {
        final recorder = store.startRecording();

        store.set(counter, 1);
        store.set(counter, 2);
        store.set(counter, 3);

        final session = recorder.stop();

        expect(session.events.length, 3);
        expect(session.events[0].newValue, 1);
        expect(session.events[0].oldValue, 0);
        expect(session.events[1].newValue, 2);
        expect(session.events[1].oldValue, 1);
        expect(session.events[2].newValue, 3);
        expect(session.events[2].oldValue, 2);
      });

      test('events have correct refName', () {
        final recorder = store.startRecording();
        store.set(counter, 10);
        final session = recorder.stop();

        expect(session.events.first.refName, contains('counter'));
      });

      test('events have increasing timestamps', () {
        final recorder = store.startRecording();
        store.set(counter, 1);
        store.set(counter, 2);
        final session = recorder.stop();

        expect(
          session.events[1].timestamp,
          greaterThanOrEqualTo(session.events[0].timestamp),
        );
      });

      test('events have wall clock timestamps', () {
        final recorder = store.startRecording();
        store.set(counter, 1);
        final session = recorder.stop();

        expect(session.events.first.wallClock, isNotNull);
      });

      test('records changes to multiple reactons', () {
        final recorder = store.startRecording();
        store.set(counter, 1);
        store.set(label, 'updated');
        final session = recorder.stop();

        expect(session.events.length, 2);
        final names = session.events.map((e) => e.refName).toSet();
        expect(names.length, 2);
      });

      test('eventCount reflects captured events', () {
        final recorder = store.startRecording();
        store.set(counter, 1);
        store.set(counter, 2);
        expect(recorder.eventCount, 2);
        recorder.stop();
      });
    });

    // -----------------------------------------------------------------------
    // Pause / resume excludes paused time
    // -----------------------------------------------------------------------

    group('pause / resume', () {
      test('paused state changes are not recorded', () {
        final recorder = store.startRecording();
        store.set(counter, 1);

        recorder.pause();
        store.set(counter, 2); // should be skipped
        store.set(counter, 3); // should be skipped

        recorder.resume();
        store.set(counter, 4);

        final session = recorder.stop();

        // Only events 1 and 4 should be captured.
        expect(session.events.length, 2);
        expect(session.events[0].newValue, 1);
        expect(session.events[1].newValue, 4);
      });

      test('isPaused reflects current state', () {
        final recorder = store.startRecording();
        expect(recorder.isPaused, isFalse);

        recorder.pause();
        expect(recorder.isPaused, isTrue);

        recorder.resume();
        expect(recorder.isPaused, isFalse);

        recorder.stop();
      });

      test('pause when already paused throws StateError', () {
        final recorder = store.startRecording();
        recorder.pause();
        expect(() => recorder.pause(), throwsA(isA<StateError>()));
        recorder.resume();
        recorder.stop();
      });

      test('resume when not paused throws StateError', () {
        final recorder = store.startRecording();
        expect(() => recorder.resume(), throwsA(isA<StateError>()));
        recorder.stop();
      });

      test('pause after stop throws StateError', () {
        final recorder = store.startRecording();
        recorder.stop();
        expect(() => recorder.pause(), throwsA(isA<StateError>()));
      });
    });

    // -----------------------------------------------------------------------
    // Markers placed at correct timestamps
    // -----------------------------------------------------------------------

    group('markers', () {
      test('mark places a marker at the current elapsed time', () {
        final recorder = store.startRecording();
        store.set(counter, 1);

        recorder.mark('checkpoint_a');
        store.set(counter, 2);
        recorder.mark('checkpoint_b');

        final session = recorder.stop();

        expect(session.markers.length, 2);
        expect(session.markers[0].label, 'checkpoint_a');
        expect(session.markers[1].label, 'checkpoint_b');
        expect(
          session.markers[1].timestamp,
          greaterThanOrEqualTo(session.markers[0].timestamp),
        );
      });

      test('mark supports optional metadata', () {
        final recorder = store.startRecording();
        recorder.mark('event', metadata: {'screen': 'home'});

        final session = recorder.stop();

        expect(session.markers.first.metadata, isNotNull);
        expect(session.markers.first.metadata!['screen'], 'home');
      });

      test('markers list is accessible during recording', () {
        final recorder = store.startRecording();
        recorder.mark('a');
        recorder.mark('b');
        expect(recorder.markers.length, 2);
        recorder.stop();
      });

      test('mark after stop throws StateError', () {
        final recorder = store.startRecording();
        recorder.stop();
        expect(() => recorder.mark('late'), throwsA(isA<StateError>()));
      });
    });

    // -----------------------------------------------------------------------
    // Annotations attached to events
    // -----------------------------------------------------------------------

    group('annotations', () {
      test('annotate attaches metadata to next event', () {
        final recorder = store.startRecording();

        recorder.annotate('action', 'increment');
        store.set(counter, 1);

        final session = recorder.stop();

        expect(session.events.first.metadata, isNotNull);
        expect(session.events.first.metadata!['action'], 'increment');
      });

      test('annotation is consumed by the next event only', () {
        final recorder = store.startRecording();

        recorder.annotate('action', 'first');
        store.set(counter, 1);
        store.set(counter, 2); // should NOT have annotation

        final session = recorder.stop();

        expect(session.events[0].metadata, isNotNull);
        expect(session.events[0].metadata!['action'], 'first');
        expect(session.events[1].metadata, isNull);
      });

      test('annotate after stop throws StateError', () {
        final recorder = store.startRecording();
        recorder.stop();
        expect(
          () => recorder.annotate('key', 'value'),
          throwsA(isA<StateError>()),
        );
      });

      test('multiple annotate calls before event merges keys', () {
        final recorder = store.startRecording();
        recorder.annotate('key1', 'val1');
        recorder.annotate('key2', 'val2');
        store.set(counter, 1);

        final session = recorder.stop();

        expect(session.events.first.metadata!['key1'], 'val1');
        expect(session.events.first.metadata!['key2'], 'val2');
      });
    });

    // -----------------------------------------------------------------------
    // Stop returns immutable RecordedSession
    // -----------------------------------------------------------------------

    group('stop', () {
      test('returns a RecordedSession with endTime', () {
        final recorder = store.startRecording(sessionId: 'test-stop');
        store.set(counter, 1);
        final session = recorder.stop();

        expect(session.endTime, isNotNull);
        expect(session.id, 'test-stop');
        expect(session.events.length, 1);
      });

      test('isRecording is false after stop', () {
        final recorder = store.startRecording();
        recorder.stop();
        expect(recorder.isRecording, isFalse);
      });

      test('double stop throws StateError', () {
        final recorder = store.startRecording();
        recorder.stop();
        expect(() => recorder.stop(), throwsA(isA<StateError>()));
      });

      test('stop while paused finalizes pause duration', () {
        final recorder = store.startRecording();
        store.set(counter, 1);
        recorder.pause();
        final session = recorder.stop();
        expect(session.events.length, 1);
        expect(recorder.isPaused, isFalse);
      });

      test('no more events captured after stop', () {
        final recorder = store.startRecording();
        store.set(counter, 1);
        final session = recorder.stop();

        store.set(counter, 2); // should not be captured
        expect(session.events.length, 1);
      });
    });

    // -----------------------------------------------------------------------
    // RecordedSession.exportJson() / fromJson() round-trip
    // -----------------------------------------------------------------------

    group('RecordedSession JSON serialization', () {
      test('exportJson / fromJson round-trip preserves data', () {
        final recorder = store.startRecording(
          sessionId: 'json-test',
          metadata: {'user': 'bob'},
        );
        store.set(counter, 1);
        store.set(counter, 2);
        recorder.mark('midpoint');
        store.set(counter, 3);
        final session = recorder.stop();

        final json = session.exportJson();
        final restored = RecordedSession.fromJson(json);

        expect(restored.id, session.id);
        expect(restored.events.length, session.events.length);
        expect(restored.markers.length, session.markers.length);
        expect(restored.markers.first.label, 'midpoint');
        expect(restored.metadata?['user'], 'bob');
        expect(restored.events[0].newValue, 1);
        expect(restored.events[2].newValue, 3);
      });

      test('exportJson produces valid JSON', () {
        final recorder = store.startRecording(sessionId: 'valid-json');
        store.set(counter, 42);
        final session = recorder.stop();

        final json = session.exportJson();
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('fromJson rejects unsupported version', () {
        final json = jsonEncode({
          'id': 'test',
          'version': 999,
          'startTime': DateTime.now().toUtc().toIso8601String(),
          'initialSnapshot': {},
          'events': [],
        });

        expect(
          () => RecordedSession.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // RecordedSession.exportCompressed / fromCompressed
    // -----------------------------------------------------------------------

    group('compressed serialization', () {
      test('exportCompressed / fromCompressed round-trip', () {
        final recorder = store.startRecording(sessionId: 'compress-test');
        store.set(counter, 1);
        store.set(counter, 2);
        final session = recorder.stop();

        final compressed = session.exportCompressed();
        expect(compressed, isNotEmpty);

        final restored = RecordedSession.fromCompressed(compressed);
        expect(restored.id, session.id);
        expect(restored.events.length, 2);
      });
    });

    // -----------------------------------------------------------------------
    // RecordedSession.slice() extracts time range
    // -----------------------------------------------------------------------

    group('RecordedSession.slice()', () {
      test('extracts events within the given time range', () {
        final recorder = store.startRecording(sessionId: 'slice-test');
        store.set(counter, 1);
        store.set(counter, 2);
        store.set(counter, 3);
        final session = recorder.stop();

        // Slice should include events within the time range.
        final sliced = session.slice(Duration.zero, session.duration);

        expect(sliced.events.length, session.events.length);
        expect(sliced.id, contains('slice'));
      });

      test('slice with narrow range may exclude events', () {
        final recorder = store.startRecording(sessionId: 'narrow-slice');
        store.set(counter, 1);
        final session = recorder.stop();

        // Use a range that starts after all events.
        final sliced = session.slice(
          const Duration(hours: 1),
          const Duration(hours: 2),
        );

        expect(sliced.events, isEmpty);
      });

      test('slice re-timestamps events relative to from', () {
        final recorder = store.startRecording(sessionId: 're-timestamp');
        store.set(counter, 1);
        store.set(counter, 2);
        final session = recorder.stop();

        if (session.events.length >= 2) {
          final from = session.events.first.timestamp;
          final to = session.duration;
          final sliced = session.slice(from, to);

          // First event in slice should have timestamp relative to 'from'.
          expect(sliced.events.first.timestamp, Duration.zero);
        }
      });

      test('slice preserves initial snapshot', () {
        final recorder = store.startRecording(sessionId: 'snapshot-slice');
        store.set(counter, 1);
        final session = recorder.stop();

        final sliced = session.slice(Duration.zero, session.duration);
        expect(sliced.initialSnapshot, isNotEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // RecordedSession.filter() by reacton name
    // -----------------------------------------------------------------------

    group('RecordedSession.filter()', () {
      test('filters events by reacton name', () {
        final recorder = store.startRecording(sessionId: 'filter-test');
        store.set(counter, 1);
        store.set(label, 'changed');
        store.set(counter, 2);
        final session = recorder.stop();

        final counterName = session.events
            .firstWhere((e) => e.newValue == 1)
            .refName;
        final filtered = session.filter(reactonNames: [counterName]);

        expect(filtered.events.length, 2);
        expect(filtered.events.every((e) => e.refName == counterName), isTrue);
      });

      test('filter with null names returns original session', () {
        final recorder = store.startRecording(sessionId: 'filter-null');
        store.set(counter, 1);
        final session = recorder.stop();

        final result = session.filter(reactonNames: null);
        expect(identical(result, session), isTrue);
      });

      test('filter with empty names returns original session', () {
        final recorder = store.startRecording(sessionId: 'filter-empty');
        store.set(counter, 1);
        final session = recorder.stop();

        final result = session.filter(reactonNames: []);
        expect(identical(result, session), isTrue);
      });

      test('filter with unknown name returns empty events', () {
        final recorder = store.startRecording(sessionId: 'filter-unknown');
        store.set(counter, 1);
        final session = recorder.stop();

        final filtered = session.filter(reactonNames: ['nonexistent']);
        expect(filtered.events, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // RecordedSession properties
    // -----------------------------------------------------------------------

    group('RecordedSession properties', () {
      test('duration reflects endTime - startTime when available', () {
        final recorder = store.startRecording(sessionId: 'duration');
        store.set(counter, 1);
        final session = recorder.stop();

        expect(session.duration, greaterThanOrEqualTo(Duration.zero));
      });

      test('eventCount returns correct count', () {
        final recorder = store.startRecording(sessionId: 'count');
        store.set(counter, 1);
        store.set(counter, 2);
        final session = recorder.stop();

        expect(session.eventCount, 2);
      });

      test('reactonsChanged returns set of changed reacton names', () {
        final recorder = store.startRecording(sessionId: 'changed');
        store.set(counter, 1);
        store.set(label, 'x');
        final session = recorder.stop();

        expect(session.reactonsChanged, hasLength(2));
      });

      test('toString contains relevant info', () {
        final recorder = store.startRecording(sessionId: 'str-test');
        store.set(counter, 1);
        final session = recorder.stop();

        expect(session.toString(), contains('str-test'));
        expect(session.toString(), contains('1 events'));
      });

      test('duration returns zero for session with no events and no endTime', () {
        final session = RecordedSession(
          id: 'empty',
          startTime: DateTime.now(),
          events: [],
          initialSnapshot: {},
        );
        expect(session.duration, Duration.zero);
      });

      test('duration returns last event timestamp when no endTime', () {
        final session = RecordedSession(
          id: 'noend',
          startTime: DateTime.now(),
          events: [
            StateEvent(
              refId: 1,
              refName: 'test',
              oldValue: 0,
              newValue: 1,
              timestamp: const Duration(milliseconds: 500),
              wallClock: DateTime.now(),
            ),
          ],
          initialSnapshot: {},
        );
        expect(session.duration, const Duration(milliseconds: 500));
      });
    });

    // -----------------------------------------------------------------------
    // maxEvents circular buffer behavior
    // -----------------------------------------------------------------------

    group('maxEvents circular buffer', () {
      test('oldest events are discarded when maxEvents is reached', () {
        final recorder = store.startRecording(
          sessionId: 'circular',
          maxEvents: 3,
        );

        store.set(counter, 1);
        store.set(counter, 2);
        store.set(counter, 3);
        store.set(counter, 4);
        store.set(counter, 5);

        final session = recorder.stop();

        expect(session.events.length, 3);
        // The first two events (1, 2) should have been discarded.
        expect(session.events[0].newValue, 3);
        expect(session.events[1].newValue, 4);
        expect(session.events[2].newValue, 5);
      });

      test('maxEvents of 1 keeps only the latest event', () {
        final recorder = store.startRecording(
          sessionId: 'single',
          maxEvents: 1,
        );

        store.set(counter, 10);
        store.set(counter, 20);
        store.set(counter, 30);

        final session = recorder.stop();
        expect(session.events.length, 1);
        expect(session.events.first.newValue, 30);
      });

      test('no limit when maxEvents is null', () {
        final recorder = store.startRecording(sessionId: 'unlimited');

        // Start from 1 to avoid the equality-skip when counter is already 0.
        for (var i = 1; i <= 100; i++) {
          store.set(counter, i);
        }

        final session = recorder.stop();
        expect(session.events.length, 100);
      });
    });

    // -----------------------------------------------------------------------
    // Selective recording
    // -----------------------------------------------------------------------

    group('selective recording', () {
      test('records only specified reactons when reactonsToRecord is provided', () {
        final recorder = store.startRecording(
          sessionId: 'selective',
          reactonsToRecord: [counter],
        );

        store.set(counter, 1);
        store.set(label, 'changed'); // should not be recorded
        store.set(counter, 2);

        final session = recorder.stop();

        expect(session.events.length, 2);
        expect(session.events.every(
          (e) => e.refName.contains('counter'),
        ), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Store extension: isRecording, isReplaying
    // -----------------------------------------------------------------------

    group('store extension helpers', () {
      test('isRecording reflects active recording', () {
        expect(store.isRecording, isFalse);
        final recorder = store.startRecording();
        expect(store.isRecording, isTrue);
        recorder.stop();
        expect(store.isRecording, isFalse);
      });

      test('isReplaying reflects active replay', () {
        expect(store.isReplaying, isFalse);
      });
    });
  });

  // =========================================================================
  // StateEvent
  // =========================================================================

  group('StateEvent', () {
    test('toJson / fromJson round-trip', () {
      final event = StateEvent(
        refId: 1,
        refName: 'counter',
        oldValue: 0,
        newValue: 1,
        timestamp: const Duration(milliseconds: 1500),
        wallClock: DateTime.utc(2025, 6, 15, 12, 0, 0),
        metadata: {'action': 'increment'},
      );

      final json = event.toJson();
      final restored = StateEvent.fromJson(json);

      expect(restored.refId, 1);
      expect(restored.refName, 'counter');
      expect(restored.oldValue, 0);
      expect(restored.newValue, 1);
      expect(restored.timestamp, const Duration(milliseconds: 1500));
      expect(restored.wallClock, DateTime.utc(2025, 6, 15, 12, 0, 0));
      expect(restored.metadata!['action'], 'increment');
    });

    test('toJson omits metadata when null', () {
      final event = StateEvent(
        refId: 1,
        refName: 'test',
        oldValue: null,
        newValue: 'x',
        timestamp: Duration.zero,
        wallClock: DateTime.now(),
      );

      final json = event.toJson();
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson throws FormatException for missing fields', () {
      expect(
        () => StateEvent.fromJson({}),
        throwsA(isA<FormatException>()),
      );
    });

    test('toString includes useful info', () {
      final event = StateEvent(
        refId: 1,
        refName: 'counter',
        oldValue: 0,
        newValue: 1,
        timestamp: const Duration(milliseconds: 500),
        wallClock: DateTime.now(),
      );
      expect(event.toString(), contains('counter'));
      expect(event.toString(), contains('0'));
      expect(event.toString(), contains('1'));
    });
  });

  // =========================================================================
  // SessionMark
  // =========================================================================

  group('SessionMark', () {
    test('toJson / fromJson round-trip', () {
      final mark = SessionMark(
        label: 'checkpoint',
        timestamp: const Duration(milliseconds: 2000),
        metadata: {'screen': 'home'},
      );

      final json = mark.toJson();
      final restored = SessionMark.fromJson(json);

      expect(restored.label, 'checkpoint');
      expect(restored.timestamp, const Duration(milliseconds: 2000));
      expect(restored.metadata!['screen'], 'home');
    });

    test('toJson omits metadata when null', () {
      final mark = SessionMark(
        label: 'test',
        timestamp: Duration.zero,
      );
      final json = mark.toJson();
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toString contains label', () {
      final mark = SessionMark(
        label: 'myMark',
        timestamp: const Duration(seconds: 5),
      );
      expect(mark.toString(), contains('myMark'));
    });
  });

  // =========================================================================
  // SessionPlayer
  // =========================================================================

  group('SessionPlayer', () {
    late ReactonStore store;
    late WritableReacton<int> counter;

    setUp(() {
      store = ReactonStore();
      counter = reacton(0, name: 'counter');
      store.get(counter);
    });

    tearDown(() {
      store.dispose();
    });

    RecordedSession createTestSession() {
      final recorder = store.startRecording(sessionId: 'player-test');
      store.set(counter, 1);
      store.set(counter, 2);
      store.set(counter, 3);
      return recorder.stop();
    }

    // -----------------------------------------------------------------------
    // SessionPlayer: load restores initial snapshot
    // -----------------------------------------------------------------------

    group('load', () {
      test('restores the initial snapshot into the store', () {
        // Record with counter starting at 0.
        final session = createTestSession();

        // Change counter to something else.
        store.set(counter, 999);
        expect(store.get(counter), 999);

        // Load the session -- should restore counter to 0 (initial snapshot).
        final player = store.createPlayer();
        player.load(session);

        expect(store.get(counter), 0);
        player.dispose();
      });

      test('resets playback state on load', () {
        final session = createTestSession();
        final player = store.createPlayer();

        player.load(session);
        player.stepForward();
        expect(player.progress, greaterThan(0.0));

        // Re-load should reset.
        player.load(session);
        expect(player.progress, 0.0);

        player.dispose();
      });

      test('throws StateError when loading while playing', () async {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        final future = player.play(speed: 16.0);
        expect(
          () => player.load(session),
          throwsA(isA<StateError>()),
        );
        player.stop();
        await future;
        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: play replays events in order
    // -----------------------------------------------------------------------

    group('play', () {
      test('replays events in order', () async {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        final events = <StateEvent>[];
        player.onEvent.listen(events.add);

        await player.play(speed: 16.0);

        expect(events.length, 3);
        expect(events[0].newValue, 1);
        expect(events[1].newValue, 2);
        expect(events[2].newValue, 3);

        // Store should reflect the final state.
        expect(store.get(counter), 3);

        player.dispose();
      });

      test('throws StateError when no session loaded', () {
        final player = store.createPlayer();
        expect(() => player.play(), throwsA(isA<StateError>()));
        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: speed control
    // -----------------------------------------------------------------------

    group('speed control', () {
      test('speed property reflects the configured speed', () async {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        final future = player.play(speed: 4.0);
        expect(player.speed, 4.0);
        await future;

        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: pause / resume
    // -----------------------------------------------------------------------

    group('pause / resume', () {
      test('pause stops playback temporarily', () async {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        player.play(speed: 0.25); // slow speed to give us time
        await Future<void>.delayed(Duration.zero);

        player.pause();
        expect(player.isPaused, isTrue);
        expect(player.isPlaying, isTrue);

        player.resume();
        expect(player.isPaused, isFalse);

        player.stop();
        player.dispose();
      });

      test('pause when not playing throws StateError', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);
        expect(() => player.pause(), throwsA(isA<StateError>()));
        player.dispose();
      });

      test('resume when not paused throws StateError', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);
        expect(() => player.resume(), throwsA(isA<StateError>()));
        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: seekTo jumps to position
    // -----------------------------------------------------------------------

    group('seekTo', () {
      test('applies all events up to the given position', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        // Seek to end.
        player.seekTo(session.duration);
        expect(store.get(counter), 3);

        player.dispose();
      });

      test('seeking to zero restores initial snapshot', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        player.stepForward();
        player.stepForward();
        player.seekTo(Duration.zero);

        expect(store.get(counter), 0);

        player.dispose();
      });

      test('throws StateError when no session loaded', () {
        final player = store.createPlayer();
        expect(
          () => player.seekTo(Duration.zero),
          throwsA(isA<StateError>()),
        );
        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: stepForward / stepBackward
    // -----------------------------------------------------------------------

    group('stepForward / stepBackward', () {
      test('stepForward applies next event', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        expect(player.stepForward(), isTrue);
        expect(store.get(counter), 1);

        expect(player.stepForward(), isTrue);
        expect(store.get(counter), 2);

        expect(player.stepForward(), isTrue);
        expect(store.get(counter), 3);

        // No more events.
        expect(player.stepForward(), isFalse);

        player.dispose();
      });

      test('stepBackward reverses the last event', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        player.stepForward(); // counter = 1
        player.stepForward(); // counter = 2
        player.stepForward(); // counter = 3

        expect(player.stepBackward(), isTrue);
        expect(store.get(counter), 2);

        expect(player.stepBackward(), isTrue);
        expect(store.get(counter), 1);

        expect(player.stepBackward(), isTrue);
        expect(store.get(counter), 0);

        // At start.
        expect(player.stepBackward(), isFalse);

        player.dispose();
      });

      test('stepForward throws StateError with no session', () {
        final player = store.createPlayer();
        expect(() => player.stepForward(), throwsA(isA<StateError>()));
        player.dispose();
      });

      test('stepBackward throws StateError with no session', () {
        final player = store.createPlayer();
        expect(() => player.stepBackward(), throwsA(isA<StateError>()));
        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: progress and completion streams
    // -----------------------------------------------------------------------

    group('progress and completion', () {
      test('progress stream emits values from 0.0 to 1.0', () async {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        final progressValues = <double>[];
        player.onProgress.listen(progressValues.add);

        await player.play(speed: 16.0);

        expect(progressValues, isNotEmpty);
        expect(progressValues.last, closeTo(1.0, 0.01));

        player.dispose();
      });

      test('progress is 0 when no session loaded', () {
        final player = store.createPlayer();
        expect(player.progress, 0.0);
        player.dispose();
      });

      test('onComplete resolves when playback finishes', () async {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        player.play(speed: 16.0);
        await player.onComplete;

        expect(player.isPlaying, isFalse);

        player.dispose();
      });

      test('onComplete resolves immediately when no playback', () async {
        final player = store.createPlayer();
        // Should return a completed future.
        await player.onComplete;
        player.dispose();
      });

      test('position is Duration.zero at start', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);
        expect(player.position, Duration.zero);
        player.dispose();
      });

      test('position advances with stepForward', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        player.stepForward();
        expect(player.position, greaterThanOrEqualTo(Duration.zero));

        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: stop
    // -----------------------------------------------------------------------

    group('stop', () {
      test('stop completes the play future', () async {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);

        final future = player.play(speed: 0.25);
        player.stop();
        await future;

        expect(player.isPlaying, isFalse);

        player.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // SessionPlayer: dispose
    // -----------------------------------------------------------------------

    group('dispose', () {
      test('dispose cleans up resources', () {
        final session = createTestSession();
        final player = store.createPlayer();
        player.load(session);
        player.dispose();
        expect(player.isDisposed, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Store.replay convenience
    // -----------------------------------------------------------------------

    group('store.replay', () {
      test('replays a session to completion', () async {
        final session = createTestSession();

        // Reset counter.
        store.set(counter, 0);

        await store.replay(session, speed: 16.0);

        expect(store.get(counter), 3);
      });
    });

    // -----------------------------------------------------------------------
    // Store.createPlayer
    // -----------------------------------------------------------------------

    group('store.createPlayer', () {
      test('creates a player bound to the store', () {
        final player = store.createPlayer();
        expect(player, isNotNull);
        player.dispose();
      });
    });
  });
}
