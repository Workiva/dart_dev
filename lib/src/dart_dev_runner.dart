import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';

import 'dart_dev_tool.dart';
import 'events.dart' as events;
import 'tools/clean_tool.dart';
import 'utils/version.dart';

class DartDevRunner extends CommandRunner<int> {
  DartDevRunner(Map<String, DevTool> commands)
      : super('dart_dev', 'Dart tool runner.') {
    // For backwards-compatibility, only add the `clean` command if it doesn't
    // conflict with any configured command.
    if (!commands.containsKey('clean')) {
      // Construct a new commands map here, to work around a runtime typecheck
      // failure:
      // `type 'CleanTool' is not a subtype of type 'FormatTool' of 'value'`
      // As seen in this CI run:
      // https://github.com/Workiva/dart_dev/actions/runs/8161855516/job/22311519665?pr=426#step:8:295
      commands = <String, DevTool>{...commands, 'clean': CleanTool()};
    }

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
    final stopwatch = Stopwatch()..start();
    final exitCode = (await super.run(args)) ?? 0;
    stopwatch.stop();
    await events.commandComplete(
        events.CommandResult(args.toList(), exitCode, stopwatch.elapsed));
    return exitCode;
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
