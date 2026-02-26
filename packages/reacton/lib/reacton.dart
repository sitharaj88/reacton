/// Reacton - A novel reactive graph engine for Dart.
///
/// Fine-grained state management with reactons, computed values, effects,
/// state branching, time-travel debugging, and more.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:reacton/reacton.dart';
///
/// // Create reactons (Level 1)
/// final counterReacton = reacton(0, name: 'counter');
///
/// // Derive state (Level 2)
/// final doubleReacton = computed((read) => read(counterReacton) * 2);
///
/// // Use in a store
/// final store = ReactonStore();
/// print(store.get(counterReacton)); // 0
/// store.set(counterReacton, 5);
/// print(store.get(doubleReacton)); // 10
/// ```
library reacton;

// Core reacton primitives
export 'src/core/reacton_base.dart';
export 'src/core/writable_reacton.dart';
export 'src/core/readonly_reacton.dart';
export 'src/core/selector_reacton.dart';
export 'src/core/family_reacton.dart';
export 'src/core/state_machine_reacton.dart';
export 'src/core/state_machine_ext.dart';

// Reactive graph engine
export 'src/graph/reactive_graph.dart';
export 'src/graph/node.dart' show NodeState, GraphNode;
export 'src/graph/scheduler.dart';

// Store
export 'src/store/store.dart';
export 'src/store/store_snapshot.dart';

// Derived state and effects
export 'src/derived/effect.dart';

// Async
export 'src/async/async_value.dart';
export 'src/async/async_reacton.dart';
export 'src/async/retry.dart';
export 'src/async/debounce.dart';
export 'src/async/optimistic.dart';
export 'src/async/query_reacton.dart';

// Middleware
export 'src/middleware/middleware.dart';
export 'src/middleware/interceptor.dart';
export 'src/middleware/logging_middleware.dart';
export 'src/middleware/persistence_middleware.dart';
export 'src/middleware/devtools_middleware.dart';

// Persistence
export 'src/persistence/serializer.dart';
export 'src/persistence/storage_adapter.dart';

// State branching
export 'src/branching/branch.dart';

// Time travel
export 'src/history/history.dart';
export 'src/history/action_log.dart';

// Multi-isolate
export 'src/isolate/isolate_protocol.dart';
export 'src/isolate/isolate_store.dart';
export 'src/isolate/isolate_channel.dart';

// Observable collections
export 'src/collections/observable_list.dart';
export 'src/collections/observable_map.dart';

// Modules
export 'src/module/reacton_module.dart';

// Lenses (bidirectional optics)
export 'src/lens/lens.dart';

// Collaborative CRDT
export 'src/collab/crdt.dart';
export 'src/collab/collaborative_reacton.dart';

// Sagas (effect orchestrator)
export 'src/saga/saga.dart';
export 'src/saga/saga_runner.dart';

// Session recording & replay
export 'src/recording/session_recorder.dart';

// Utilities
export 'src/utils/disposable.dart';
