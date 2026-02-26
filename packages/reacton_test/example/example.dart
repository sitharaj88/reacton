import 'package:reacton/reacton.dart';
import 'package:reacton_test/reacton_test.dart';

// Define reactons to test.
final counterReacton = reacton(0, name: 'counter');
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

void main() {
  // Create an isolated test store with overrides.
  final store = TestReactonStore(
    overrides: [
      ReactonTestOverride(counterReacton, 10),
    ],
  );

  // Verify the override was applied.
  store.expectReacton(counterReacton, 10);

  // Computed reactons derive from overridden values.
  store.expectReacton(doubleCountReacton, 20);

  // Collect emitted values during a mutation.
  final values = store.collectValues(counterReacton, () {
    store.set(counterReacton, 42);
    store.set(counterReacton, 99);
  });
  print('Emitted values: $values'); // [42, 99]

  // Assert emission count.
  store.expectEmissionCount(counterReacton, () {
    store.set(counterReacton, 1);
    store.set(counterReacton, 2);
    store.set(counterReacton, 3);
  }, 3);

  store.dispose();
  print('All assertions passed.');
}
