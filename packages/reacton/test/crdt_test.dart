import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  // =========================================================================
  // VectorClock
  // =========================================================================

  group('VectorClock', () {
    group('increment', () {
      test('increments counter for a node from zero', () {
        final clock = VectorClock.zero().increment('a');
        expect(clock['a'], 1);
      });

      test('increments an existing counter', () {
        var clock = VectorClock.zero();
        clock = clock.increment('a');
        clock = clock.increment('a');
        clock = clock.increment('a');
        expect(clock['a'], 3);
      });

      test('independent nodes have independent counters', () {
        var clock = VectorClock.zero();
        clock = clock.increment('a');
        clock = clock.increment('b');
        clock = clock.increment('a');
        expect(clock['a'], 2);
        expect(clock['b'], 1);
      });

      test('returns a new immutable instance', () {
        final clock1 = VectorClock({'a': 1});
        final clock2 = clock1.increment('a');
        expect(clock1['a'], 1); // original unchanged
        expect(clock2['a'], 2);
      });
    });

    group('merge', () {
      test('pointwise maximum of two clocks', () {
        final a = VectorClock({'x': 2, 'y': 1});
        final b = VectorClock({'x': 1, 'y': 3});
        final merged = a.merge(b);
        expect(merged['x'], 2);
        expect(merged['y'], 3);
      });

      test('handles disjoint keys', () {
        final a = VectorClock({'x': 2});
        final b = VectorClock({'y': 3});
        final merged = a.merge(b);
        expect(merged['x'], 2);
        expect(merged['y'], 3);
      });

      test('merging with zero clock returns same values', () {
        final a = VectorClock({'x': 5, 'y': 3});
        final merged = a.merge(VectorClock.zero());
        expect(merged['x'], 5);
        expect(merged['y'], 3);
      });

      test('merge is commutative', () {
        final a = VectorClock({'x': 2, 'y': 1});
        final b = VectorClock({'x': 1, 'y': 3, 'z': 7});
        expect(a.merge(b), equals(b.merge(a)));
      });
    });

    group('happensBefore', () {
      test('returns true when strictly before', () {
        final a = VectorClock({'x': 1, 'y': 1});
        final b = VectorClock({'x': 2, 'y': 1});
        expect(a.happensBefore(b), isTrue);
      });

      test('returns true when all counters less or equal with at least one strictly less', () {
        final a = VectorClock({'x': 1, 'y': 2});
        final b = VectorClock({'x': 2, 'y': 3});
        expect(a.happensBefore(b), isTrue);
      });

      test('returns false for equal clocks', () {
        final a = VectorClock({'x': 1, 'y': 2});
        final b = VectorClock({'x': 1, 'y': 2});
        expect(a.happensBefore(b), isFalse);
      });

      test('returns false for concurrent clocks', () {
        final a = VectorClock({'x': 2, 'y': 1});
        final b = VectorClock({'x': 1, 'y': 2});
        expect(a.happensBefore(b), isFalse);
        expect(b.happensBefore(a), isFalse);
      });

      test('returns false when strictly after', () {
        final a = VectorClock({'x': 3, 'y': 2});
        final b = VectorClock({'x': 1, 'y': 1});
        expect(a.happensBefore(b), isFalse);
      });

      test('handles disjoint keys correctly', () {
        final a = VectorClock({'x': 1});
        final b = VectorClock({'x': 1, 'y': 1});
        // a has y=0, b has y=1 => a happens before b
        expect(a.happensBefore(b), isTrue);
      });
    });

    group('isConcurrent', () {
      test('returns true for concurrent clocks', () {
        final a = VectorClock({'x': 2, 'y': 1});
        final b = VectorClock({'x': 1, 'y': 2});
        expect(a.isConcurrent(b), isTrue);
      });

      test('returns false for equal clocks', () {
        final a = VectorClock({'x': 1, 'y': 2});
        final b = VectorClock({'x': 1, 'y': 2});
        expect(a.isConcurrent(b), isFalse);
      });

      test('returns false when one happens before the other', () {
        final a = VectorClock({'x': 1});
        final b = VectorClock({'x': 2});
        expect(a.isConcurrent(b), isFalse);
      });

      test('is symmetric', () {
        final a = VectorClock({'x': 2, 'y': 1});
        final b = VectorClock({'x': 1, 'y': 2});
        expect(a.isConcurrent(b), equals(b.isConcurrent(a)));
      });
    });

    group('JSON serialization round-trip', () {
      test('toJson produces correct map', () {
        final clock = VectorClock({'a': 3, 'b': 7});
        final json = clock.toJson();
        expect(json, {'a': 3, 'b': 7});
      });

      test('fromJson restores the clock', () {
        final original = VectorClock({'node1': 5, 'node2': 10});
        final restored = VectorClock.fromJson(original.toJson());
        expect(restored, equals(original));
      });

      test('round-trip through JSON encode/decode', () {
        final original = VectorClock({'x': 1, 'y': 2, 'z': 3});
        final jsonStr = jsonEncode(original.toJson());
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restored = VectorClock.fromJson(decoded);
        expect(restored, equals(original));
      });

      test('zero clock round-trip', () {
        final zero = VectorClock.zero();
        final restored = VectorClock.fromJson(zero.toJson());
        expect(restored, equals(zero));
      });
    });

    group('equality and hashCode', () {
      test('equal clocks are equal', () {
        final a = VectorClock({'x': 1, 'y': 2});
        final b = VectorClock({'x': 1, 'y': 2});
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different clocks are not equal', () {
        final a = VectorClock({'x': 1, 'y': 2});
        final b = VectorClock({'x': 1, 'y': 3});
        expect(a, isNot(equals(b)));
      });

      test('identity is equal', () {
        final a = VectorClock({'x': 1});
        expect(a, equals(a));
      });

      test('not equal to non-VectorClock', () {
        final a = VectorClock({'x': 1});
        // ignore: unrelated_type_equality_checks
        expect(a == 'not a clock', isFalse);
      });

      test('clocks with missing keys treated as zero', () {
        final a = VectorClock({'x': 1});
        final b = VectorClock({'x': 1, 'y': 0});
        // a['y'] is 0, b['y'] is 0 -> they should be equal.
        expect(a, equals(b));
      });
    });

    group('compareTo', () {
      test('returns negative when happens before', () {
        final a = VectorClock({'x': 1});
        final b = VectorClock({'x': 2});
        expect(a.compareTo(b), lessThan(0));
      });

      test('returns positive when happens after', () {
        final a = VectorClock({'x': 3});
        final b = VectorClock({'x': 1});
        expect(a.compareTo(b), greaterThan(0));
      });

      test('returns zero for equal or concurrent', () {
        final a = VectorClock({'x': 2, 'y': 1});
        final b = VectorClock({'x': 1, 'y': 2});
        expect(a.compareTo(b), equals(0));
      });
    });

    group('sum', () {
      test('returns sum of all counters', () {
        final clock = VectorClock({'a': 3, 'b': 7, 'c': 1});
        expect(clock.sum, 11);
      });

      test('zero clock has sum 0', () {
        expect(VectorClock.zero().sum, 0);
      });
    });

    group('operator []', () {
      test('returns 0 for unknown node', () {
        final clock = VectorClock({'a': 1});
        expect(clock['unknown'], 0);
      });
    });

    test('entries returns unmodifiable view', () {
      final clock = VectorClock({'a': 1});
      expect(clock.entries, isA<Map<String, int>>());
      expect(() => clock.entries['a'] = 99, throwsA(isA<UnsupportedError>()));
    });

    test('toString includes entries', () {
      final clock = VectorClock({'a': 1});
      expect(clock.toString(), contains('a'));
    });
  });

  // =========================================================================
  // CrdtValue
  // =========================================================================

  group('CrdtValue', () {
    test('creation with all fields', () {
      final clock = VectorClock({'a': 1});
      final val = CrdtValue<int>(
        value: 42,
        clock: clock,
        nodeId: 'node-a',
        timestamp: 1000,
      );
      expect(val.value, 42);
      expect(val.clock, equals(clock));
      expect(val.nodeId, 'node-a');
      expect(val.timestamp, 1000);
    });

    test('copyWith replaces specified fields', () {
      final original = CrdtValue<int>(
        value: 10,
        clock: VectorClock({'a': 1}),
        nodeId: 'a',
        timestamp: 100,
      );
      final updated = original.copyWith(value: 20, timestamp: 200);
      expect(updated.value, 20);
      expect(updated.clock, equals(original.clock));
      expect(updated.nodeId, 'a');
      expect(updated.timestamp, 200);
    });

    test('copyWith with no arguments returns equivalent copy', () {
      final original = CrdtValue<String>(
        value: 'hello',
        clock: VectorClock({'x': 5}),
        nodeId: 'n1',
        timestamp: 500,
      );
      final copy = original.copyWith();
      expect(copy.value, original.value);
      expect(copy.clock, original.clock);
      expect(copy.nodeId, original.nodeId);
      expect(copy.timestamp, original.timestamp);
    });

    test('JSON round-trip with serialize/deserialize', () {
      final original = CrdtValue<int>(
        value: 42,
        clock: VectorClock({'a': 3, 'b': 5}),
        nodeId: 'node-a',
        timestamp: 1234567890,
      );
      final json = original.toJson((v) => v);
      final restored = CrdtValue<int>.fromJson(json, (raw) => raw as int);
      expect(restored.value, 42);
      expect(restored.clock, equals(original.clock));
      expect(restored.nodeId, 'node-a');
      expect(restored.timestamp, 1234567890);
    });

    test('JSON round-trip through encode/decode', () {
      final original = CrdtValue<String>(
        value: 'test',
        clock: VectorClock({'x': 1}),
        nodeId: 'n',
        timestamp: 999,
      );
      final jsonStr = jsonEncode(original.toJson((v) => v));
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = CrdtValue<String>.fromJson(decoded, (raw) => raw as String);
      expect(restored.value, 'test');
      expect(restored.nodeId, 'n');
    });

    test('toString includes relevant info', () {
      final val = CrdtValue<int>(
        value: 7,
        clock: VectorClock.zero(),
        nodeId: 'n',
        timestamp: 0,
      );
      final str = val.toString();
      expect(str, contains('7'));
      expect(str, contains('n'));
    });
  });

  // =========================================================================
  // MergeStrategy
  // =========================================================================

  group('MergeStrategy', () {
    final localClock = VectorClock({'a': 2, 'b': 1});
    final remoteClock = VectorClock({'a': 1, 'b': 2});

    group('LastWriterWins', () {
      test('remote wins when remote timestamp is greater', () {
        final strategy = LastWriterWins<int>();
        final result = strategy.resolve(10, 20, localClock, remoteClock, 100, 200);
        expect(result, 20);
      });

      test('local wins when local timestamp is greater', () {
        final strategy = LastWriterWins<int>();
        final result = strategy.resolve(10, 20, localClock, remoteClock, 200, 100);
        expect(result, 10);
      });

      test('tiebreaks by nodeId when timestamps are equal', () {
        final strategyA = LastWriterWins<int>(localNodeId: 'a');
        // remoteClock has key 'b' which is > 'a', so remote wins
        final result = strategyA.resolve(10, 20, localClock, remoteClock, 100, 100);
        expect(result, 20);
      });

      test('local wins tiebreak when local nodeId is lexicographically greater', () {
        final strategyZ = LastWriterWins<int>(localNodeId: 'z');
        // remote key from remoteClock excluding 'z' -> 'a' or 'b'; both < 'z'
        final result = strategyZ.resolve(10, 20, localClock, remoteClock, 100, 100);
        expect(result, 10);
      });

      test('works with string values', () {
        final strategy = LastWriterWins<String>();
        final result = strategy.resolve('old', 'new', localClock, remoteClock, 100, 200);
        expect(result, 'new');
      });
    });

    group('MaxValue', () {
      test('picks the larger string value', () {
        final strategy = MaxValue<String>();
        expect(
          strategy.resolve('apple', 'banana', localClock, remoteClock, 0, 0),
          'banana',
        );
        expect(
          strategy.resolve('zebra', 'apple', localClock, remoteClock, 0, 0),
          'zebra',
        );
      });

      test('returns local when equal', () {
        final strategy = MaxValue<String>();
        expect(
          strategy.resolve('same', 'same', localClock, remoteClock, 0, 0),
          'same',
        );
      });

      test('works with DateTime (temporal ordering)', () {
        final strategy = MaxValue<DateTime>();
        final earlier = DateTime(2024, 1, 1);
        final later = DateTime(2025, 6, 15);
        expect(
          strategy.resolve(earlier, later, localClock, remoteClock, 0, 0),
          later,
        );
        expect(
          strategy.resolve(later, earlier, localClock, remoteClock, 0, 0),
          later,
        );
      });

      test('works with single-char strings to simulate numeric ordering', () {
        final strategy = MaxValue<String>();
        expect(
          strategy.resolve('1', '9', localClock, remoteClock, 0, 0),
          '9',
        );
      });
    });

    group('UnionMerge', () {
      test('merges two sets into their union', () {
        final strategy = UnionMerge<Set<String>>();
        final local = <String>{'a', 'b'};
        final remote = <String>{'b', 'c'};
        final result = strategy.resolve(
          local, remote, localClock, remoteClock, 0, 0,
        );
        expect(result, {'a', 'b', 'c'});
      });

      test('union with empty set returns the other', () {
        final strategy = UnionMerge<Set<int>>();
        final local = <int>{1, 2};
        final remote = <int>{};
        final result = strategy.resolve(
          local, remote, localClock, remoteClock, 0, 0,
        );
        expect(result, {1, 2});
      });

      test('union of identical sets returns same elements', () {
        final strategy = UnionMerge<Set<int>>();
        final set1 = <int>{1, 2, 3};
        final set2 = <int>{1, 2, 3};
        final result = strategy.resolve(
          set1, set2, localClock, remoteClock, 0, 0,
        );
        expect(result, {1, 2, 3});
      });
    });

    group('CustomMerge', () {
      test('invokes user-provided merge function', () {
        final strategy = CustomMerge<int>((local, remote, lc, rc) {
          return local + remote;
        });
        final result = strategy.resolve(10, 20, localClock, remoteClock, 0, 0);
        expect(result, 30);
      });

      test('receives correct clock parameters', () {
        VectorClock? receivedLocalClock;
        VectorClock? receivedRemoteClock;
        final strategy = CustomMerge<int>((local, remote, lc, rc) {
          receivedLocalClock = lc;
          receivedRemoteClock = rc;
          return local;
        });
        strategy.resolve(1, 2, localClock, remoteClock, 0, 0);
        expect(receivedLocalClock, equals(localClock));
        expect(receivedRemoteClock, equals(remoteClock));
      });
    });
  });

  // =========================================================================
  // SyncMessage
  // =========================================================================

  group('SyncMessage', () {
    Object? trivialDeserializer(String name, Object? raw) => raw;

    group('SyncFull', () {
      test('serialize and deserialize round-trip', () {
        final msg = SyncFull(
          reactonName: 'counter',
          crdtValue: CrdtValue<Object?>(
            value: 42,
            clock: VectorClock({'a': 3}),
            nodeId: 'node-a',
            timestamp: 1000,
          ),
          sourceNodeId: 'node-a',
        );

        expect(msg.type, 'sync_full');
        final json = msg.toJson();
        final restored = SyncMessage.fromJson(
          json,
          deserializeValue: trivialDeserializer,
        );
        expect(restored, isA<SyncFull>());
        final full = restored as SyncFull;
        expect(full.reactonName, 'counter');
        expect(full.crdtValue.value, 42);
        expect(full.sourceNodeId, 'node-a');
      });

      test('toJsonString and fromJsonString round-trip', () {
        final msg = SyncFull(
          reactonName: 'test',
          crdtValue: CrdtValue<Object?>(
            value: 'hello',
            clock: VectorClock({'x': 1}),
            nodeId: 'n',
            timestamp: 500,
          ),
          sourceNodeId: 'n',
        );
        final str = msg.toJsonString();
        final restored = SyncMessage.fromJsonString(
          str,
          deserializeValue: trivialDeserializer,
        );
        expect(restored, isA<SyncFull>());
      });
    });

    group('SyncDelta', () {
      test('serialize and deserialize round-trip', () {
        final msg = SyncDelta(
          reactonName: 'counter',
          crdtValue: CrdtValue<Object?>(
            value: 99,
            clock: VectorClock({'b': 5}),
            nodeId: 'node-b',
            timestamp: 2000,
          ),
          sourceNodeId: 'node-b',
        );

        expect(msg.type, 'sync_delta');
        final json = msg.toJson();
        final restored = SyncMessage.fromJson(
          json,
          deserializeValue: trivialDeserializer,
        );
        expect(restored, isA<SyncDelta>());
        final delta = restored as SyncDelta;
        expect(delta.reactonName, 'counter');
        expect(delta.crdtValue.value, 99);
      });
    });

    group('SyncAck', () {
      test('serialize and deserialize round-trip', () {
        final msg = SyncAck(
          reactonName: 'counter',
          ackedClock: VectorClock({'a': 3, 'b': 5}),
          sourceNodeId: 'node-a',
        );

        expect(msg.type, 'sync_ack');
        final json = msg.toJson();
        final restored = SyncMessage.fromJson(
          json,
          deserializeValue: trivialDeserializer,
        );
        expect(restored, isA<SyncAck>());
        final ack = restored as SyncAck;
        expect(ack.reactonName, 'counter');
        expect(ack.ackedClock, equals(VectorClock({'a': 3, 'b': 5})));
        expect(ack.sourceNodeId, 'node-a');
      });
    });

    group('SyncRequestFull', () {
      test('serialize and deserialize round-trip', () {
        final msg = SyncRequestFull(
          reactonNames: ['counter', 'tags'],
          sourceNodeId: 'node-c',
        );

        expect(msg.type, 'sync_request_full');
        final json = msg.toJson();
        final restored = SyncMessage.fromJson(
          json,
          deserializeValue: trivialDeserializer,
        );
        expect(restored, isA<SyncRequestFull>());
        final req = restored as SyncRequestFull;
        expect(req.reactonNames, ['counter', 'tags']);
        expect(req.sourceNodeId, 'node-c');
      });

      test('empty reactonNames round-trip', () {
        final msg = SyncRequestFull(
          reactonNames: [],
          sourceNodeId: 'node-d',
        );
        final restored = SyncMessage.fromJson(
          msg.toJson(),
          deserializeValue: trivialDeserializer,
        );
        final req = restored as SyncRequestFull;
        expect(req.reactonNames, isEmpty);
      });
    });

    test('unknown type throws FormatException', () {
      expect(
        () => SyncMessage.fromJson(
          {'type': 'unknown'},
          deserializeValue: trivialDeserializer,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // =========================================================================
  // InMemorySyncChannel
  // =========================================================================

  group('InMemorySyncChannel', () {
    test('pair creation returns two channels', () {
      final (a, b) = InMemorySyncChannel.pair('node-a', 'node-b');
      expect(a.localNodeId, 'node-a');
      expect(b.localNodeId, 'node-b');
    });

    test('bidirectional communication: A to B', () async {
      final (a, b) = InMemorySyncChannel.pair('a', 'b');
      final received = <String>[];
      b.incoming.listen((msg) => received.add(msg));

      a.send('hello');
      a.send('world');

      expect(received, ['hello', 'world']);

      await a.close();
    });

    test('bidirectional communication: B to A', () async {
      final (a, b) = InMemorySyncChannel.pair('a', 'b');
      final received = <String>[];
      a.incoming.listen((msg) => received.add(msg));

      b.send('ping');
      b.send('pong');

      expect(received, ['ping', 'pong']);

      await b.close();
    });

    test('send on closed channel throws StateError', () async {
      final (a, _) = InMemorySyncChannel.pair('a', 'b');
      await a.close();

      expect(() => a.send('late'), throwsA(isA<StateError>()));
    });

    test('close is idempotent', () async {
      final (a, _) = InMemorySyncChannel.pair('a', 'b');
      await a.close();
      // Should not throw.
      await a.close();
    });
  });

  // =========================================================================
  // CollaborativeReacton
  // =========================================================================

  group('CollaborativeReacton', () {
    test('creation with default strategy', () {
      final cr = collaborativeReacton<int>(0, name: 'counter');
      expect(cr.collaborativeName, 'counter');
      expect(cr.strategy, isA<LastWriterWins<int>>());
    });

    test('creation with custom strategy', () {
      final cr = collaborativeReacton<String>(
        '',
        name: 'maxStr',
        strategy: MaxValue<String>(),
      );
      expect(cr.strategy, isA<MaxValue<String>>());
    });

    test('auto-generated name when none provided', () {
      final cr = collaborativeReacton<int>(0);
      expect(cr.collaborativeName, isNotEmpty);
    });
  });

  // =========================================================================
  // CollaborativeSession
  // =========================================================================

  group('CollaborativeSession', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    tearDown(() {
      store.dispose();
    });

    group('connect and initial sync', () {
      test('session starts in connected state after collaborate()', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, _) = InMemorySyncChannel.pair('a', 'b');

        final session = store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        expect(session.isConnected, isTrue);
        expect(session.currentStatus, SyncStatus.connected);
        expect(session.localNodeId, 'a');

        await session.disconnect();
      });

      test('sends SyncRequestFull on connect', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, channelB) = InMemorySyncChannel.pair('a', 'b');

        final received = <String>[];
        channelB.incoming.listen((msg) => received.add(msg));

        store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        // The first message should be a SyncRequestFull.
        expect(received.length, greaterThanOrEqualTo(1));
        final firstMsg = jsonDecode(received.first) as Map<String, dynamic>;
        expect(firstMsg['type'], 'sync_request_full');

        await channelA.close();
      });
    });

    group('local change propagates to remote', () {
      test('setting a value sends a SyncDelta', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, channelB) = InMemorySyncChannel.pair('a', 'b');

        final received = <Map<String, dynamic>>[];
        channelB.incoming.listen((msg) {
          received.add(jsonDecode(msg) as Map<String, dynamic>);
        });

        final session = store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        // Clear the initial sync request.
        received.clear();

        store.set(counter, 42);

        // A SyncDelta should have been sent.
        final deltas = received.where((m) => m['type'] == 'sync_delta').toList();
        expect(deltas, isNotEmpty);
        expect(deltas.first['reactonName'], 'counter');

        await session.disconnect();
      });
    });

    group('remote change applies locally', () {
      test('incoming SyncDelta with newer clock updates local store', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, channelB) = InMemorySyncChannel.pair('a', 'b');

        final session = store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        // Simulate a remote delta that is causally newer.
        final remoteClock = VectorClock({'b': 10}); // clearly newer than local
        final delta = SyncDelta(
          reactonName: 'counter',
          crdtValue: CrdtValue<Object?>(
            value: 99,
            clock: remoteClock,
            nodeId: 'b',
            timestamp: DateTime.now().millisecondsSinceEpoch + 1000,
          ),
          sourceNodeId: 'b',
        );
        channelB.send(delta.toJsonString());

        // Allow the message to be processed.
        await Future<void>.delayed(Duration.zero);

        expect(store.get(counter), 99);

        await session.disconnect();
      });
    });

    group('conflict detection and resolution', () {
      test('concurrent updates trigger conflict and resolve via strategy', () async {
        final counter = collaborativeReacton<int>(
          0,
          name: 'counter',
          strategy: CustomMerge<int>((local, remote, lc, rc) {
            // Pick the larger value (same as MaxValue but works with int).
            return local > remote ? local : remote;
          }),
        );
        final (channelA, channelB) = InMemorySyncChannel.pair('a', 'b');

        final session = store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        final conflicts = <ConflictEvent<Object?>>[];
        session.onConflict.listen(conflicts.add);

        // Set a local value first.
        store.set(counter, 50);

        // Now send a concurrent remote value (concurrent clock).
        // Local clock is roughly {'a': 2}, remote is {'b': 1} -> concurrent.
        final remoteClock = VectorClock({'b': 1});
        final delta = SyncDelta(
          reactonName: 'counter',
          crdtValue: CrdtValue<Object?>(
            value: 100,
            clock: remoteClock,
            nodeId: 'b',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
          sourceNodeId: 'b',
        );
        channelB.send(delta.toJsonString());
        await Future<void>.delayed(Duration.zero);

        // MaxValue strategy should pick the larger value.
        expect(store.get(counter), 100);
        expect(conflicts, isNotEmpty);
        expect(conflicts.first.resolvedValue, 100);

        await session.disconnect();
      });
    });

    group('disconnect cleanup', () {
      test('disconnect sets status to disconnected and cleans up', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, _) = InMemorySyncChannel.pair('a', 'b');

        final session = store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        final statuses = <SyncStatus>[];
        session.syncStatus.listen(statuses.add);

        await session.disconnect();

        expect(session.currentStatus, SyncStatus.disconnected);
        expect(session.isDisposed, isTrue);
      });

      test('disconnect is idempotent', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, _) = InMemorySyncChannel.pair('a', 'b');

        final session = store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        await session.disconnect();
        // Should not throw.
        await session.disconnect();
      });
    });

    group('peer tracking', () {
      test('peers set populated after receiving remote messages', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, channelB) = InMemorySyncChannel.pair('a', 'b');

        final session = store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        // Send an ack from the "remote" side.
        final ack = SyncAck(
          reactonName: 'counter',
          ackedClock: VectorClock({'b': 1}),
          sourceNodeId: 'b',
        );
        channelB.send(ack.toJsonString());
        await Future<void>.delayed(Duration.zero);

        expect(session.peers, contains('b'));

        await session.disconnect();
      });
    });

    group('store extension helpers', () {
      test('isSynced returns true for tracked reacton in connected session', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, _) = InMemorySyncChannel.pair('a', 'b');

        store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        expect(store.isSynced(counter), isTrue);

        await channelA.close();
      });

      test('isSynced returns false when no session', () {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        expect(store.isSynced(counter), isFalse);
      });

      test('clockOf returns the tracked clock', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, _) = InMemorySyncChannel.pair('a', 'b');

        store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        final clock = store.clockOf(counter);
        expect(clock['a'], greaterThan(0));

        await channelA.close();
      });

      test('clockOf returns zero clock when not tracked', () {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        expect(store.clockOf(counter), equals(VectorClock.zero()));
      });

      test('collaborativeSessions lists active sessions', () async {
        final counter = collaborativeReacton<int>(0, name: 'counter');
        final (channelA, _) = InMemorySyncChannel.pair('a', 'b');

        store.collaborate(
          channel: channelA,
          reactons: [counter],
        );

        expect(store.collaborativeSessions, hasLength(1));

        await channelA.close();
      });
    });

    group('two stores syncing through in-memory channels', () {
      test('bidirectional sync between two stores', () async {
        final storeA = ReactonStore();
        final storeB = ReactonStore();
        final (channelA, channelB) = InMemorySyncChannel.pair('a', 'b');

        // Both stores need their own instance of the reacton definition
        // but with the same collaborative name for sync to work.
        final counterA = collaborativeReacton<int>(0, name: 'shared');
        final counterB = collaborativeReacton<int>(0, name: 'shared');

        final sessionA = storeA.collaborate(
          channel: channelA,
          reactons: [counterA],
        );
        final sessionB = storeB.collaborate(
          channel: channelB,
          reactons: [counterB],
        );

        // Store A sets a value.
        storeA.set(counterA, 42);
        await Future<void>.delayed(Duration.zero);

        // Store B should have received the update.
        expect(storeB.get(counterB), 42);

        // Store B sets a different value.
        storeB.set(counterB, 100);
        await Future<void>.delayed(Duration.zero);

        // Store A should have received the update.
        expect(storeA.get(counterA), 100);

        await sessionA.disconnect();
        await sessionB.disconnect();
        storeA.dispose();
        storeB.dispose();
      });
    });
  });

  // =========================================================================
  // ConflictEvent
  // =========================================================================

  group('ConflictEvent', () {
    test('toString includes relevant info', () {
      final event = ConflictEvent<int>(
        reactonName: 'counter',
        localValue: 10,
        remoteValue: 20,
        resolvedValue: 20,
        strategy: LastWriterWins<int>(),
        localClock: VectorClock({'a': 1}),
        remoteClock: VectorClock({'b': 1}),
      );
      final str = event.toString();
      expect(str, contains('counter'));
      expect(str, contains('10'));
      expect(str, contains('20'));
    });
  });

  // =========================================================================
  // SyncStatus
  // =========================================================================

  group('SyncStatus', () {
    test('has all expected values', () {
      expect(SyncStatus.values, containsAll([
        SyncStatus.disconnected,
        SyncStatus.connecting,
        SyncStatus.connected,
        SyncStatus.reconnecting,
      ]));
    });
  });
}
