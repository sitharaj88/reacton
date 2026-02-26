import 'dart:io';
import 'package:args/command_runner.dart';

import '../templates/project_template.dart';

/// Command: reacton init
///
/// Adds Reacton dependencies to an existing Flutter project and scaffolds
/// starter files.
class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description => 'Add Reacton to your Flutter project';

  InitCommand() {
    argParser.addFlag(
      'example',
      defaultsTo: true,
      help: 'Create a starter counter reacton and wrap main.dart with ReactonScope',
    );
  }

  @override
  Future<void> run() async {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      stderr.writeln('Error: No pubspec.yaml found in current directory.');
      stderr.writeln('Run this command from the root of a Flutter project.');
      return;
    }

    final withExample = argResults!['example'] as bool;

    stdout.writeln('Adding Reacton to your project...');
    stdout.writeln('');

    var content = pubspecFile.readAsStringSync();

    if (content.contains('flutter_reacton:') || content.contains('reacton:')) {
      stdout.writeln('Reacton is already configured in this project.');
      return;
    }

    // -----------------------------------------------------------------------
    // 1. Add dependencies to pubspec.yaml
    // -----------------------------------------------------------------------
    content = _addDependency(content, 'dependencies', 'flutter_reacton', '^0.1.0');
    content = _addDevDependency(content, 'dev_dependencies', 'reacton_test', '^0.1.0');
    content = _addDevDependency(content, 'dev_dependencies', 'reacton_lint', '^0.1.0');

    pubspecFile.writeAsStringSync(content);
    stdout.writeln('  [+] Added flutter_reacton to dependencies');
    stdout.writeln('  [+] Added reacton_test to dev_dependencies');
    stdout.writeln('  [+] Added reacton_lint to dev_dependencies');

    // -----------------------------------------------------------------------
    // 2. Create lib/reactons/ directory
    // -----------------------------------------------------------------------
    final reactonsDir = Directory('lib/reactons');
    if (!reactonsDir.existsSync()) {
      reactonsDir.createSync(recursive: true);
      stdout.writeln('  [+] Created lib/reactons/ directory');
    }

    // -----------------------------------------------------------------------
    // 3. Scaffold starter files if --example
    // -----------------------------------------------------------------------
    if (withExample) {
      final counterFile = File('lib/reactons/counter_reacton.dart');
      if (!counterFile.existsSync()) {
        counterFile.writeAsStringSync(counterReactonTemplate);
        stdout.writeln('  [+] Created lib/reactons/counter_reacton.dart');
      }
    }

    // -----------------------------------------------------------------------
    // 4. Set up analysis_options.yaml for reacton_lint
    // -----------------------------------------------------------------------
    final analysisFile = File('analysis_options.yaml');
    if (analysisFile.existsSync()) {
      var analysisContent = analysisFile.readAsStringSync();
      if (!analysisContent.contains('custom_lint')) {
        // Append custom_lint plugin config
        analysisContent += '''

# Reacton lint rules
analyzer:
  plugins:
    - custom_lint
''';
        analysisFile.writeAsStringSync(analysisContent);
        stdout.writeln('  [+] Added custom_lint to analysis_options.yaml');
      }
    }

    stdout.writeln('');
    stdout.writeln('Reacton initialized successfully!');
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln('  1. Run: flutter pub get');
    stdout.writeln('  2. Wrap your app with ReactonScope:');
    stdout.writeln('');
    stdout.writeln('     ReactonScope(');
    stdout.writeln('       child: MaterialApp(...),');
    stdout.writeln('     )');
    stdout.writeln('');
    stdout.writeln('  3. Create reactons in lib/reactons/');
    stdout.writeln('  4. Use context.watch(myReacton) in widgets');
    stdout.writeln('');
    if (withExample) {
      stdout.writeln('A starter counterReacton has been created at lib/reactons/counter_reacton.dart');
    }
  }

  /// Insert a dependency under `dependencies:` in pubspec.yaml.
  String _addDependency(String pubspec, String section, String pkg, String version) {
    return _insertUnderSection(pubspec, section, '  $pkg: $version');
  }

  /// Insert a dev dependency under `dev_dependencies:` in pubspec.yaml.
  String _addDevDependency(String pubspec, String section, String pkg, String version) {
    return _insertUnderSection(pubspec, section, '  $pkg: $version');
  }

  /// Inserts a line under a YAML section. Creates the section if missing.
  String _insertUnderSection(String pubspec, String section, String line) {
    final sectionPattern = RegExp('^$section:\\s*\$', multiLine: true);
    final match = sectionPattern.firstMatch(pubspec);

    if (match != null) {
      // Section exists — insert after it
      final insertPos = match.end;
      return '${pubspec.substring(0, insertPos)}\n$line${pubspec.substring(insertPos)}';
    } else {
      // Section doesn't exist — append it
      return '$pubspec\n$section:\n$line\n';
    }
  }
}
