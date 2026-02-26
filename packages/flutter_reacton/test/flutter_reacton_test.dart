import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// ---------------------------------------------------------------------------
// Top-level reacton declarations (each reacton has a unique ReactonRef identity)
// ---------------------------------------------------------------------------

// Group 1: ReactonScope
final _scopeCounterReacton = reacton(0, name: 'scope_counter');
final _scopeOverrideReacton = reacton(10, name: 'scope_override');
final _scopeOverrideReacton2 = reacton('hello', name: 'scope_override2');

// Group 2: context.watch()
final _watchCounterReacton = reacton(0, name: 'watch_counter');
final _watchNameReacton = reacton('Alice', name: 'watch_name');
final _watchBaseReacton = reacton(3, name: 'watch_base');
final _watchComputedReacton = computed<int>(
  (read) => read(_watchBaseReacton) * 2,
  name: 'watch_computed',
);
final _watchDisposalReacton = reacton(0, name: 'watch_disposal');

// Group 3: context.read()
final _readCounterReacton = reacton(0, name: 'read_counter');
final _readNoRebuildReacton = reacton(0, name: 'read_no_rebuild');
final _readCallbackReacton = reacton(100, name: 'read_callback');

// Group 4: context.set() / context.update()
final _setReacton = reacton(0, name: 'set_reacton');
final _updateReacton = reacton(0, name: 'update_reacton');
final _setRebuildReacton = reacton(0, name: 'set_rebuild');
final _e2eCounterReacton = reacton(0, name: 'e2e_counter');

// Group 5: ReactonBuilder
final _builderReacton = reacton(0, name: 'builder_reacton');
final _builderChangeReacton = reacton(0, name: 'builder_change');
final _builderParentReacton = reacton(0, name: 'builder_parent');
final _builderSwapReactonA = reacton('A', name: 'builder_swap_a');
final _builderSwapReactonB = reacton('B', name: 'builder_swap_b');

// Group 6: ReactonConsumer
final _consumerWatchReacton = reacton(0, name: 'consumer_watch');
final _consumerReadReacton = reacton(42, name: 'consumer_read');
final _consumerMultiReacton1 = reacton(1, name: 'consumer_multi1');
final _consumerMultiReacton2 = reacton(2, name: 'consumer_multi2');
final _consumerSetReacton = reacton(0, name: 'consumer_set');

// Group 7: ReactonListener
final _listenerReacton = reacton(0, name: 'listener_reacton');
final _listenerChildReacton = reacton(0, name: 'listener_child');
final _listenerWhenReacton = reacton(0, name: 'listener_when');
final _listenerValueReacton = reacton('', name: 'listener_value');

// Group 8: ReactonSelector
final _selectorReacton = reacton(const _UserData('Alice', 25), name: 'selector_reacton');
final _selectorNoRebuildReacton =
    reacton(const _UserData('Bob', 30), name: 'selector_no_rebuild');
final _selectorComplexReacton =
    reacton(const _Pair(1, 'one'), name: 'selector_complex');

// Group 9: Integration
final _intCounterReacton = reacton(0, name: 'int_counter');
final _intDoubleReacton = computed<int>(
  (read) => read(_intCounterReacton) * 2,
  name: 'int_double',
);
final _intLabelReacton = computed<String>(
  (read) => 'Count: ${read(_intCounterReacton)}',
  name: 'int_label',
);
final _intSharedReacton = reacton(0, name: 'int_shared');
final _intBatchReacton1 = reacton(0, name: 'int_batch1');
final _intBatchReacton2 = reacton(0, name: 'int_batch2');
final _intBatchComputed = computed<int>(
  (read) => read(_intBatchReacton1) + read(_intBatchReacton2),
  name: 'int_batch_sum',
);

// ---------------------------------------------------------------------------
// Helper types
// ---------------------------------------------------------------------------

class _UserData {
  final String name;
  final int age;
  const _UserData(this.name, this.age);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UserData && name == other.name && age == other.age;

  @override
  int get hashCode => Object.hash(name, age);
}

class _Pair<A, B> {
  final A first;
  final B second;
  const _Pair(this.first, this.second);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Pair && first == other.first && second == other.second;

  @override
  int get hashCode => Object.hash(first, second);
}

// ---------------------------------------------------------------------------
// Helper: wraps a widget in MaterialApp + ReactonScope
// ---------------------------------------------------------------------------

