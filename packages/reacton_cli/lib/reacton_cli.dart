/// CLI tool for Reacton state management.
///
/// Commands:
/// - `reacton init` - Add Reacton to an existing Flutter project
/// - `reacton create reacton|computed|async|selector|family <name>` - Scaffold reactons
/// - `reacton create feature <name>` - Generate a feature module with reactons, widget & test
/// - `reacton graph` - Print the dependency graph (text or DOT format)
/// - `reacton doctor` - Diagnose common configuration issues
/// - `reacton analyze` - Analyze reactons for issues (dead reactons, cycles, complexity)
library reacton_cli;

export 'src/commands/init_command.dart';
export 'src/commands/create_command.dart';
export 'src/commands/graph_command.dart';
export 'src/commands/doctor_command.dart';
export 'src/commands/analyze_command.dart';
export 'src/templates/reacton_template.dart';
export 'src/templates/feature_template.dart';
export 'src/templates/project_template.dart';
