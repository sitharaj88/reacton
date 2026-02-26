/// Flutter widgets and bindings for the Reacton state management library.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_reacton/flutter_reacton.dart';
///
/// // 1. Wrap your app
/// void main() => runApp(ReactonScope(child: MyApp()));
///
/// // 2. Create reactons
/// final counterReacton = reacton(0, name: 'counter');
///
/// // 3. Use in widgets
/// class CounterPage extends StatelessWidget {
///   Widget build(BuildContext context) {
///     final count = context.watch(counterReacton);
///     return Text('$count');
///   }
/// }
/// ```
library flutter_reacton;

// Re-export core reacton
export 'package:reacton/reacton.dart';

// Widgets
export 'src/widgets/reacton_scope.dart';
export 'src/widgets/reacton_builder.dart';
export 'src/widgets/reacton_consumer.dart';
export 'src/widgets/reacton_listener.dart';
export 'src/widgets/reacton_selector.dart';

// Extensions
export 'src/extensions/build_context_ext.dart';

// Lifecycle
export 'src/lifecycle/auto_dispose.dart';

// Form state management
export 'src/form/validators.dart';
export 'src/form/field_reacton.dart';
export 'src/form/form_reacton.dart';
