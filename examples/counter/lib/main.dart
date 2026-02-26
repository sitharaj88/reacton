import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// ============================================================================
// LEVEL 1 API EXAMPLE: Counter App
//
// Demonstrates the simplest Reacton usage:
//   - reacton() to create state
//   - context.watch() to read reactively
//   - context.update() to modify state
//   - ReactonScope to provide the store
// ============================================================================

// 1. Create reactons (top-level declarations)
final counterReacton = reacton(0, name: 'counter');

// 2. Derived state with computed (Level 2 preview)
final doubleCountReacton = computed(
  (read) => read(counterReacton) * 2,
  name: 'doubleCount',
);

final isEvenReacton = computed(
  (read) => read(counterReacton) % 2 == 0,
  name: 'isEven',
);

void main() {
  // 3. Wrap app with ReactonScope
  runApp(ReactonScope(child: const CounterApp()));
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Counter',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Watch reactons - rebuilds automatically when values change
    final count = context.watch(counterReacton);
    final doubleCount = context.watch(doubleCountReacton);
    final isEven = context.watch(isEvenReacton);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reacton Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Double: $doubleCount',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isEven ? 'Even' : 'Odd',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isEven ? Colors.green : Colors.orange,
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'increment',
            // 5. Update state
            onPressed: () => context.update(counterReacton, (c) => c + 1),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: () => context.update(counterReacton, (c) => c - 1),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: () => context.set(counterReacton, 0),
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
