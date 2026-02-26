import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  late ReactonStore store;

  setUp(() {
    store = ReactonStore();
  });

  tearDown(() {
    store.dispose();
  });

  group('History (Time Travel)', () {
    test('records initial value', () {
      final counter = reacton(0, name: 'counter');
      final history = store.enableHistory(counter);

      expect(history.length, 1);
      expect(history.currentValue, 0);
      expect(history.currentIndex, 0);

      history.dispose();
    });

    test('records value changes', () {
      final counter = reacton(0, name: 'counter');
      final history = store.enableHistory(counter);

      store.set(counter, 1);
      store.set(counter, 2);
      store.set(counter, 3);

      expect(history.length, 4); // initial + 3 changes
      expect(history.currentValue, 3);

      history.dispose();
    });

    test('undo goes back', () {
      final counter = reacton(0, name: 'counter');
      final history = store.enableHistory(counter);

      store.set(counter, 1);
      store.set(counter, 2);

      expect(history.canUndo, isTrue);
      history.undo();
      expect(store.get(counter), 1);
      expect(history.currentValue, 1);

      history.undo();
      expect(store.get(counter), 0);

      history.dispose();
    });

    test('redo goes forward', () {
      final counter = reacton(0, name: 'counter');
      final history = store.enableHistory(counter);

      store.set(counter, 1);
      store.set(counter, 2);

      history.undo();
      history.undo();

      expect(history.canRedo, isTrue);
      history.redo();
      expect(store.get(counter), 1);

      history.redo();
      expect(store.get(counter), 2);

      expect(history.canRedo, isFalse);

      history.dispose();
    });

    test('undo then new value forks history', () {
      final counter = reacton(0, name: 'counter');
      final history = store.enableHistory(counter);

      store.set(counter, 1);
      store.set(counter, 2);
      store.set(counter, 3);

      // Undo to 1
      history.undo(); // 2
      history.undo(); // 1

      // New value - forks history, discards future (2, 3)
      store.set(counter, 10);

      expect(history.length, 3); // [0, 1, 10]
      expect(history.canRedo, isFalse);
      expect(history.currentValue, 10);

      history.dispose();
    });

    test('jumpTo works', () {
      final counter = reacton(0, name: 'counter');
      final history = store.enableHistory(counter);

      store.set(counter, 1);
      store.set(counter, 2);
      store.set(counter, 3);

      history.jumpTo(1);
      expect(store.get(counter), 1);

      history.jumpTo(0);
      expect(store.get(counter), 0);

      history.dispose();
    });

    test('respects maxHistory', () {
      final counter = reacton(0, name: 'counter');
      final history = store.enableHistory(counter, maxHistory: 3);

      store.set(counter, 1);
      store.set(counter, 2);
      store.set(counter, 3);
      store.set(counter, 4);

      // Only last 3 entries should remain
      expect(history.length, 3);

      history.dispose();
    });
  });
}
