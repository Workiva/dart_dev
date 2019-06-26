import 'dart:async';

import 'package:args/command_runner.dart';

class SequenceCommand extends Command<int> {
  final SequenceConfig config;

  SequenceCommand([SequenceConfig config])
      : config = config ?? SequenceConfig() {
    if (config.commandName == null) {
      throw ArgumentError('config.commandName must not be null.');
    }
    if (config.primaryCommands == null || config.primaryCommands.isEmpty) {
      throw ArgumentError(
          'config.primaryCommands must be non-null and non-empty.');
    }
  }

  @override
  String get name => config.commandName;

  @override
  String get description => config.description ?? '';

  @override
  bool get hidden => config.hidden ?? false;

  @override
  void printUsage() {
    if (config?.helpCommand != null && config.helpCommand.isNotEmpty) {
      runner.run(config.helpCommand);
    } else {
      super.printUsage();
    }
  }

  @override
  Future<int> run() async {
    int code;
    for (final args in config.beforeCommands ?? []) {
      code = await runner.run(args);
      if (code != 0) {
        return code;
      }
    }
    for (final args in config.primaryCommands ?? []) {
      code = await runner.run([...args, ...argResults.rest]);
      if (code != 0) {
        return code;
      }
    }
    if (code != 0) {
      return code;
    }
    for (final args in config.afterCommands ?? []) {
      code = await runner.run(args);
      if (code != 0) {
        return code;
      }
    }
    return code;
  }
}

class SequenceConfig {
  SequenceConfig({
    this.afterCommands,
    this.beforeCommands,
    this.commandName,
    this.description,
    this.helpCommand,
    this.hidden,
    this.primaryCommands,
  });

  final List<List<String>> afterCommands;
  final List<List<String>> beforeCommands;
  final String commandName;
  final String description;
  final List<String> helpCommand;
  final bool hidden;
  final List<List<String>> primaryCommands;
}
