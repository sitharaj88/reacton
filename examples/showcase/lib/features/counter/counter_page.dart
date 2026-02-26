import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import '../../shared/state.dart';

// ============================================================================
// Counter Page
//
// Demonstrates the foundational Reacton primitives:
//   - reacton()         writable state
//   - computed()        derived / read-only state
//   - context.watch()   subscribe to changes (rebuilds widget)
//   - context.set()     write a new value
//   - context.update()  transform the current value
//   - ReactonBuilder    widget-level subscription
// ============================================================================

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch() subscribes this widget to the reacton.
    // Whenever counterReacton changes, only this widget rebuilds.
    final count = context.watch(counterReacton);
    final doubleCount = context.watch(doubleCountReacton);
    final isEven = context.watch(isEvenReacton);
    final label = context.watch(counterLabelReacton);

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Text(
              'Basic State Management',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'reacton() creates writable state. computed() derives values '
              'that update automatically. context.watch() subscribes the '
              'widget to changes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // --- Main counter display ---
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Action buttons ---
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        context.update(counterReacton, (c) => c + 1),
                    icon: const Icon(Icons.add),
                    label: const Text('Increment'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.update(counterReacton, (c) => c - 1),
                    icon: const Icon(Icons.remove),
                    label: const Text('Decrement'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.set(counterReacton, 0),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Derived state cards ---
            Text(
              'Derived State (computed)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Double',
                    value: '$doubleCount',
                    icon: Icons.looks_two,
                    color: colors.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title: 'Parity',
                    value: isEven ? 'Even' : 'Odd',
                    icon: isEven ? Icons.check_circle : Icons.circle_outlined,
                    color: isEven ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- ReactonBuilder demo ---
            Text(
              'ReactonBuilder Widget',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'ReactonBuilder provides a scoped subscription to a single '
              'reacton. Only its subtree rebuilds on change.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ReactonBuilder<int>(
              reacton: counterReacton,
              builder: (context, value) {
                return Card(
                  color: colors.secondaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.widgets,
                      color: colors.onSecondaryContainer,
                    ),
                    title: Text(
                      'ReactonBuilder says: $value',
                      style: TextStyle(color: colors.onSecondaryContainer),
                    ),
                    subtitle: Text(
                      'This card rebuilds independently via ReactonBuilder',
                      style: TextStyle(
                        color: colors.onSecondaryContainer.withAlpha(179),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
