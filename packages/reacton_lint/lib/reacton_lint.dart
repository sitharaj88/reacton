import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/avoid_reacton_in_build.dart';
import 'src/rules/avoid_read_in_build.dart';
import 'src/rules/prefer_computed.dart';

/// Entry point for the custom_lint plugin.
PluginBase createPlugin() => _ReactonLintPlugin();

class _ReactonLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidReactonInBuild(),
        AvoidReadInBuild(),
        PreferComputed(),
      ];
}
