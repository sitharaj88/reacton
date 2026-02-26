import 'package:flutter/material.dart';
import '../services/reacton_service.dart';

/// Reacton inspector view for DevTools.
///
/// Shows a table of all reactons with their current values, types,
/// subscriber counts, and allows live value editing.
class ReactonInspector extends StatefulWidget {
  final ReactonDevToolsService service;

  const ReactonInspector({super.key, required this.service});

  @override
  State<ReactonInspector> createState() => _ReactonInspectorState();
}

class _ReactonInspectorState extends State<ReactonInspector> {
  List<ReactonListEntry>? _reactons;
  bool _loading = true;
  String? _error;
  String _filter = '';
  _SortColumn _sortColumn = _SortColumn.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadReactons();
  }

  Future<void> _loadReactons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reactons = await widget.service.getReactonList();
      setState(() {
        _reactons = reactons;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ReactonListEntry> get _filteredReactons {
    var reactons = _reactons ?? [];
    if (_filter.isNotEmpty) {
      reactons = reactons
          .where((a) => a.name.toLowerCase().contains(_filter.toLowerCase()))
          .toList();
    }

    reactons.sort((a, b) {
      final cmp = switch (_sortColumn) {
        _SortColumn.name => a.name.compareTo(b.name),
        _SortColumn.type => a.type.compareTo(b.type),
        _SortColumn.value => a.value.compareTo(b.value),
        _SortColumn.subscribers => a.subscribers.compareTo(b.subscribers),
      };
      return _sortAscending ? cmp : -cmp;
    });

    return reactons;
  }

  void _onSort(_SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    final reactons = _filteredReactons;

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Text(
                'Reacton Inspector',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Filter reactons...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              const SizedBox(width: 8),
              Text('${reactons.length} reactons'),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loadReactons,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Table header
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _SortableHeader('Name', _SortColumn.name, _sortColumn,
                  _sortAscending, _onSort,
                  flex: 3),
              _SortableHeader('Type', _SortColumn.type, _sortColumn,
                  _sortAscending, _onSort,
                  flex: 1),
              _SortableHeader('Value', _SortColumn.value, _sortColumn,
                  _sortAscending, _onSort,
                  flex: 3),
              _SortableHeader('Subs', _SortColumn.subscribers, _sortColumn,
                  _sortAscending, _onSort,
                  flex: 1),
            ],
          ),
        ),

        // Reacton rows
        Expanded(
          child: reactons.isEmpty
              ? const Center(child: Text('No reactons found'))
              : ListView.builder(
                  itemCount: reactons.length,
                  itemBuilder: (ctx, i) => _ReactonRow(entry: reactons[i]),
                ),
        ),
      ],
    );
  }
}

enum _SortColumn { name, type, value, subscribers }

class _SortableHeader extends StatelessWidget {
  final String label;
  final _SortColumn column;
  final _SortColumn currentSort;
  final bool ascending;
  final void Function(_SortColumn) onSort;
  final int flex;

  const _SortableHeader(
    this.label,
    this.column,
    this.currentSort,
    this.ascending,
    this.onSort, {
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (isActive)
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReactonRow extends StatelessWidget {
  final ReactonListEntry entry;

  const _ReactonRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (entry.type) {
      'writable' => Colors.blue,
      'computed' => Colors.green,
      'async' => Colors.orange,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.name,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              entry.type,
              style: TextStyle(fontSize: 11, color: typeColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.value,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${entry.subscribers}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
