import 'dart:io';
import 'package:args/command_runner.dart';

import '../templates/reacton_template.dart';
import '../templates/feature_template.dart';

/// Command: `reacton create reacton|computed|async|selector|family|feature <name>`
///
/// Scaffolds files from templates.
class CreateCommand extends Command<void> {
  @override
  String get name => 'create';

  @override
  String get description => 'Create reactons and features from templates';

  CreateCommand() {
    addSubcommand(_CreateReactonSubcommand());
    addSubcommand(_CreateComputedSubcommand());
    addSubcommand(_CreateAsyncSubcommand());
    addSubcommand(_CreateSelectorSubcommand());
    addSubcommand(_CreateFamilySubcommand());
    addSubcommand(_CreateFeatureSubcommand());
  }
}

// ---------------------------------------------------------------------------
// Subcommands
// ---------------------------------------------------------------------------

class _CreateReactonSubcommand extends Command<void> {
  @override
  String get name => 'reacton';

  @override
  String get description => 'Create a writable reacton file';

  _CreateReactonSubcommand() {
    argParser
      ..addOption('type', abbr: 't', defaultsTo: 'String', help: 'Dart type')
      ..addOption('default', abbr: 'd', defaultsTo: "''", help: 'Default value')
      ..addOption('dir', defaultsTo: 'lib/reactons', help: 'Output directory');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: reacton create reacton <name> [--type String] [--default \'\']');
      return;
    }

    final rawName = argResults!.rest.first;
    final snakeName = _toSnakeCase(rawName);
    final camelName = _toCamelCase(rawName);
    final dartType = argResults!['type'] as String;
    final defaultValue = argResults!['default'] as String;
    final dir = argResults!['dir'] as String;

    final content = reactonTemplate
        .replaceAll('{{name}}', camelName)
        .replaceAll('{{snakeName}}', snakeName)
        .replaceAll('{{type}}', dartType)
        .replaceAll('{{defaultValue}}', defaultValue)
        .replaceAll('{{description}}', '$rawName state');

    _writeFile('$dir/${snakeName}_reacton.dart', content);
  }
}

class _CreateComputedSubcommand extends Command<void> {
  @override
  String get name => 'computed';

  @override
  String get description => 'Create a computed reacton file';

  _CreateComputedSubcommand() {
    argParser
      ..addOption('type', abbr: 't', defaultsTo: 'String', help: 'Dart type')
      ..addOption('dir', defaultsTo: 'lib/reactons', help: 'Output directory');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: reacton create computed <name> [--type String]');
      return;
    }

    final rawName = argResults!.rest.first;
    final snakeName = _toSnakeCase(rawName);
    final camelName = _toCamelCase(rawName);
    final dartType = argResults!['type'] as String;
    final dir = argResults!['dir'] as String;

    final content = computedReactonTemplate
        .replaceAll('{{name}}', camelName)
        .replaceAll('{{snakeName}}', snakeName)
        .replaceAll('{{type}}', dartType)
        .replaceAll('{{imports}}', '')
        .replaceAll('{{body}}', '// TODO: Compute derived value\n    return read(sourceReacton);')
        .replaceAll('{{description}}', 'Computed $rawName');

    _writeFile('$dir/${snakeName}_reacton.dart', content);
  }
}

class _CreateAsyncSubcommand extends Command<void> {
  @override
  String get name => 'async';

  @override
  String get description => 'Create an async reacton file';

  _CreateAsyncSubcommand() {
    argParser
      ..addOption('type', abbr: 't', defaultsTo: 'String', help: 'Dart type')
      ..addOption('dir', defaultsTo: 'lib/reactons', help: 'Output directory');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: reacton create async <name> [--type String]');
      return;
    }

    final rawName = argResults!.rest.first;
    final snakeName = _toSnakeCase(rawName);
    final camelName = _toCamelCase(rawName);
    final dartType = argResults!['type'] as String;
    final dir = argResults!['dir'] as String;

    final content = asyncReactonTemplate
        .replaceAll('{{name}}', camelName)
        .replaceAll('{{snakeName}}', snakeName)
        .replaceAll('{{type}}', dartType)
        .replaceAll('{{body}}', "throw UnimplementedError('Implement $rawName fetch');")
        .replaceAll('{{description}}', 'Async $rawName');

    _writeFile('$dir/${snakeName}_reacton.dart', content);
  }
}

class _CreateSelectorSubcommand extends Command<void> {
  @override
  String get name => 'selector';

  @override
  String get description => 'Create a selector reacton file';

  _CreateSelectorSubcommand() {
    argParser
      ..addOption('type', abbr: 't', defaultsTo: 'String', help: 'Selected type')
      ..addOption('source-type', defaultsTo: 'String', help: 'Source reacton type')
      ..addOption('dir', defaultsTo: 'lib/reactons', help: 'Output directory');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: reacton create selector <name> [--type String] [--source-type String]');
      return;
    }

