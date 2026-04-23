import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// Top-level async reactons drive the tests deterministically without timers.
final _userReacton = reacton<AsyncValue<String>>(
  const AsyncValue<String>.loading(),
  name: 'suspense_user',
);

final _aReacton = reacton<AsyncValue<int>>(
  const AsyncValue<int>.loading(),
  name: 'boundary_a',
);
final _bReacton = reacton<AsyncValue<String>>(
  const AsyncValue<String>.loading(),
  name: 'boundary_b',
);

Widget _wrap(ReactonStore store, Widget child) => ReactonScope(
      store: store,
      child: MaterialApp(home: Material(child: child)),
    );

void main() {
  group('ReactonSuspense', () {
    testWidgets('shows loading builder while AsyncLoading', (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<String>>(
        _userReacton,
        const AsyncValue<String>.loading(),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonSuspense<String>(
            reacton: _userReacton,
            loading: (_) => const Text('LOADING'),
            data: (_, v) => Text('DATA:$v'),
          ),
        ),
      );

      expect(find.text('LOADING'), findsOneWidget);
      expect(find.textContaining('DATA:'), findsNothing);
    });

    testWidgets('renders data builder once AsyncData arrives', (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<String>>(
        _userReacton,
        const AsyncValue<String>.loading(),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonSuspense<String>(
            reacton: _userReacton,
            loading: (_) => const Text('LOADING'),
            data: (_, v) => Text('DATA:$v'),
          ),
        ),
      );

      store.set<AsyncValue<String>>(
        _userReacton,
        const AsyncValue<String>.data('Alice'),
      );
      await tester.pump();

      expect(find.text('DATA:Alice'), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);
    });

    testWidgets('renders error builder when errored and no previous data',
        (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<String>>(
        _userReacton,
        AsyncValue<String>.error(Exception('boom')),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonSuspense<String>(
            reacton: _userReacton,
            loading: (_) => const Text('LOADING'),
            error: (_, err, __) => Text('ERR:$err'),
            data: (_, v) => Text('DATA:$v'),
          ),
        ),
      );

      expect(find.textContaining('ERR:'), findsOneWidget);
    });

    testWidgets(
      'keepPreviousData: renders last data during revalidation',
      (tester) async {
        final store = ReactonStore();
        store.forceSet<AsyncValue<String>>(
          _userReacton,
          const AsyncValue<String>.data('first'),
        );

        await tester.pumpWidget(
          _wrap(
            store,
            ReactonSuspense<String>(
              reacton: _userReacton,
              loading: (_) => const Text('LOADING'),
              data: (_, v) => Text('DATA:$v'),
            ),
          ),
        );
        expect(find.text('DATA:first'), findsOneWidget);

        store.set<AsyncValue<String>>(
          _userReacton,
          const AsyncValue<String>.loading('first'),
        );
        await tester.pump();

        expect(find.text('DATA:first'), findsOneWidget);
        expect(find.text('LOADING'), findsNothing);
      },
    );

    testWidgets(
      'keepPreviousData: false shows loading on revalidation',
      (tester) async {
        final store = ReactonStore();
        store.forceSet<AsyncValue<String>>(
          _userReacton,
          const AsyncValue<String>.data('first'),
        );

        await tester.pumpWidget(
          _wrap(
            store,
            ReactonSuspense<String>(
              reacton: _userReacton,
              keepPreviousData: false,
              loading: (_) => const Text('LOADING'),
              data: (_, v) => Text('DATA:$v'),
            ),
          ),
        );

        store.set<AsyncValue<String>>(
          _userReacton,
          const AsyncValue<String>.loading('first'),
        );
        await tester.pump();

        expect(find.text('LOADING'), findsOneWidget);
        expect(find.text('DATA:first'), findsNothing);
      },
    );

    testWidgets('error keeps previous data when keepPreviousData is true',
        (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<String>>(
        _userReacton,
        const AsyncValue<String>.data('cached'),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonSuspense<String>(
            reacton: _userReacton,
            loading: (_) => const Text('LOADING'),
            error: (_, err, __) => Text('ERR:$err'),
            data: (_, v) => Text('DATA:$v'),
          ),
        ),
      );
      expect(find.text('DATA:cached'), findsOneWidget);

      store.set<AsyncValue<String>>(
        _userReacton,
        AsyncValue<String>.error(Exception('net'), null, 'cached'),
      );
      await tester.pump();

      expect(find.text('DATA:cached'), findsOneWidget);
      expect(find.textContaining('ERR:'), findsNothing);
    });

    testWidgets('unsubscribes on dispose', (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<String>>(
        _userReacton,
        const AsyncValue<String>.loading(),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonSuspense<String>(
            reacton: _userReacton,
            loading: (_) => const Text('L'),
            data: (_, v) => Text('D:$v'),
          ),
        ),
      );

      // Remove the widget — subscription should be released.
      await tester.pumpWidget(_wrap(store, const SizedBox()));

      store.set<AsyncValue<String>>(
        _userReacton,
        const AsyncValue<String>.data('after'),
      );
      await tester.pump();
      // No crash, no rebuild of the now-gone widget.
    });
  });

  group('ReactonErrorBoundary', () {
    testWidgets('shows loading while any reacton is loading', (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<int>>(
        _aReacton,
        const AsyncValue<int>.data(1),
      );
      store.forceSet<AsyncValue<String>>(
        _bReacton,
        const AsyncValue<String>.loading(),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonErrorBoundary(
            reactons: [_aReacton, _bReacton],
            loading: (_) => const Text('L'),
            error: (_, __, ___, ____) => const Text('E'),
            child: const Text('CHILD'),
          ),
        ),
      );
      expect(find.text('L'), findsOneWidget);
      expect(find.text('CHILD'), findsNothing);
    });

    testWidgets(
      'renders child once every reacton has data',
      (tester) async {
        final store = ReactonStore();
        store.forceSet<AsyncValue<int>>(
          _aReacton,
          const AsyncValue<int>.loading(),
        );
        store.forceSet<AsyncValue<String>>(
          _bReacton,
          const AsyncValue<String>.loading(),
        );

        await tester.pumpWidget(
          _wrap(
            store,
            ReactonErrorBoundary(
              reactons: [_aReacton, _bReacton],
              loading: (_) => const Text('L'),
              error: (_, __, ___, ____) => const Text('E'),
              child: const Text('CHILD'),
            ),
          ),
        );
        expect(find.text('L'), findsOneWidget);

        store.set<AsyncValue<int>>(
          _aReacton,
          const AsyncValue<int>.data(10),
        );
        await tester.pump();
        expect(find.text('L'), findsOneWidget);

        store.set<AsyncValue<String>>(
          _bReacton,
          const AsyncValue<String>.data('ok'),
        );
        await tester.pump();
        expect(find.text('CHILD'), findsOneWidget);
      },
    );

    testWidgets('shows error builder when any reacton errors', (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<int>>(
        _aReacton,
        const AsyncValue<int>.data(1),
      );
      store.forceSet<AsyncValue<String>>(
        _bReacton,
        AsyncValue<String>.error(StateError('nope')),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonErrorBoundary(
            reactons: [_aReacton, _bReacton],
            loading: (_) => const Text('L'),
            error: (_, err, __, reset) => Text('ERR:$err'),
            child: const Text('CHILD'),
          ),
        ),
      );
      expect(find.textContaining('ERR:'), findsOneWidget);
      expect(find.text('CHILD'), findsNothing);
    });

    testWidgets('reset callback is invoked by the fallback', (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<int>>(
        _aReacton,
        AsyncValue<int>.error(StateError('x')),
      );
      store.forceSet<AsyncValue<String>>(
        _bReacton,
        const AsyncValue<String>.data('y'),
      );

      var reset = 0;
      await tester.pumpWidget(
        _wrap(
          store,
          ReactonErrorBoundary(
            reactons: [_aReacton, _bReacton],
            loading: (_) => const Text('L'),
            error: (_, err, __, retry) => TextButton(
              onPressed: retry,
              child: const Text('RETRY'),
            ),
            onReset: () => reset++,
            child: const Text('CHILD'),
          ),
        ),
      );

      await tester.tap(find.text('RETRY'));
      await tester.pump();

      expect(reset, 1);
    });

    testWidgets('error takes priority over loading', (tester) async {
      final store = ReactonStore();
      store.forceSet<AsyncValue<int>>(
        _aReacton,
        const AsyncValue<int>.loading(),
      );
      store.forceSet<AsyncValue<String>>(
        _bReacton,
        AsyncValue<String>.error(Exception('net')),
      );

      await tester.pumpWidget(
        _wrap(
          store,
          ReactonErrorBoundary(
            reactons: [_aReacton, _bReacton],
            loading: (_) => const Text('L'),
            error: (_, err, __, ____) => const Text('E'),
            child: const Text('CHILD'),
          ),
        ),
      );
      expect(find.text('E'), findsOneWidget);
      expect(find.text('L'), findsNothing);
    });

    testWidgets('assertion fires when reactons list is empty', (tester) async {
      expect(
        () => ReactonErrorBoundary(
          reactons: const [],
          loading: (_) => const SizedBox(),
          child: const SizedBox(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
