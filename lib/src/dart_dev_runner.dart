import 'package:args/command_runner.dart';

class DartDevRunner extends CommandRunner<int> {
  DartDevRunner(Iterable<Command<int>> commands)
      : super('dart_dev', 'Dart tool runner.') {
    commands.forEach(addCommand);
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enables verbose logging.');
  }

  @override
  Future<int> run(Iterable<String> args) async {
    return (await super.run(args)) ?? 0;
  }
}
