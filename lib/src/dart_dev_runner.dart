import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'dart_dev_tool.dart';
import 'events.dart' as events;
import 'utils/version.dart';

// import 'package:completion/completion.dart' as completion;

class DartDevRunner extends CommandRunner<int> {
  DartDevRunner(Map<String, DevTool> commands)
      : super('dart_dev', 'Dart tool runner.') {
    commands.forEach((name, builder) {
      final command = builder.toCommand(name);
      if (command.name != name) {
        throw CommandNameMismatch(command.name, name);
      }
      addCommand(command);
    });
    argParser
      ..addFlag('verbose',
          abbr: 'v', negatable: false, help: 'Enables verbose logging.')
      ..addFlag('version',
          negatable: false, help: 'Prints the dart_dev version.');
  }

  @override
  ArgResults parse(Iterable<String> args) {
    // TODO: get this completion working with bash/zsh
    // try {
    //   return completion.tryArgsCompletion(args, argParser);
    // } catch (_) {
    //   return super.parse(args);
    // }
    return super.parse(args);
  }

  @override
  Future<int> run(Iterable<String> args) async {
    final argResults = parse(args);
    if (argResults['version'] ?? false) {
      print(dartDevVersion);
      return 0;
    }
    // About the only mechanism I can find for communicating between the different levels of this
    // is that this runner holds an actual list of command instances, so we can associate the log
    // file path with that.
    print("commands = $commands");
    print("we're trying to execute ${argResults.name}");
    print("or is that ${argResults.command.name}");
    final command = commands[argResults.command.name];
    print(
        "We are trying to write a log at ${(command as DevToolCommand).logFilePath}");
    final stopwatch = Stopwatch()..start();

    print("running with ${args}");
    final exitCode = (await super.run(args)) ?? 0;
    stopwatch.stop();
    String log;
    if (command != null && command is DevToolCommand) {
      print("We expect to read a log at ${command.logFilePath}");
      log = await File(command.logFilePath).readAsString();
      print("Got ${log.length} bytes of log");
    }
    events.CommandResult result =
        events.CommandResult(args, exitCode, stopwatch.elapsed, log: log);
    await events.commandComplete(result);
    return result.exitCode;
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
