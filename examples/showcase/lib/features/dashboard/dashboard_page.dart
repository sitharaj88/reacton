import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import '../../shared/state.dart';

// ============================================================================
// Dashboard Page
//
// Demonstrates:
//   - family()              parameterised reactons keyed by category name
//   - selector()            fine-grained sub-value watching
//   - computed chains       total and percentage derived from family values
//   - batch()               atomic updates across multiple reactons
//   - ReactonConsumer       watching multiple heterogeneous reactons
//   - ReactonBuilder        scoped rebuilds per category card
// ============================================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          // Batch randomise button
          IconButton(
            tooltip: 'Randomise all (batch)',
            icon: const Icon(Icons.casino_outlined),
            onPressed: () => _randomiseAll(context),
          ),
          // Reset button
          IconButton(
            tooltip: 'Reset all',
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetAll(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Text(
              'Family, Selector & Batch',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'family() creates parameterised reactons on demand. '
              'selector() watches a sub-value of a reacton for fine-grained '
              'rebuilds. batch() groups multiple mutations into a single '
              'propagation pass.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // --- User profile (selector demo) ---
            _UserProfileCard(),
            const SizedBox(height: 16),

            // --- Total (computed chain) ---
            _TotalCard(),
            const SizedBox(height: 16),

            // --- Category cards (family demo) ---
            Text('Categories (family)', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                for (final category in dashboardCategories)
                  _CategoryCard(category: category),
              ],
            ),
            const SizedBox(height: 16),

            // --- Percentage breakdown (computed chain) ---
            _PercentageCard(),
          ],
        ),
      ),
    );
  }

  /// batch() ensures all four category updates propagate as one atomic change.
  /// Computed reactons (total, percentages) recompute only once.
  void _randomiseAll(BuildContext context) {
    final store = context.reactonStore;
    final rng = Random();

    store.batch(() {
      for (final cat in dashboardCategories) {
        store.set(
          categoryValueFamily(cat) as WritableReacton<int>,
          rng.nextInt(200),
        );
      }
    });
  }

  void _resetAll(BuildContext context) {
    final store = context.reactonStore;
    store.batch(() {
      for (final cat in dashboardCategories) {
        store.set(
          categoryValueFamily(cat) as WritableReacton<int>,
          0,
        );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// User profile card -- demonstrates selector()
// ---------------------------------------------------------------------------

class _UserProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // selector() only rebuilds when the selected sub-value changes.
    // Updating "notifications" will NOT cause the name selector to fire.
    return ReactonConsumer(
      builder: (context, ref) {
        final name = ref.watch(userNameSelector);
        final notifications = ref.watch(notificationCountSelector);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'selector() watches only the name sub-value',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Badge(
                  label: Text('$notifications'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Add notification',
                  icon: const Icon(Icons.add_alert_outlined),
                  onPressed: () {
                    ref.update(userProfileReacton, (profile) {
                      return {
                        ...profile,
                        'notifications':
                            (profile['notifications'] as int) + 1,
                      };
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Total card -- computed chain
// ---------------------------------------------------------------------------

class _TotalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ReactonBuilder<int>(
      reacton: dashboardTotalReacton,
      builder: (context, total) {
        return Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.analytics, color: colors.onPrimaryContainer, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Across Categories',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$total',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'computed()',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Category card -- family() reacton per category
// ---------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  final String category;
  const _CategoryCard({required this.category});

  static const _categoryIcons = <String, IconData>{
    'Sales': Icons.point_of_sale,
    'Users': Icons.people,
    'Orders': Icons.shopping_bag,
    'Revenue': Icons.attach_money,
  };

  static const _categoryColors = <String, Color>{
    'Sales': Colors.blue,
    'Users': Colors.green,
    'Orders': Colors.orange,
    'Revenue': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _categoryIcons[category] ?? Icons.category;
    final color = _categoryColors[category] ?? Colors.grey;

    // Each category has its own reacton via family().
    // Updating one category does NOT rebuild the other cards.
    return ReactonBuilder<int>(
      reacton: categoryValueFamily(category),
      builder: (context, value) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '$value',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _SmallButton(
                      icon: Icons.add,
                      onTap: () => context.update(
                        categoryValueFamily(category) as WritableReacton<int>,
                        (v) => v + 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _SmallButton(
                      icon: Icons.remove,
                      onTap: () => context.update(
                        categoryValueFamily(category) as WritableReacton<int>,
                        (v) => max(0, v - 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Percentage breakdown -- computed chain over family values
// ---------------------------------------------------------------------------

class _PercentageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ReactonBuilder<Map<String, double>>(
      reacton: categoryPercentagesReacton,
      builder: (context, percentages) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Breakdown (computed chain)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (percentages.isEmpty)
                  Text(
                    'Add values to categories to see the breakdown.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else
                  for (final entry in percentages.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(entry.key,
                                style: theme.textTheme.bodyMedium),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: entry.value / 100,
                                minHeight: 12,
                                backgroundColor: colors.surfaceContainerHigh,
                                color: _CategoryCard._categoryColors[entry.key] ??
                                    colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 52,
                            child: Text(
                              '${entry.value.toStringAsFixed(1)}%',
                              style: theme.textTheme.labelMedium,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Small icon button
// ---------------------------------------------------------------------------

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}