Widget _wrapWithScope(Widget child, {ReactonStore? store}) {
  return MaterialApp(
    home: ReactonScope(
      store: store ?? ReactonStore(),
      child: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Reusable build-counter widget that exposes its build count
// ---------------------------------------------------------------------------

class _BuildCounter extends StatefulWidget {
  final Widget Function(BuildContext context, int buildCount) builder;
  const _BuildCounter({required this.builder});

  @override
  State<_BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<_BuildCounter> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    return widget.builder(context, _buildCount);
  }
}

// ==========================================================================
// TESTS
// ==========================================================================

void main() {
  // ========================================================================
  // Group 1: ReactonScope
  // ========================================================================
  group('ReactonScope', () {
    testWidgets('provides a given store to the widget tree',
        (WidgetTester tester) async {
      final store = ReactonStore();
      store.set(_scopeCounterReacton, 42);

      late ReactonStore capturedStore;
      await tester.pumpWidget(
        MaterialApp(
          home: ReactonScope(
            store: store,
            child: Builder(
              builder: (context) {
                capturedStore = ReactonScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedStore, same(store));
      expect(capturedStore.get(_scopeCounterReacton), equals(42));
    });

    testWidgets('auto-creates a store when none is provided',
        (WidgetTester tester) async {
      late ReactonStore capturedStore;
      await tester.pumpWidget(
        MaterialApp(
          home: ReactonScope(
            child: Builder(
              builder: (context) {
                capturedStore = ReactonScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedStore, isNotNull);
      expect(capturedStore, isA<ReactonStore>());
    });

    testWidgets('ReactonScope.of() returns the store with dependency',
        (WidgetTester tester) async {
      final store = ReactonStore();

      late ReactonStore result;
      await tester.pumpWidget(
        MaterialApp(
          home: ReactonScope(
            store: store,
            child: Builder(
              builder: (context) {
                result = ReactonScope.of(context);
                return Text('value: ${result.get(_scopeCounterReacton)}',
                    textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(result, same(store));
    });

    testWidgets('ReactonScope.read() returns the store without dependency',
        (WidgetTester tester) async {
      final store = ReactonStore();

      late ReactonStore result;
      await tester.pumpWidget(
        MaterialApp(
          home: ReactonScope(
            store: store,
            child: Builder(
              builder: (context) {
                result = ReactonScope.read(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, same(store));
    });

    testWidgets('ReactonScope.maybeOf() returns null when no scope exists',
        (WidgetTester tester) async {
      ReactonStore? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ReactonScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isNull);
    });

    testWidgets('ReactonScope.maybeOf() returns the store when scope exists',
        (WidgetTester tester) async {
      final store = ReactonStore();
      ReactonStore? result;

      await tester.pumpWidget(
        MaterialApp(
          home: ReactonScope(
            store: store,
            child: Builder(
              builder: (context) {
                result = ReactonScope.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, same(store));
    });

    testWidgets('ReactonOverride overrides reacton values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReactonScope(
            overrides: [
              ReactonOverride(_scopeOverrideReacton, 999),
              ReactonOverride(_scopeOverrideReacton2, 'overridden'),
            ],
            child: Builder(
              builder: (context) {
                final intVal = context.read(_scopeOverrideReacton);
                final strVal = context.read(_scopeOverrideReacton2);
                return Text('$intVal $strVal',
                    textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('999 overridden'), findsOneWidget);
    });
  });

  // ========================================================================
  // Group 2: context.watch()
  // ========================================================================
  group('context.watch()', () {
    testWidgets('returns the current reacton value',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final value = context.watch(_watchCounterReacton);
              return Text('$value', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds widget when reacton value changes',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final value = context.watch(_watchCounterReacton);
              return Text('count:$value', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(find.text('count:0'), findsOneWidget);

      store.set(_watchCounterReacton, 5);
      await tester.pump();

      expect(find.text('count:5'), findsOneWidget);

      store.set(_watchCounterReacton, 10);
      await tester.pump();

      expect(find.text('count:10'), findsOneWidget);
    });

    testWidgets('multiple watches in the same build work correctly',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final count = context.watch(_watchCounterReacton);
              final name = context.watch(_watchNameReacton);
              return Text('$name:$count', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(find.text('Alice:0'), findsOneWidget);

      store.set(_watchCounterReacton, 7);
      await tester.pump();

      expect(find.text('Alice:7'), findsOneWidget);

      store.set(_watchNameReacton, 'Bob');
      await tester.pump();

      expect(find.text('Bob:7'), findsOneWidget);
    });

    testWidgets('computed reacton watch works and reacts to dependencies',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final doubled = context.watch(_watchComputedReacton);
              return Text('doubled:$doubled', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      // Initial: _watchBaseReacton = 3, computed = 3 * 2 = 6
      expect(find.text('doubled:6'), findsOneWidget);

      store.set(_watchBaseReacton, 10);
      await tester.pump();

      expect(find.text('doubled:20'), findsOneWidget);
    });

    testWidgets('ReactonBuilder stops rebuilding after disposal',
        (WidgetTester tester) async {
      // ReactonBuilder explicitly unsubscribes in its dispose method,
      // so updates after removal should not trigger rebuilds.
      final store = ReactonStore();
      int buildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonBuilder<int>(
            reacton: _watchDisposalReacton,
            builder: (context, value) {
              buildCount++;
              return Text('val:$value', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      final initialBuildCount = buildCount;

      // Verify it reacts
      store.set(_watchDisposalReacton, 1);
      await tester.pump();
      expect(buildCount, greaterThan(initialBuildCount));

      final countAfterUpdate = buildCount;

      // Remove the ReactonBuilder from the tree
      await tester.pumpWidget(
        _wrapWithScope(const SizedBox(), store: store),
      );

      // Further changes should not increase buildCount
      store.set(_watchDisposalReacton, 2);
      await tester.pump();
      store.set(_watchDisposalReacton, 3);
      await tester.pump();

      expect(buildCount, equals(countAfterUpdate));
    });
  });

  // ========================================================================
  // Group 3: context.read()
  // ========================================================================
  group('context.read()', () {
    testWidgets('returns the current reacton value',
        (WidgetTester tester) async {
      final store = ReactonStore();
      store.set(_readCounterReacton, 55);

      late int capturedValue;
      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              capturedValue = context.read(_readCounterReacton);
              return Text('$capturedValue', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(capturedValue, equals(55));
      expect(find.text('55'), findsOneWidget);
    });

    testWidgets('does NOT rebuild when the reacton value changes',
        (WidgetTester tester) async {
      final store = ReactonStore();
      int buildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              buildCount++;
              final value = context.read(_readNoRebuildReacton);
              return Text('read:$value', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(buildCount, equals(1));
      expect(find.text('read:0'), findsOneWidget);

      // Change the reacton value
      store.set(_readNoRebuildReacton, 100);
      await tester.pump();

      // Build count should not increase since read() doesn't subscribe
      expect(buildCount, equals(1));
    });

    testWidgets('works correctly in callbacks and event handlers',
        (WidgetTester tester) async {
      final store = ReactonStore();
      store.set(_readCallbackReacton, 100);

      late int tappedValue;
      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  tappedValue = context.read(_readCallbackReacton);
                },
                child: const Text('Tap'),
              );
            },
          ),
          store: store,
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tappedValue, equals(100));

      // Change value and tap again
      store.set(_readCallbackReacton, 200);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tappedValue, equals(200));
    });
  });

  // ========================================================================
  // Group 4: context.set() and context.update()
  // ========================================================================
  group('context.set() and context.update()', () {
    testWidgets('set() changes the reacton value',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final value = context.watch(_setReacton);
              return Column(
                children: [
                  Text('val:$value', textDirection: TextDirection.ltr),
                  ElevatedButton(
                    onPressed: () => context.set(_setReacton, 42),
                    child: const Text('Set'),
                  ),
                ],
              );
            },
          ),
          store: store,
        ),
      );

      expect(find.text('val:0'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('val:42'), findsOneWidget);
      expect(store.get(_setReacton), equals(42));
    });

    testWidgets('update() applies a function to the current value',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final value = context.watch(_updateReacton);
              return Column(
                children: [
                  Text('val:$value', textDirection: TextDirection.ltr),
                  ElevatedButton(
                    onPressed: () =>
                        context.update(_updateReacton, (v) => v + 10),
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          ),
          store: store,
        ),
      );

      expect(find.text('val:0'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('val:10'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('val:20'), findsOneWidget);
    });

    testWidgets('set triggers rebuild on watching widgets',
        (WidgetTester tester) async {
      final store = ReactonStore();
      int buildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              buildCount++;
              final value = context.watch(_setRebuildReacton);
              return Column(
                children: [
                  Text('val:$value', textDirection: TextDirection.ltr),
                  ElevatedButton(
                    onPressed: () => context.set(_setRebuildReacton, value + 1),
                    child: const Text('Inc'),
                  ),
                ],
              );
            },
          ),
          store: store,
        ),
      );

      expect(buildCount, equals(1));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buildCount, equals(2));
      expect(find.text('val:1'), findsOneWidget);
    });

    testWidgets('increment counter end-to-end',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final count = context.watch(_e2eCounterReacton);
              return Column(
                children: [
                  Text('$count', textDirection: TextDirection.ltr),
                  ElevatedButton(
                    key: const Key('inc'),
                    onPressed: () =>
                        context.update(_e2eCounterReacton, (c) => c + 1),
                    child: const Text('+'),
                  ),
                  ElevatedButton(
                    key: const Key('dec'),
                    onPressed: () =>
                        context.update(_e2eCounterReacton, (c) => c - 1),
                    child: const Text('-'),
                  ),
                ],
              );
            },
          ),
          store: store,
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Increment 3 times
      await tester.tap(find.byKey(const Key('inc')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('inc')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('inc')));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);

      // Decrement once
      await tester.tap(find.byKey(const Key('dec')));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });
  });

  // ========================================================================
  // Group 5: ReactonBuilder
  // ========================================================================
  group('ReactonBuilder', () {
    testWidgets('renders the initial reacton value',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonBuilder<int>(
            reacton: _builderReacton,
            builder: (context, value) =>
                Text('builder:$value', textDirection: TextDirection.ltr),
          ),
          store: store,
        ),
      );

      expect(find.text('builder:0'), findsOneWidget);
    });

    testWidgets('rebuilds when the reacton changes',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonBuilder<int>(
            reacton: _builderChangeReacton,
            builder: (context, value) =>
                Text('val:$value', textDirection: TextDirection.ltr),
          ),
          store: store,
        ),
      );

      expect(find.text('val:0'), findsOneWidget);

      store.set(_builderChangeReacton, 7);
      await tester.pump();

      expect(find.text('val:7'), findsOneWidget);

      store.set(_builderChangeReacton, 99);
      await tester.pump();

      expect(find.text('val:99'), findsOneWidget);
    });

    testWidgets('does not rebuild the parent widget',
        (WidgetTester tester) async {
      final store = ReactonStore();
      int parentBuildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          _BuildCounter(
            builder: (context, buildCount) {
              parentBuildCount = buildCount;
              return ReactonBuilder<int>(
                reacton: _builderParentReacton,
                builder: (context, value) =>
                    Text('inner:$value', textDirection: TextDirection.ltr),
              );
            },
          ),
          store: store,
        ),
      );

      expect(parentBuildCount, equals(1));

      store.set(_builderParentReacton, 1);
      await tester.pump();

      // Parent should NOT have rebuilt
      expect(parentBuildCount, equals(1));
      expect(find.text('inner:1'), findsOneWidget);

      store.set(_builderParentReacton, 2);
      await tester.pump();

      expect(parentBuildCount, equals(1));
      expect(find.text('inner:2'), findsOneWidget);
    });

    testWidgets('handles switching to a different reacton',
        (WidgetTester tester) async {
      final store = ReactonStore();
      store.set(_builderSwapReactonA, 'ValueA');
      store.set(_builderSwapReactonB, 'ValueB');

      bool useReactonA = true;

      await tester.pumpWidget(
        _wrapWithScope(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ReactonBuilder<String>(
                    reacton: useReactonA ? _builderSwapReactonA : _builderSwapReactonB,
                    builder: (context, value) =>
                        Text('reacton:$value', textDirection: TextDirection.ltr),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => useReactonA = !useReactonA),
                    child: const Text('Swap'),
                  ),
                ],
              );
            },
          ),
          store: store,
        ),
      );

      expect(find.text('reacton:ValueA'), findsOneWidget);

      // Swap to reacton B
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('reacton:ValueB'), findsOneWidget);

      // Now update reacton B; it should reflect
      store.set(_builderSwapReactonB, 'NewB');
      await tester.pump();

      expect(find.text('reacton:NewB'), findsOneWidget);
    });
  });

  // ========================================================================
  // Group 6: ReactonConsumer
  // ========================================================================
  group('ReactonConsumer', () {
    testWidgets('ref.watch() subscribes to reactons and rebuilds on change',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonConsumer(
            builder: (context, ref) {
              final value = ref.watch(_consumerWatchReacton);
              return Text('consumer:$value',
                  textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(find.text('consumer:0'), findsOneWidget);

      store.set(_consumerWatchReacton, 77);
      await tester.pump();

      expect(find.text('consumer:77'), findsOneWidget);
    });

    testWidgets('ref.read() reads without subscription',
        (WidgetTester tester) async {
      final store = ReactonStore();
      store.set(_consumerReadReacton, 42);
      int buildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonConsumer(
            builder: (context, ref) {
              buildCount++;
              final value = ref.read(_consumerReadReacton);
              return Text('read:$value', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(find.text('read:42'), findsOneWidget);
      final initialBuildCount = buildCount;

      // Changing the read-only reacton should NOT trigger rebuild
      store.set(_consumerReadReacton, 999);
      await tester.pump();

      // Build count should stay the same since only read() was used
      expect(buildCount, equals(initialBuildCount));
    });

    testWidgets('multiple reactons can be watched simultaneously',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonConsumer(
            builder: (context, ref) {
              final v1 = ref.watch(_consumerMultiReacton1);
              final v2 = ref.watch(_consumerMultiReacton2);
              return Text('$v1+$v2=${v1 + v2}',
                  textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(find.text('1+2=3'), findsOneWidget);

      store.set(_consumerMultiReacton1, 10);
      await tester.pump();

      expect(find.text('10+2=12'), findsOneWidget);

      store.set(_consumerMultiReacton2, 20);
      await tester.pump();

      expect(find.text('10+20=30'), findsOneWidget);
    });

    testWidgets('ref.set() and ref.update() work correctly',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonConsumer(
            builder: (context, ref) {
              final value = ref.watch(_consumerSetReacton);
              return Column(
                children: [
                  Text('val:$value', textDirection: TextDirection.ltr),
                  ElevatedButton(
                    key: const Key('set'),
                    onPressed: () => ref.set(_consumerSetReacton, 50),
                    child: const Text('Set'),
                  ),
                  ElevatedButton(
                    key: const Key('update'),
                    onPressed: () =>
                        ref.update(_consumerSetReacton, (v) => v + 5),
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          ),
          store: store,
        ),
      );

      expect(find.text('val:0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('set')));
      await tester.pump();
      expect(find.text('val:50'), findsOneWidget);

      await tester.tap(find.byKey(const Key('update')));
      await tester.pump();
      expect(find.text('val:55'), findsOneWidget);
    });
  });

  // ========================================================================
  // Group 7: ReactonListener
  // ========================================================================
  group('ReactonListener', () {
    testWidgets('calls listener when reacton changes',
        (WidgetTester tester) async {
      final store = ReactonStore();
      final listenerValues = <int>[];

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonListener<int>(
            reacton: _listenerReacton,
            listener: (context, value) {
              listenerValues.add(value);
            },
            child: const Text('static', textDirection: TextDirection.ltr),
          ),
          store: store,
        ),
      );

      expect(listenerValues, isEmpty);

      store.set(_listenerReacton, 1);
      await tester.pump();

      expect(listenerValues, equals([1]));

      store.set(_listenerReacton, 2);
      await tester.pump();

      expect(listenerValues, equals([1, 2]));

      store.set(_listenerReacton, 3);
      await tester.pump();

      expect(listenerValues, equals([1, 2, 3]));
    });

    testWidgets('does NOT rebuild the child widget',
        (WidgetTester tester) async {
      final store = ReactonStore();
      int childBuildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonListener<int>(
            reacton: _listenerChildReacton,
            listener: (context, value) {
              // Side effect only
            },
            child: _BuildCounter(
              builder: (context, buildCount) {
                childBuildCount = buildCount;
                return const Text('child', textDirection: TextDirection.ltr);
              },
            ),
          ),
          store: store,
        ),
      );

      expect(childBuildCount, equals(1));

      store.set(_listenerChildReacton, 10);
      await tester.pump();

      // Child should NOT have rebuilt
      expect(childBuildCount, equals(1));

      store.set(_listenerChildReacton, 20);
      await tester.pump();

      expect(childBuildCount, equals(1));
    });

    testWidgets('listenWhen guards listener calls',
        (WidgetTester tester) async {
      final store = ReactonStore();
      final listenerValues = <int>[];

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonListener<int>(
            reacton: _listenerWhenReacton,
            listenWhen: (prev, curr) => curr.isEven,
            listener: (context, value) {
              listenerValues.add(value);
            },
            child: const Text('guarded', textDirection: TextDirection.ltr),
          ),
          store: store,
        ),
      );

      // Set to odd -> should NOT call listener
      store.set(_listenerWhenReacton, 1);
      await tester.pump();
      expect(listenerValues, isEmpty);

      // Set to even -> should call listener
      store.set(_listenerWhenReacton, 2);
      await tester.pump();
      expect(listenerValues, equals([2]));

      // Set to odd -> should NOT call listener
      store.set(_listenerWhenReacton, 3);
      await tester.pump();
      expect(listenerValues, equals([2]));

      // Set to even -> should call listener
      store.set(_listenerWhenReacton, 4);
      await tester.pump();
      expect(listenerValues, equals([2, 4]));
    });

    testWidgets('listener receives the correct current value',
        (WidgetTester tester) async {
      final store = ReactonStore();
      final receivedValues = <String>[];

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonListener<String>(
            reacton: _listenerValueReacton,
            listener: (context, value) {
              receivedValues.add(value);
            },
            child: const Text('listener', textDirection: TextDirection.ltr),
          ),
          store: store,
        ),
      );

      store.set(_listenerValueReacton, 'first');
      await tester.pump();
      expect(receivedValues.last, equals('first'));

      store.set(_listenerValueReacton, 'second');
      await tester.pump();
      expect(receivedValues.last, equals('second'));

      store.set(_listenerValueReacton, 'third');
      await tester.pump();
      expect(receivedValues, equals(['first', 'second', 'third']));
    });
  });

  // ========================================================================
  // Group 8: ReactonSelector
  // ========================================================================
  group('ReactonSelector', () {
    testWidgets('renders the selected sub-value',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonSelector<_UserData, String>(
            reacton: _selectorReacton,
            selector: (user) => user.name,
            builder: (context, name) =>
                Text('name:$name', textDirection: TextDirection.ltr),
          ),
          store: store,
        ),
      );

      expect(find.text('name:Alice'), findsOneWidget);
    });

    testWidgets('rebuilds only when the selected value changes',
        (WidgetTester tester) async {
      final store = ReactonStore();
      int selectorBuildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonSelector<_UserData, String>(
            reacton: _selectorReacton,
            selector: (user) => user.name,
            builder: (context, name) {
              selectorBuildCount++;
              return Text('name:$name', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(selectorBuildCount, equals(1));

      // Change name -> should rebuild
      store.set(_selectorReacton, const _UserData('Charlie', 25));
      await tester.pump();

      expect(selectorBuildCount, equals(2));
      expect(find.text('name:Charlie'), findsOneWidget);
    });

    testWidgets('does NOT rebuild when unselected fields change',
        (WidgetTester tester) async {
      final store = ReactonStore();
      int buildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonSelector<_UserData, String>(
            reacton: _selectorNoRebuildReacton,
            selector: (user) => user.name,
            builder: (context, name) {
              buildCount++;
              return Text('name:$name', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(buildCount, equals(1));
      expect(find.text('name:Bob'), findsOneWidget);

      // Change only the age, NOT the name -> should NOT rebuild
      store.set(_selectorNoRebuildReacton, const _UserData('Bob', 99));
      await tester.pump();

      expect(buildCount, equals(1));
      expect(find.text('name:Bob'), findsOneWidget);

      // Change the name -> should rebuild
      store.set(_selectorNoRebuildReacton, const _UserData('Eve', 99));
      await tester.pump();

      expect(buildCount, equals(2));
      expect(find.text('name:Eve'), findsOneWidget);
    });

    testWidgets('works with complex types',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          ReactonSelector<_Pair<int, String>, int>(
            reacton: _selectorComplexReacton,
            selector: (pair) => pair.first,
            builder: (context, first) =>
                Text('first:$first', textDirection: TextDirection.ltr),
          ),
          store: store,
        ),
      );

      expect(find.text('first:1'), findsOneWidget);

      // Change only .second -> should NOT rebuild
      store.set(_selectorComplexReacton, const _Pair(1, 'two'));
      await tester.pump();
      expect(find.text('first:1'), findsOneWidget);

      // Change .first -> should rebuild
      store.set(_selectorComplexReacton, const _Pair(2, 'two'));
      await tester.pump();
      expect(find.text('first:2'), findsOneWidget);
    });
  });

  // ========================================================================
  // Group 9: Integration tests
  // ========================================================================
  group('Integration', () {
    testWidgets('full counter app with watch, set, and computed reacton',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              final count = context.watch(_intCounterReacton);
              final doubled = context.watch(_intDoubleReacton);
              final label = context.watch(_intLabelReacton);

              return Column(
                children: [
                  Text('count:$count', textDirection: TextDirection.ltr),
                  Text('doubled:$doubled', textDirection: TextDirection.ltr),
                  Text(label, textDirection: TextDirection.ltr),
                  ElevatedButton(
                    key: const Key('inc'),
                    onPressed: () =>
                        context.update(_intCounterReacton, (c) => c + 1),
                    child: const Text('+'),
                  ),
                ],
              );
            },
          ),
          store: store,
        ),
      );

      expect(find.text('count:0'), findsOneWidget);
      expect(find.text('doubled:0'), findsOneWidget);
      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('inc')));
      await tester.pump();

      expect(find.text('count:1'), findsOneWidget);
      expect(find.text('doubled:2'), findsOneWidget);
      expect(find.text('Count: 1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('inc')));
      await tester.pump();

      expect(find.text('count:2'), findsOneWidget);
      expect(find.text('doubled:4'), findsOneWidget);
      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('multiple widgets watching the same reacton all update',
        (WidgetTester tester) async {
      final store = ReactonStore();

      await tester.pumpWidget(
        _wrapWithScope(
          Column(
            children: [
              // Widget A watches _intSharedReacton via context.watch
              Builder(
                builder: (context) {
                  final val = context.watch(_intSharedReacton);
                  return Text('A:$val', textDirection: TextDirection.ltr);
                },
              ),
              // Widget B also watches _intSharedReacton
              ReactonBuilder<int>(
                reacton: _intSharedReacton,
                builder: (context, val) =>
                    Text('B:$val', textDirection: TextDirection.ltr),
              ),
              // Widget C via ReactonConsumer
              ReactonConsumer(
                builder: (context, ref) {
                  final val = ref.watch(_intSharedReacton);
                  return Text('C:$val', textDirection: TextDirection.ltr);
                },
              ),
            ],
          ),
          store: store,
        ),
      );

      expect(find.text('A:0'), findsOneWidget);
      expect(find.text('B:0'), findsOneWidget);
      expect(find.text('C:0'), findsOneWidget);

      store.set(_intSharedReacton, 42);
      await tester.pump();

      expect(find.text('A:42'), findsOneWidget);
      expect(find.text('B:42'), findsOneWidget);
      expect(find.text('C:42'), findsOneWidget);
    });

    testWidgets('batch updates cause watching widgets to rebuild with final state',
        (WidgetTester tester) async {
      final store = ReactonStore();
      int buildCount = 0;

      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              buildCount++;
              final sum = context.watch(_intBatchComputed);
              final v1 = context.watch(_intBatchReacton1);
              final v2 = context.watch(_intBatchReacton2);
              return Text('$v1+$v2=$sum', textDirection: TextDirection.ltr);
            },
          ),
          store: store,
        ),
      );

      expect(find.text('0+0=0'), findsOneWidget);
      final buildCountBefore = buildCount;

      // Batch both changes together
      store.batch(() {
        store.set(_intBatchReacton1, 10);
        store.set(_intBatchReacton2, 20);
      });
      await tester.pump();

      // After the batch, the widget should see the final state
      expect(find.text('10+20=30'), findsOneWidget);

      // The widget should have rebuilt minimally (batch coalesces notifications)
      // At least one rebuild should have occurred
      expect(buildCount, greaterThan(buildCountBefore));
    });

    testWidgets('context.reactonStore provides direct store access',
        (WidgetTester tester) async {
      final store = ReactonStore();

      late ReactonStore capturedStore;
      await tester.pumpWidget(
        _wrapWithScope(
          Builder(
            builder: (context) {
              capturedStore = context.reactonStore;
              return const SizedBox();
            },
          ),
          store: store,
        ),
      );

      expect(capturedStore, same(store));
    });
  });
}
