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

  group('StateBranch', () {
    test('reads from parent when no override', () {
      final counter = reacton(10, name: 'counter');
      store.get(counter); // initialize

      final branch = store.createBranch('test');
      expect(branch.get(counter), 10);
    });

    test('writes do not affect parent', () {
      final counter = reacton(0, name: 'counter');
      store.get(counter);

      final branch = store.createBranch('test');
      branch.set(counter, 42);

      expect(branch.get(counter), 42);
      expect(store.get(counter), 0); // parent unchanged
    });

    test('diff shows changes', () {
      final counter = reacton(0, name: 'counter');
      final name = reacton('hello', name: 'name');
      store.get(counter);
      store.get(name);

      final branch = store.createBranch('test');
      branch.set(counter, 5);

      final diff = branch.diff();
      expect(diff.changeCount, 1);
      expect(diff.changes[counter.ref]!.branchValue, 5);
    });

    test('merge applies changes to parent', () {
      final counter = reacton(0, name: 'counter');
      store.get(counter);

      final branch = store.createBranch('test');
      branch.set(counter, 99);

      store.mergeBranch(branch);
      expect(store.get(counter), 99);
      expect(branch.isMerged, isTrue);
    });

    test('discard clears branch', () {
      final counter = reacton(0, name: 'counter');
      store.get(counter);

      final branch = store.createBranch('test');
      branch.set(counter, 99);
      branch.discard();

      expect(branch.isDiscarded, isTrue);
      expect(branch.isClosed, isTrue);
    });

    test('cannot modify closed branch', () {
      final counter = reacton(0, name: 'counter');
      store.get(counter);

      final branch = store.createBranch('test');
      branch.discard();

      expect(
        () => branch.set(counter, 1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
