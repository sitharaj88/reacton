# Analytics Dashboard

An analytics dashboard with multiple polling data sources, selectors for widget-level optimization, lenses for deep config updates, and computed aggregations. Demonstrates `reactonQuery` with polling, `selector`, `lens`, and `computed` for a data-rich UI.

## Full Source

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- Models ---

class SalesData {
  final double revenue;
  final int orders;
  final int visitors;
  final double conversionRate;
  final List<DailySales> daily;

  const SalesData({
    required this.revenue,
    required this.orders,
    required this.visitors,
    required this.conversionRate,
    required this.daily,
  });
}

class DailySales {
  final String date;
  final double revenue;
  final int orders;

  const DailySales({
    required this.date,
    required this.revenue,
    required this.orders,
  });
}

class SystemHealth {
  final double cpuUsage;
  final double memoryUsage;
  final int activeConnections;
  final int errorCount;
  final double uptime;

  const SystemHealth({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.activeConnections,
    required this.errorCount,
    required this.uptime,
  });
}

class DashboardConfig {
  final String dateRange;
  final String currency;
  final bool showTrends;
  final RefreshSettings refresh;

  const DashboardConfig({
    this.dateRange = '7d',
    this.currency = 'USD',
    this.showTrends = true,
    this.refresh = const RefreshSettings(),
  });

  DashboardConfig copyWith({
    String? dateRange,
    String? currency,
    bool? showTrends,
    RefreshSettings? refresh,
  }) =>
      DashboardConfig(
        dateRange: dateRange ?? this.dateRange,
        currency: currency ?? this.currency,
        showTrends: showTrends ?? this.showTrends,
        refresh: refresh ?? this.refresh,
      );
}

class RefreshSettings {
  final int salesIntervalSec;
  final int healthIntervalSec;

  const RefreshSettings({
    this.salesIntervalSec = 30,
    this.healthIntervalSec = 10,
  });

  RefreshSettings copyWith({
    int? salesIntervalSec,
    int? healthIntervalSec,
  }) =>
      RefreshSettings(
        salesIntervalSec: salesIntervalSec ?? this.salesIntervalSec,
        healthIntervalSec: healthIntervalSec ?? this.healthIntervalSec,
      );
}

// --- Simulated APIs ---

final _rng = Random();

class DashboardApi {
  static Future<SalesData> fetchSales(String dateRange) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final baseRevenue = 12500.0 + _rng.nextDouble() * 500;
    return SalesData(
      revenue: baseRevenue,
      orders: 340 + _rng.nextInt(20),
      visitors: 8200 + _rng.nextInt(300),
      conversionRate: 3.8 + _rng.nextDouble() * 0.5,
      daily: List.generate(7, (i) => DailySales(
        date: 'Day ${i + 1}',
        revenue: 1500 + _rng.nextDouble() * 500,
        orders: 40 + _rng.nextInt(15),
      )),
    );
  }

  static Future<SystemHealth> fetchHealth() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SystemHealth(
      cpuUsage: 30 + _rng.nextDouble() * 40,
      memoryUsage: 50 + _rng.nextDouble() * 25,
      activeConnections: 120 + _rng.nextInt(50),
      errorCount: _rng.nextInt(5),
      uptime: 99.9 + _rng.nextDouble() * 0.09,
    );
  }
}

// --- Dashboard Config with Lenses ---

final configReacton = reacton(const DashboardConfig(), name: 'config');

/// Lens into the dateRange field of the config.
final dateRangeLens = lens<DashboardConfig, String>(
  configReacton,
  get: (config) => config.dateRange,
  set: (config, dateRange) => config.copyWith(dateRange: dateRange),
  name: 'config.dateRange',
);

/// Lens into the currency field.
final currencyLens = lens<DashboardConfig, String>(
  configReacton,
  get: (config) => config.currency,
  set: (config, currency) => config.copyWith(currency: currency),
  name: 'config.currency',
);

