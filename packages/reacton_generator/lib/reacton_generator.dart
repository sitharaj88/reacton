/// Code generation for Reacton state management.
///
/// Provides build_runner builders for:
/// - Auto-generating serializers for `@ReactonSerializable` types
/// - Static dependency graph analysis
/// - Dead reacton detection
///
/// ## Setup
///
/// Add to your `pubspec.yaml`:
/// ```yaml
/// dev_dependencies:
///   reacton_generator: ^0.1.0
///   build_runner: ^2.4.0
/// ```
///
/// Then run:
/// ```bash
/// dart run build_runner build
/// ```
library reacton_generator;

export 'src/annotations/reacton_annotations.dart';
export 'src/builders/graph_analyzer.dart';
export 'src/builders/serializer_builder.dart';
export 'src/builders/reacton_collector.dart';
