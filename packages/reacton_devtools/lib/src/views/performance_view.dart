import 'package:flutter/material.dart';
import '../services/reacton_service.dart';

/// Performance profiler view for DevTools.
///
/// Shows recomputation counts, propagation times,
/// and identifies hot paths (frequently recomputing reactons).
/// Fetches real metrics from the DevTools service extension.
class PerformanceView extends StatefulWidget {
  final ReactonDevToolsService service;

  const PerformanceView({super.key, required this.service});

  @override
  State<PerformanceView> createState() => _PerformanceViewState();
}

class _PerformanceViewState extends State<PerformanceView> {
  List<PerformanceEntry> _data = [];
  bool _loading = true;
  String? _error;
  bool _showOnlyHotPaths = false;

  List<PerformanceEntry> get _filteredData {
    if (_showOnlyHotPaths) {
      return _data.where((d) => d.recomputeCount > 10).toList();
    }
    return _data;
  }

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.service.getPerformance();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Failed to load performance data: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPerformance,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final data = _filteredData;

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Text(
                'Performance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Hot paths only'),
                selected: _showOnlyHotPaths,
                onSelected: (v) => setState(() => _showOnlyHotPaths = v),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loadPerformance,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Summary cards
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _SummaryCard(
                label: 'Total Reactons',
                value: '${_data.length}',
                icon: Icons.circle,
                color: Colors.blue,
              ),
              _SummaryCard(
                label: 'Total Recomputes',
                value:
                    '${_data.fold<int>(0, (s, d) => s + d.recomputeCount)}',
                icon: Icons.refresh,
                color: Colors.orange,
              ),
              _SummaryCard(
                label: 'Hot Reactons',
                value:
                    '${_data.where((d) => d.recomputeCount > 10).length}',
                icon: Icons.local_fire_department,
                color: Colors.red,
              ),
              _SummaryCard(
                label: 'Avg Propagation',
                value: _data.isEmpty
                    ? '0us'
                    : '${(_data.fold<int>(0, (s, d) => s + d.avgPropagationMicros) / _data.length).round()}us',
                icon: Icons.speed,
                color: Colors.green,
              ),
            ],
          ),
        ),

        // Table header
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('Reacton',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(
                  flex: 1,
                  child: Text('Type',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(
                  flex: 1,
                  child: Text('Recomputes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(
                  flex: 1,
                  child: Text('Avg Time',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(
                  flex: 1,
                  child: Text('Subs',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),

        // Data rows
        Expanded(
          child: data.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No performance data collected yet.'),
                      const Text(
                        'Interact with your app to see metrics.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (ctx, i) => _PerfRow(data: data[i]),
                ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfRow extends StatelessWidget {
  final PerformanceEntry data;

  const _PerfRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isHot = data.recomputeCount > 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHot ? Colors.red.withValues(alpha: 0.05) : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isHot)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.local_fire_department,
                        size: 14, color: Colors.red),
                  ),
                Expanded(
                  child: Text(
                    data.name,
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(data.type, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${data.recomputeCount}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHot ? FontWeight.bold : FontWeight.normal,
                color: isHot ? Colors.red : null,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${data.avgPropagationMicros}us',
              style:
                  const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${data.subscriberCount}',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