    final rawName = argResults!.rest.first;
    final snakeName = _toSnakeCase(rawName);
    final camelName = _toCamelCase(rawName);
    final dartType = argResults!['type'] as String;
    final sourceType = argResults!['source-type'] as String;
    final dir = argResults!['dir'] as String;

    final content = selectorReactonTemplate
        .replaceAll('{{name}}', camelName)
        .replaceAll('{{snakeName}}', snakeName)
        .replaceAll('{{type}}', dartType)
        .replaceAll('{{sourceType}}', sourceType)
        .replaceAll('{{sourceReacton}}', '/* sourceReacton */')
        .replaceAll('{{transform}}', 'value /* TODO: transform */')
        .replaceAll('{{imports}}', '')
        .replaceAll('{{description}}', 'Selector for $rawName');

    _writeFile('$dir/${snakeName}_selector.dart', content);
  }
}

class _CreateFamilySubcommand extends Command<void> {
  @override
  String get name => 'family';

  @override
  String get description => 'Create a reacton family file';

  _CreateFamilySubcommand() {
    argParser
      ..addOption('type', abbr: 't', defaultsTo: 'String', help: 'Reacton value type')
      ..addOption('param-type', defaultsTo: 'String', help: 'Family parameter type')
      ..addOption('default', abbr: 'd', defaultsTo: "''", help: 'Default value')
      ..addOption('dir', defaultsTo: 'lib/reactons', help: 'Output directory');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: reacton create family <name> [--type String] [--param-type String]');
      return;
    }

    final rawName = argResults!.rest.first;
    final snakeName = _toSnakeCase(rawName);
    final camelName = _toCamelCase(rawName);
    final dartType = argResults!['type'] as String;
    final paramType = argResults!['param-type'] as String;
    final defaultValue = argResults!['default'] as String;
    final dir = argResults!['dir'] as String;

    final content = familyReactonTemplate
        .replaceAll('{{name}}', camelName)
        .replaceAll('{{snakeName}}', snakeName)
        .replaceAll('{{type}}', dartType)
        .replaceAll('{{paramType}}', paramType)
        .replaceAll('{{defaultValue}}', defaultValue)
        .replaceAll('{{description}}', '$rawName reacton family');

    _writeFile('$dir/${snakeName}_family.dart', content);
  }
}

class _CreateFeatureSubcommand extends Command<void> {
  @override
  String get name => 'feature';

  @override
  String get description => 'Create a feature module with reactons, widget, and test';

  _CreateFeatureSubcommand() {
    argParser.addFlag('with-test', defaultsTo: true, help: 'Also generate a test file');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: reacton create feature <name>');
      return;
    }

    final featureName = argResults!.rest.first;
    final snakeName = _toSnakeCase(featureName);
    final camelName = _toCamelCase(featureName);
    final pascalName = _toPascalCase(featureName);
    final withTest = argResults!['with-test'] as bool;

    // Detect package name from pubspec
    final packageName = _detectPackageName();

    final reactonsContent = featureReactonsTemplate
        .replaceAll('{{name}}', featureName)
        .replaceAll('{{snakeName}}', snakeName)
        .replaceAll('{{camelName}}', camelName)
        .replaceAll('{{pascalName}}', pascalName);

    final widgetContent = featureWidgetTemplate
        .replaceAll('{{name}}', featureName)
        .replaceAll('{{snakeName}}', snakeName)
        .replaceAll('{{camelName}}', camelName)
        .replaceAll('{{pascalName}}', pascalName);

    final dir = 'lib/features/$snakeName';
    _writeFile('$dir/${snakeName}_reactons.dart', reactonsContent);
    _writeFile('$dir/${snakeName}_page.dart', widgetContent);

    if (withTest) {
      final testContent = featureTestTemplate
          .replaceAll('{{snakeName}}', snakeName)
          .replaceAll('{{camelName}}', camelName)
          .replaceAll('{{pascalName}}', pascalName)
          .replaceAll('{{package}}', packageName);

      _writeFile('test/features/${snakeName}_test.dart', testContent);
    }

    stdout.writeln('Created feature: $featureName');
    stdout.writeln('  $dir/${snakeName}_reactons.dart');
    stdout.writeln('  $dir/${snakeName}_page.dart');
    if (withTest) {
      stdout.writeln('  test/features/${snakeName}_test.dart');
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _writeFile(String path, String content) {
  final file = File(path);
  if (file.existsSync()) {
    stderr.writeln('File already exists: $path');
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  stdout.writeln('Created: $path');
}

String _detectPackageName() {
  final pubspec = File('pubspec.yaml');
  if (pubspec.existsSync()) {
    final nameMatch = RegExp(r'^name:\s+(\S+)', multiLine: true)
        .firstMatch(pubspec.readAsStringSync());
    if (nameMatch != null) return nameMatch.group(1)!;
  }
  return 'my_app';
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp(r'^_'), '');
}

String _toCamelCase(String input) {
  final parts = input.split(RegExp(r'[_\s-]'));
  return parts.first.toLowerCase() +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

String _toPascalCase(String input) {
  final parts = input.split(RegExp(r'[_\s-]'));
  return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
}