/// Lens into the showTrends flag.
final showTrendsLens = lens<DashboardConfig, bool>(
  configReacton,
  get: (config) => config.showTrends,
  set: (config, show) => config.copyWith(showTrends: show),
  name: 'config.showTrends',
);

/// Lens into the nested refresh settings.
final refreshSettingsLens = lens<DashboardConfig, RefreshSettings>(
  configReacton,
  get: (config) => config.refresh,
  set: (config, refresh) => config.copyWith(refresh: refresh),
  name: 'config.refresh',
);

/// Nested lens: sales interval within refresh settings.
final salesIntervalLens = lens<RefreshSettings, int>(
  refreshSettingsLens,
  get: (r) => r.salesIntervalSec,
  set: (r, v) => r.copyWith(salesIntervalSec: v),
  name: 'config.refresh.salesInterval',
);

// --- Query Reactons with Polling ---

final salesQuery = reactonQuery<SalesData>(
  queryFn: (read) => DashboardApi.fetchSales(read(dateRangeLens)),
  config: QueryConfig(
    staleTime: const Duration(seconds: 15),
    cacheTime: const Duration(minutes: 5),
    pollInterval: const Duration(seconds: 30),
    retryPolicy: RetryPolicy(maxAttempts: 3),
  ),
  name: 'salesQuery',
);

final healthQuery = reactonQuery<SystemHealth>(
  queryFn: (_) => DashboardApi.fetchHealth(),
  config: QueryConfig(
    staleTime: const Duration(seconds: 5),
    cacheTime: const Duration(minutes: 2),
    pollInterval: const Duration(seconds: 10),
  ),
  name: 'healthQuery',
);

// --- Selectors (widget-level optimization) ---

/// Selector: extract only the revenue from the sales query.
final revenueSelector = selector<AsyncValue<SalesData>, double?>(
  salesQuery,
  (state) => state.when(
    loading: () => null,
    data: (data) => data.revenue,
    error: (_, __) => null,
  ),
  name: 'revenueSelector',
);

/// Selector: extract only the order count.
final ordersSelector = selector<AsyncValue<SalesData>, int?>(
  salesQuery,
  (state) => state.when(
    loading: () => null,
    data: (data) => data.orders,
    error: (_, __) => null,
  ),
  name: 'ordersSelector',
);

/// Selector: extract CPU usage from health.
final cpuSelector = selector<AsyncValue<SystemHealth>, double?>(
  healthQuery,
  (state) => state.when(
    loading: () => null,
    data: (data) => data.cpuUsage,
    error: (_, __) => null,
  ),
  name: 'cpuSelector',
);

/// Selector: extract memory usage from health.
final memorySelector = selector<AsyncValue<SystemHealth>, double?>(
  healthQuery,
  (state) => state.when(
    loading: () => null,
    data: (data) => data.memoryUsage,
    error: (_, __) => null,
  ),
  name: 'memorySelector',
);

// --- Computed Aggregations ---

/// Average daily revenue from the sales data.
final avgDailyRevenue = computed<double?>((read) {
  final state = read(salesQuery);
  return state.when(
    loading: () => null,
    data: (data) {
      if (data.daily.isEmpty) return 0.0;
      final total = data.daily.fold(0.0, (sum, d) => sum + d.revenue);
      return total / data.daily.length;
    },
    error: (_, __) => null,
  );
}, name: 'avgDailyRevenue');

/// Revenue trend: positive means growing, negative means declining.
final revenueTrend = computed<double?>((read) {
  final state = read(salesQuery);
  return state.when(
    loading: () => null,
    data: (data) {
      if (data.daily.length < 2) return 0.0;
      final firstHalf = data.daily.sublist(0, data.daily.length ~/ 2);
      final secondHalf = data.daily.sublist(data.daily.length ~/ 2);
      final firstAvg =
          firstHalf.fold(0.0, (s, d) => s + d.revenue) / firstHalf.length;
      final secondAvg =
          secondHalf.fold(0.0, (s, d) => s + d.revenue) / secondHalf.length;
      return ((secondAvg - firstAvg) / firstAvg) * 100;
    },
    error: (_, __) => null,
  );
}, name: 'revenueTrend');

