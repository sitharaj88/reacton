import 'package:args/command_runner.dart';
import 'package:reacton_cli/reacton_cli.dart';

void main(List<String> args) {
  final runner = CommandRunner<void>(
    'reacton',
    'Reacton CLI - State management tooling for Flutter',
  )
    ..addCommand(InitCommand())
    ..addCommand(CreateCommand())
    ..addCommand(GraphCommand())
    ..addCommand(DoctorCommand())
    ..addCommand(AnalyzeCommand());

  runner.run(args);
}
