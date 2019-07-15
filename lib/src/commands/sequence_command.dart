import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../command_builder.dart';

final _log = Logger('SequenceCommand');

class WrappedCommand implements CommandBuilder {
  WrappedCommand(this.innerCommand, {
    this.afterCommands,
    this.beforeCommands,
  });

  final List<CommandBuilder> afterCommands;

  final List<CommandBuilder> beforeCommands;

  @override
  String description;

  @override
  bool hidden;

  final CommandBuilder innerCommand;

  @override
  Command<int> build(String commandName) => _SequenceCommand(
    afterCommands ?? <CommandBuilder>[],
    beforeCommands ?? <CommandBuilder>[],
    commandName,
    description,
    hidden,
    innerCommand,
  );
}

class _SequenceCommand extends Command<int> {
  final List<CommandBuilder> _afterCommands;
  final List<CommandBuilder> _beforeCommands;
  final String _commandName;
  final String _description;
  final bool _hidden;
  final CommandBuilder _innerCommand;

  _SequenceCommand(
    this._afterCommands,
    this._beforeCommands,
    this._commandName,
    this._description,
    this._hidden,
    this._innerCommand,
  );
  //     : config = config ?? SequenceConfig() {
  //   if (config.commandName == null) {
  //     throw ArgumentError('config.commandName must not be null.');
  //   }
  //   if (config.primaryCommands == null || config.primaryCommands.isEmpty) {
  //     throw ArgumentError(
  //         'config.primaryCommands must be non-null and non-empty.');
  //   }
  // }

  @override
  String get name => _commandName;

  @override
  String get description => _description ?? '';

  @override
  bool get hidden => _hidden ?? false;

  String get _innerCommandName => '_$name';

  @override
  void printUsage() {
    runner.run([_innerCommandName, '-h']);
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
      final combinedArgs = <String>[...args, ...argResults.rest];
      _log.info('Running: dart_dev ${combinedArgs.join(' ')}\n');
      code = await runner.run(combinedArgs);
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

  void _addWrappedCommands() {
    if (runner.commands.containsKey(_innerCommandName)) {
      return;
    }

    final innerCommand = 

    for (var i = 0; i < _beforeCommands.length; i++) {
      final command = _beforeCommands[i].build('${_innerCommand}_before$i');
      runner.addCommand(command);
    }
    
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