/// System health score: weighted average of CPU, memory, uptime.
final healthScore = computed<double?>((read) {
  final state = read(healthQuery);
  return state.when(
    loading: () => null,
    data: (data) {
      // Lower CPU and memory usage is better; higher uptime is better
      final cpuScore = (100 - data.cpuUsage) / 100;
      final memScore = (100 - data.memoryUsage) / 100;
      final uptimeScore = data.uptime / 100;
      return (cpuScore * 0.3 + memScore * 0.3 + uptimeScore * 0.4) * 100;
    },
    error: (_, __) => null,
  );
}, name: 'healthScore');

// --- App ---

void main() => runApp(ReactonScope(child: const DashboardApp()));

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analytics Dashboard',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateRange = context.watch(dateRangeLens);
    final showTrends = context.watch(showTrendsLens);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          // Date range selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '7d', label: Text('7D')),
              ButtonSegment(value: '30d', label: Text('30D')),
              ButtonSegment(value: '90d', label: Text('90D')),
            ],
            selected: {dateRange},
            onSelectionChanged: (v) =>
                context.set(dateRangeLens, v.first),
          ),
          const SizedBox(width: 8),
          // Trends toggle
          IconButton(
            icon: Icon(showTrends
                ? Icons.trending_up
                : Icons.trending_flat),
            tooltip: 'Toggle trends',
            onPressed: () =>
                context.set(showTrendsLens, !showTrends),
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI cards row
            Text('Key Metrics',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _RevenueCard()),
                SizedBox(width: 12),
                Expanded(child: _OrdersCard()),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _CpuCard()),
                SizedBox(width: 12),
                Expanded(child: _MemoryCard()),
              ],
            ),

            const SizedBox(height: 24),

            // Aggregations section
            Text('Aggregations',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _AggregationsPanel(),

            const SizedBox(height: 24),

            // Daily breakdown
            Text('Daily Breakdown',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _DailyBreakdownTable(),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const _SettingsSheet(),
    );
  }
}

// --- KPI Cards (each uses a selector for minimal rebuilds) ---

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    final revenue = context.watch(revenueSelector);
    final trend = context.watch(revenueTrend);
    final showTrends = context.watch(showTrendsLens);
    final currency = context.watch(currencyLens);

    return _KpiCard(
      title: 'Revenue',
      value: revenue != null
          ? '$currency ${revenue.toStringAsFixed(0)}'
          : 'Loading...',
      trend: showTrends ? trend : null,
      icon: Icons.attach_money,
      color: Colors.green,
    );
  }
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard();

  @override
  Widget build(BuildContext context) {
    final orders = context.watch(ordersSelector);

    return _KpiCard(
      title: 'Orders',
      value: orders?.toString() ?? 'Loading...',
      icon: Icons.shopping_bag_outlined,
      color: Colors.blue,
    );
  }
}

class _CpuCard extends StatelessWidget {
  const _CpuCard();

