import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import '../../shared/state.dart';

// ============================================================================
// Time Travel Page
//
// Demonstrates:
//   - store.enableHistory()   attach an undo/redo history to a reacton
//   - history.undo()          step backward in history
//   - history.redo()          step forward in history
//   - history.jumpTo()        jump to an arbitrary point
//   - history.canUndo/canRedo enable/disable buttons
//   - history.entries         full timeline with timestamps
//   - store.snapshot()        capture entire store state
//   - store.restore()         restore from a snapshot
// ============================================================================

class TimeTravelPage extends StatefulWidget {
  const TimeTravelPage({super.key});

  @override
  State<TimeTravelPage> createState() => _TimeTravelPageState();
}

class _TimeTravelPageState extends State<TimeTravelPage> {
  History<int>? _history;
  StoreSnapshot? _savedSnapshot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Enable history tracking on first build.
    // enableHistory returns a History controller with undo/redo capabilities.
    _history ??= context.reactonStore.enableHistory(
      timeTravelCounterReacton,
      maxHistory: 50,
    );
  }

  @override
  void dispose() {
    _history?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Watch the value so this widget rebuilds on changes
    final value = context.watch(timeTravelCounterReacton);

    final history = _history;
    if (history == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Travel'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Text(
              'History & Snapshots',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'enableHistory() wraps a reacton with an undo/redo timeline. '
              'snapshot() captures the entire store; restore() rewinds to it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // --- Counter display ---
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$value',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step ${history.currentIndex + 1} of ${history.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Mutation buttons ---
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.update(
                      timeTravelCounterReacton,
                      (c) => c + 1,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('+1'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.update(
                      timeTravelCounterReacton,
                      (c) => c + 5,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('+5'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.update(
                      timeTravelCounterReacton,
                      (c) => c - 1,
                    ),
                    icon: const Icon(Icons.remove),
                    label: const Text('-1'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.set(timeTravelCounterReacton, 0),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset to 0'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Undo / Redo controls ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Undo / Redo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: history.canUndo
                              ? () {
                                  history.undo();
                                  setState(() {});
                                }
                              : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.tonalIcon(
                          onPressed: history.canRedo
                              ? () {
                                  history.redo();
                                  setState(() {});
                                }
                              : null,
                          icon: const Icon(Icons.redo),
                          label: const Text('Redo'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: history.length > 1
                              ? () {
                                  history.jumpTo(0);
                                  setState(() {});
                                }
                              : null,
                          child: const Text('Jump to Start'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Snapshot controls ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Snapshots',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'snapshot() captures the entire store state. '
                      'restore() applies a snapshot, reverting all reactons.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            _savedSnapshot = context.reactonStore.snapshot();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Snapshot saved!'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Save Snapshot'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _savedSnapshot != null
                              ? () {
                                  context.reactonStore
                                      .restore(_savedSnapshot!);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Snapshot restored!'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore Snapshot'),
                        ),
                      ],
                    ),
                    if (_savedSnapshot != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Snapshot taken at ${_formatTime(_savedSnapshot!.timestamp)} '
                          '(${_savedSnapshot!.size} reactons)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- History timeline ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'History Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (history.entries.isEmpty)
                      Text(
                        'No history yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      ...List.generate(history.entries.length, (index) {
                        final entry = history.entries[index];
                        final isCurrent = index == history.currentIndex;

                        return InkWell(
                          onTap: () {
                            history.jumpTo(index);
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrent
                                        ? colors.primary
                                        : colors.surfaceContainerHigh,
                                    border: Border.all(
                                      color: isCurrent
                                          ? colors.primary
                                          : colors.outlineVariant,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: isCurrent
                                            ? colors.onPrimary
                                            : colors.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Value: ${entry.value}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrent
                                        ? colors.primary
                                        : colors.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTime(entry.timestamp),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
