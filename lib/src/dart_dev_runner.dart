import 'package:args/command_runner.dart';
import 'command_builder.dart';

class DartDevRunner extends CommandRunner<int> {
  DartDevRunner(Map<String, CommandBuilder> commands)
      : super('dart_dev', 'Dart tool runner.') {
    commands.forEach((name, builder) {
      final command = builder.build(name);
      if (command.name != name) {
        throw new CommandNameMismatch(command.name, name);
      }
      addCommand(command);
    });
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enables verbose logging.');
  }

  @override
  Future<int> run(Iterable<String> args) async {
    return (await super.run(args)) ?? 0;
  }
}

class CommandNameMismatch implements Exception {
  final String actual;
  final String expected;
  CommandNameMismatch(this.actual, this.expected);

  @override
  String toString() => 'CommandNameMismatch: '
      'Expected a "$expected" command but got one named "$actual".';
}
