import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import 'test_store.dart';

/// Widget testing extensions for Reacton.
extension ReactonWidgetTester on WidgetTester {
  /// Pump a widget wrapped in a [ReactonScope] with optional overrides.
  ///
  /// ```dart
  /// await tester.pumpReacton(
  ///   CounterWidget(),
  ///   overrides: [ReactonTestOverride(counterReacton, 10)],
  /// );
  /// ```
  Future<void> pumpReacton(
    Widget widget, {
    List<TestOverride>? overrides,
    ReactonStore? store,
  }) async {
    final testStore = store ?? TestReactonStore(overrides: overrides);
    await pumpWidget(
      ReactonScope(
        store: testStore,
        child: MaterialApp(home: widget),
      ),
    );
  }

  /// Get the [ReactonStore] from the widget tree.
  ReactonStore get reactonStore {
    final scope = widget<ReactonScope>(find.byType(ReactonScope));
    return scope.store;
  }

  /// Set a reacton value in the store and pump.
  Future<void> setReactonAndPump<T>(WritableReacton<T> reacton, T value) async {
    reactonStore.set(reacton, value);
    await pump();
  }

  /// Update a reacton value in the store and pump.
  Future<void> updateReactonAndPump<T>(
    WritableReacton<T> reacton,
    T Function(T) updater,
  ) async {
    reactonStore.update(reacton, updater);
    await pump();
  }
}
