import 'package:reacton/reacton.dart';
import 'package:reacton_devtools/reacton_devtools.dart';

// Define some reactons for demonstration.
final counterReacton = reacton(0, name: 'counter');
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

void main() {
  // 1. Create a ReactonStore.
  final store = ReactonStore();

  // 2. Install DevTools extension - this registers service extensions
  //    that the Flutter DevTools UI uses to inspect state.
  ReactonDevToolsExtension.install(store);

  // Once installed, DevTools can:
  //   - Visualize the reactive dependency graph
  //   - Inspect current reacton values
  //   - View a timeline of state changes
  //   - Monitor per-reacton performance metrics
  //   - Edit reacton values at runtime

  // 3. Use the store as normal.
  store.set(counterReacton, 5);
  print('Counter: ${store.get(counterReacton)}');
  print('Double:  ${store.get(doubleCountReacton)}');

  // In a Flutter app, call install() once during app initialization:
  //
  // void main() {
  //   final store = ReactonStore();
  //   ReactonDevToolsExtension.install(store);
  //   runApp(ReactonScope(store: store, child: MyApp()));
  // }

  store.dispose();
}
