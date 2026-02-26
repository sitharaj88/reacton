import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import 'app.dart';

// ============================================================================
// Reacton Showcase
//
// A comprehensive demo application that exercises every feature of the
// Reacton state management library:
//
//   - reacton(), computed(), selector(), family()
//   - stateMachine() with guard conditions
//   - Observable collections (reactonList, reactonMap)
//   - Bidirectional lenses
//   - Time-travel (undo / redo / history)
//   - State branching (copy-on-write overlays)
//   - Form state management (fields, validators, submission)
//   - ReactonScope, ReactonBuilder, ReactonConsumer, ReactonListener
//   - context.watch(), context.read(), context.set(), context.update()
//   - batch() for atomic updates
//   - store.snapshot() and store.restore()
// ============================================================================

void main() {
  // ReactonScope provides a ReactonStore to the entire widget tree.
  // All reacton definitions are lazily initialised on first access.
  runApp(
    ReactonScope(
      child: const ShowcaseApp(),
    ),
  );
}
