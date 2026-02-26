import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// Define reactons at the top level.
final counterReacton = reacton(0, name: 'counter');
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

void main() => runApp(ReactonScope(child: const CounterApp()));

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch subscribes and rebuilds on change.
    final count = context.watch(counterReacton);
    final doubled = context.watch(doubleCountReacton);

    return Scaffold(
      appBar: AppBar(title: const Text('Reacton Counter')),
      body: Center(
        child: Text('Count: $count (x2 = $doubled)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.update(counterReacton, (n) => n + 1),
        child: const Icon(Icons.add),
      ),
    );
  }
}
