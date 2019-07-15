import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../command_builder.dart';
import '../utils/has_any_positional_args_before_separator.dart';

class DartFunctionCommand implements CommandBuilder {
  DartFunctionCommand(FutureOr<int> Function() function) : _function = function;

  @override
  String description;

  @override
  bool hidden;
  
  final FutureOr<int> Function() _function;

  @override
  Command<int> build(String commandName) => _DartFunctionCommand(
    commandName,
    description,
    _function,
    hidden,
  );
}

class _DartFunctionCommand extends Command<int> {
  final String _commandName;
  final String _description;
  final FutureOr<int> Function() _function;
  final bool _hidden;

  _DartFunctionCommand(
    this._commandName,
    this._description,
    this._function,
    this._hidden,
  );

  @override
  String get name => _commandName;

  @override
  String get description => _description;

  @override
  bool get hidden => _hidden ?? false;

  @override
  Future<int> run() async {
    assertNoPositionalArgsBeforeSeparator(name, argResults, usageException);
    return (await _function()) ?? ExitCode.software.code;
  }
}

void assertNoPositionalArgsBeforeSeparator(
  String name,
  ArgResults argResults,
  void usageException(String message),
) {
  if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
    usageException('The "$name" command does not support positional args.');
  }
}
