import 'dart:io';
import 'package:args/command_runner.dart';

/// Command: reacton doctor
///
/// Diagnoses common Reacton configuration issues.
class DoctorCommand extends Command<void> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Diagnose common Reacton configuration issues';

  @override
  Future<void> run() async {
    stdout.writeln('Reacton Doctor');
    stdout.writeln('${'=' * 40}');
    stdout.writeln('');

    var issues = 0;

    // Check pubspec.yaml
    final pubspec = File('pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      _check('pubspec.yaml exists', true);

      final hasReacton = content.contains('flutter_reacton:') || content.contains('reacton:');
      _check('Reacton dependency found', hasReacton);
      if (!hasReacton) issues++;

      final hasReactonTest = content.contains('reacton_test:');
      _check('reacton_test dev dependency', hasReactonTest);
      if (!hasReactonTest) issues++;
    } else {
      _check('pubspec.yaml exists', false);
      issues++;
    }

    // Check for ReactonScope in main.dart
    final mainFile = File('lib/main.dart');
    if (mainFile.existsSync()) {
      final content = mainFile.readAsStringSync();
      final hasScope = content.contains('ReactonScope');
      _check('ReactonScope in main.dart', hasScope);
      if (!hasScope) issues++;
    }

    // Check for reactons directory
    final reactonsDir = Directory('lib/reactons');
    _check('lib/reactons/ directory exists', reactonsDir.existsSync());

    // Check for test directory
    final testDir = Directory('test');
    _check('test/ directory exists', testDir.existsSync());

    stdout.writeln('');
    if (issues == 0) {
      stdout.writeln('No issues found! Your Reacton setup looks good.');
    } else {
      stdout.writeln('Found $issues issue(s). Fix them for optimal Reacton usage.');
    }
  }

  void _check(String label, bool passed) {
    final icon = passed ? '[OK]' : '[!!]';
    stdout.writeln('  $icon $label');
  }
}
