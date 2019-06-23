import 'package:args/command_runner.dart';

import 'package:dart_dev/src/dart_dev_tool.dart';

class DartDevRunner extends CommandRunner<int> {
  DartDevRunner(Iterable<DartDevTool> tools)
      : super('dart_dev', 'Dart tool runner.') {
    // Add each tool's command in alphabetical order.
    final sortedCommands = tools.map((t) => t.command).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    sortedCommands.forEach(addCommand);

    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Enables verbose logging.');
  }

  @override
  Future<int> run(Iterable<String> args) async {
    return (await super.run(args)) ?? 0;
  }
}
