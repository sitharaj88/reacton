/// Example usage of the reacton_cli tool.
///
/// The Reacton CLI is a command-line tool for scaffolding and analyzing
/// Reacton projects. Install and run it from your terminal:
///
/// ```shell
/// # Install globally
/// dart pub global activate reacton_cli
///
/// # Add Reacton to an existing Flutter project
/// reacton init
///
/// # Scaffold a writable reacton
/// reacton create reacton counter --type int --default 0
///
/// # Scaffold a computed reacton
/// reacton create computed fullName
///
/// # Scaffold a complete feature module (reacton + widget + test)
/// reacton create feature todo
///
/// # Print the dependency graph (text or DOT format)
/// reacton graph
/// reacton graph --format dot
///
/// # Diagnose configuration issues
/// reacton doctor
///
/// # Analyze reactons for dead code, cycles, and complexity
/// reacton analyze
/// ```
void main() {
  print('Reacton CLI - scaffolding and analysis tool');
  print('');
  print('Install:  dart pub global activate reacton_cli');
  print('');
  print('Commands:');
  print('  reacton init              Add Reacton to a Flutter project');
  print('  reacton create <type>     Scaffold reactons and features');
  print('  reacton graph             Print the dependency graph');
  print('  reacton doctor            Diagnose configuration issues');
  print('  reacton analyze           Analyze reactons for issues');
}
