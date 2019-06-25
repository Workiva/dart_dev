import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../utils/has_any_positional_args_before_separator.dart';

class DartFunctionCommand extends Command<int> {
  final DartFunctionConfig config;

  DartFunctionCommand([DartFunctionConfig config])
      : config = config ?? DartFunctionConfig() {
    if (config.commandName == null) {
      throw ArgumentError('config.commandName must not be null.');
    }
  }

  @override
  String get name => config.commandName;

  @override
  String get description => config.description ?? '';

  @override
  bool get hidden => config.hidden ?? true;

  @override
  Future<int> run() async {
    assertNoPositionalArgsBeforeSeparator(name, argResults, usageException);
    return config?.function() ?? ExitCode.software.code;
  }

  static void assertNoPositionalArgsBeforeSeparator(
    String name,
    ArgResults argResults,
    void usageException(String message),
  ) {
    if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
      usageException('The "$name" command does not support positional args.');
    }
  }
}

class DartFunctionConfig {
  DartFunctionConfig({
    this.commandName,
    this.description,
    this.function,
    this.hidden,
  });

  final String commandName;
  final String description;
  final FutureOr<int> Function() function;
  final bool hidden;
}
