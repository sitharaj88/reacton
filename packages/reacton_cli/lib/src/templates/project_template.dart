/// Template for main.dart when running `reacton init`.
const mainDartTemplate = r'''
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import 'reactons/counter_reacton.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonScope(
      child: MaterialApp(
        title: 'Reacton App',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterReacton);

    return Scaffold(
      appBar: AppBar(title: const Text('Reacton App')),
      body: Center(
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.update(counterReacton, (n) => n + 1),
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

/// Template for a starter counter reacton.
const counterReactonTemplate = r'''
import 'package:reacton/reacton.dart';

/// A simple counter reacton to get you started.
final counterReacton = reacton<int>(0, name: 'counter');
''';

/// Template for analysis_options.yaml with reacton_lint enabled.
const analysisOptionsTemplate = r'''
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - avoid_read_in_build
    - prefer_computed
    - avoid_reacton_in_build
''';
