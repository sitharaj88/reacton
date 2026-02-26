import 'dart:async';
import 'package:flutter/material.dart';
import '../services/reacton_service.dart';

/// Chronological timeline of all state changes.
///
/// Displays each mutation with reacton name, old/new values,
/// timestamp, and propagation time. Filterable by reacton name.
/// Polls the service extension for new entries every second.
class TimelineView extends StatefulWidget {
  final ReactonDevToolsService service;

  const TimelineView({super.key, required this.service});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final List<TimelineEntryData> _entries = [];
  String _filter = '';
  bool _paused = false;
  bool _loading = false;
  String? _error;
  Timer? _pollTimer;
  int _fetchedCount = 0;

  List<TimelineEntryData> get _filteredEntries {
    if (_filter.isEmpty) return _entries;
    return _entries
        .where(
            (e) => e.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTimeline();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) {
        _loadTimeline(incremental: true);
      }
    });
  }

  Future<void> _loadTimeline({bool incremental = false}) async {
    if (_loading) return;
    _loading = true;

    try {
      final data = await widget.service.getTimeline(
        since: incremental ? _fetchedCount : 0,
      );

      if (!mounted) return;

      setState(() {
        if (!incremental) {
          _entries.clear();
          _fetchedCount = 0;
        }
        _entries.addAll(data.entries);
        _fetchedCount = data.total;
        _paused = data.paused;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> _clearTimeline() async {
    try {
      await widget.service.clearTimeline();
      setState(() {
        _entries.clear();
        _fetchedCount = 0;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _togglePause() async {
    final newPaused = !_paused;
    try {
      await widget.service.clearTimeline(pause: newPaused);
      setState(() => _paused = newPaused);
      // Don't clear entries, just toggle pause state
      if (!newPaused) {
        // Reload to catch any entries that came in
        _loadTimeline();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Text(
                'State Timeline',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Filter by reacton name...',
                    prefixIcon: Icon(Icons.filter_list, size: 18),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 18),
                onPressed: _togglePause,
                tooltip: _paused ? 'Resume' : 'Pause',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: _clearTimeline,
                tooltip: 'Clear',
              ),
              Text('${entries.length} events'),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
        const Divider(height: 1),

        // Timeline list
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timeline,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No state changes recorded yet.'),
                      const Text(
                        'Interact with your app to see changes here.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: entries.length,
                  reverse: true, // newest first
                  itemBuilder: (ctx, i) => _TimelineEntryTile(
                      entry: entries[entries.length - 1 - i]),
                ),
        ),
      ],
    );
  }
}

class _TimelineEntryTile extends StatelessWidget {
  final TimelineEntryData entry;

  const _TimelineEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (entry.type) {
      'writable' => Colors.blue,
      'computed' => Colors.green,
      'async' => Colors.orange,
      'effect' => Colors.red,
      _ => Colors.grey,
    };

    final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}.'
        '${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 100,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Reacton indicator
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
            ),
          ),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.oldValue,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          fontFamily: 'monospace',
                          decoration: TextDecoration.lineThrough,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 12),
                    ),
                    Flexible(
                      child: Text(
                        entry.newValue,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Propagation time
          Text(
            '${entry.propagationMicros}us',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
