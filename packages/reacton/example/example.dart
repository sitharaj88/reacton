import 'package:reacton/reacton.dart';

// Define reactons at the top level (they are lightweight descriptors).
final counterReacton = reacton(0, name: 'counter');
final nameReacton = reacton('World', name: 'name');

// Derived state: automatically recomputes when dependencies change.
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);
final greetingReacton = computed(
  (read) => 'Hello, ${read(nameReacton)}! Count: ${read(counterReacton)}',
  name: 'greeting',
);

void main() {
  final store = ReactonStore();

  // Read initial values.
  print(store.get(counterReacton)); // 0
  print(store.get(doubleCountReacton)); // 0

  // Subscribe to changes.
  final unsubscribe = store.subscribe(greetingReacton, (value) {
    print('Greeting changed: $value');
  });

  // Write values — computed reactons update automatically.
  store.set(counterReacton, 5);
  print(store.get(doubleCountReacton)); // 10

  store.update(counterReacton, (n) => n + 1);
  print(store.get(counterReacton)); // 6

  store.set(nameReacton, 'Dart');
  print(store.get(greetingReacton)); // Hello, Dart! Count: 6

  // Clean up.
  unsubscribe();
  store.dispose();
}