  @override
  Widget build(BuildContext context) {
    final cpu = context.watch(cpuSelector);

    return _KpiCard(
      title: 'CPU',
      value: cpu != null ? '${cpu.toStringAsFixed(1)}%' : 'Loading...',
      icon: Icons.memory,
      color: cpu != null && cpu > 80 ? Colors.red : Colors.orange,
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard();

  @override
  Widget build(BuildContext context) {
    final memory = context.watch(memorySelector);

    return _KpiCard(
      title: 'Memory',
      value: memory != null ? '${memory.toStringAsFixed(1)}%' : 'Loading...',
      icon: Icons.storage,
      color: memory != null && memory > 85 ? Colors.red : Colors.purple,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final double? trend;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    this.trend,
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
                Text(title, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            if (trend != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: trend! >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: trend! >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Aggregations Panel ---

class _AggregationsPanel extends StatelessWidget {
  const _AggregationsPanel();

  @override
  Widget build(BuildContext context) {
    final avgRevenue = context.watch(avgDailyRevenue);
    final score = context.watch(healthScore);
    final currency = context.watch(currencyLens);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('Avg Daily Revenue',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    avgRevenue != null
                        ? '$currency ${avgRevenue.toStringAsFixed(0)}'
                        : '--',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: Column(
                children: [
                  Text('Health Score',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    score != null ? '${score.toStringAsFixed(1)}%' : '--',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: score != null && score > 80
                            ? Colors.green
                            : Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Daily Breakdown Table ---

class _DailyBreakdownTable extends StatelessWidget {
  const _DailyBreakdownTable();

  @override
  Widget build(BuildContext context) {
    final salesState = context.watch(salesQuery);
    final currency = context.watch(currencyLens);

    return salesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (data) => Card(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Day')),
            DataColumn(label: Text('Revenue'), numeric: true),
            DataColumn(label: Text('Orders'), numeric: true),
          ],
          rows: data.daily.map((d) => DataRow(cells: [
            DataCell(Text(d.date)),
            DataCell(Text('$currency ${d.revenue.toStringAsFixed(0)}')),
            DataCell(Text('${d.orders}')),
          ])).toList(),
        ),
      ),
    );
  }
}

// --- Settings Sheet (lens-driven config updates) ---

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final currency = context.watch(currencyLens);
    final salesInterval = context.watch(salesIntervalLens);
    final showTrends = context.watch(showTrendsLens);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard Settings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Currency
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Currency'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'USD', label: Text('\$')),
                  ButtonSegment(value: 'EUR', label: Text('\u20AC')),
                  ButtonSegment(value: 'GBP', label: Text('\u00A3')),
                ],
                selected: {currency},
                onSelectionChanged: (v) =>
                    context.set(currencyLens, v.first),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Show trends
          SwitchListTile(
            title: const Text('Show trend indicators'),
            value: showTrends,
            onChanged: (v) => context.set(showTrendsLens, v),
            contentPadding: EdgeInsets.zero,
          ),

          // Sales poll interval
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales refresh (sec)'),
              DropdownButton<int>(
                value: salesInterval,
                items: [10, 15, 30, 60]
                    .map((v) => DropdownMenuItem(
                        value: v, child: Text('${v}s')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) context.set(salesIntervalLens, v);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Walkthrough

### Data Models

`SalesData` holds aggregate metrics and a list of `DailySales` records. `SystemHealth` captures infrastructure metrics. `DashboardConfig` is a deeply nested immutable config object with `RefreshSettings` inside it.

### Lenses for Deep Config Updates

Lenses provide bidirectional access into nested structures:

```dart
final configReacton = reacton(const DashboardConfig(), name: 'config');

final dateRangeLens = lens<DashboardConfig, String>(
  configReacton,
  get: (config) => config.dateRange,
  set: (config, dateRange) => config.copyWith(dateRange: dateRange),
  name: 'config.dateRange',
);
```

Lenses compose. The `salesIntervalLens` focuses through two levels of nesting:

```dart
final refreshSettingsLens = lens<DashboardConfig, RefreshSettings>(
  configReacton,
  get: (config) => config.refresh,
  set: (config, refresh) => config.copyWith(refresh: refresh),
);

final salesIntervalLens = lens<RefreshSettings, int>(
  refreshSettingsLens,
  get: (r) => r.salesIntervalSec,
  set: (r, v) => r.copyWith(salesIntervalSec: v),
);
```

In the UI, updating a nested field is a single `context.set` call:

```dart
context.set(salesIntervalLens, 15);
// Equivalent to: config.copyWith(refresh: config.refresh.copyWith(salesIntervalSec: 15))
```

### Query Reactons with Polling

```dart
final salesQuery = reactonQuery<SalesData>(
  queryFn: (read) => DashboardApi.fetchSales(read(dateRangeLens)),
  config: QueryConfig(
    staleTime: const Duration(seconds: 15),
    cacheTime: const Duration(minutes: 5),
    pollInterval: const Duration(seconds: 30),
  ),
  name: 'salesQuery',
);
```

`pollInterval` causes the query to refetch automatically on a timer. The `queryFn` reads `dateRangeLens`, so changing the date range also triggers an immediate refetch. Both the polling and the reactive dependency work together.

### Selectors for Widget-Level Optimization

```dart
final revenueSelector = selector<AsyncValue<SalesData>, double?>(
  salesQuery,
  (state) => state.when(
    loading: () => null,
    data: (data) => data.revenue,
    error: (_, __) => null,
  ),
  name: 'revenueSelector',
);
```

A selector watches a source reacton but only notifies its subscribers when the extracted sub-value changes. The `_RevenueCard` widget watches `revenueSelector`, so it only rebuilds when the revenue number changes -- not when orders, visitors, or daily data change. On a dashboard with many widgets sharing the same data source, this prevents unnecessary rebuilds.

### Computed Aggregations

```dart
final avgDailyRevenue = computed<double?>((read) {
  final state = read(salesQuery);
  return state.when(
    loading: () => null,
    data: (data) {
      final total = data.daily.fold(0.0, (sum, d) => sum + d.revenue);
      return total / data.daily.length;
    },
    error: (_, __) => null,
  );
}, name: 'avgDailyRevenue');
```

The `revenueTrend` computed reacton compares the first and second halves of the daily data to determine whether revenue is trending up or down. The `healthScore` combines CPU, memory, and uptime into a weighted composite score. All three recompute automatically when their source queries poll new data.

### KPI Cards with Selectors

Each card is a separate `StatelessWidget` that watches only its specific selector:

```dart
class _RevenueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final revenue = context.watch(revenueSelector);
    final trend = context.watch(revenueTrend);
    final showTrends = context.watch(showTrendsLens);
    final currency = context.watch(currencyLens);
    // ...
  }
}
```

This means the revenue card rebuilds only when revenue, trend, currency, or the trends toggle changes. It does not rebuild when CPU usage or memory data arrives from the health query.

### Settings Sheet with Lenses

The settings sheet reads and writes config values through lenses:

```dart
SegmentedButton<String>(
  selected: {currency},
  onSelectionChanged: (v) => context.set(currencyLens, v.first),
),

SwitchListTile(
  value: showTrends,
  onChanged: (v) => context.set(showTrendsLens, v),
),
```

Each `context.set(lens, value)` call updates the nested field inside the `DashboardConfig` object immutably. The dashboard immediately reflects the change because widgets watch the same lenses.

## Key Takeaways

1. **Selectors prevent unnecessary widget rebuilds** -- Each KPI card watches only the specific value it displays, not the entire query response. On a data-dense dashboard, this is a significant performance win.
2. **Lenses simplify deeply nested config updates** -- Instead of manually constructing `copyWith` chains, a lens provides a single `set` call for any depth of nesting.
3. **Query polling keeps data fresh automatically** -- `pollInterval` in `QueryConfig` triggers periodic refetches without manual timers or effects.
4. **Computed aggregations derive insights from raw data** -- Averages, trends, and composite scores are expressed declaratively and update automatically when source data changes.
5. **Lenses compose for arbitrary depth** -- `salesIntervalLens` focuses through `configReacton -> refreshSettingsLens -> salesIntervalSec`, and each level is independently reusable.

## What's Next

- [Search with Debounce](./search-with-debounce) -- Query caching and debounced input
- [Real-Time Chat](./real-time-chat) -- Sagas for WebSocket orchestration
- [Pagination](./pagination) -- Infinite scroll with query reactons
