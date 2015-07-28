library dart_dev.src.tasks.cli;

import 'dart:async';

import 'package:args/args.dart';

class CliResult {
  final String message;
  final bool successful;
  CliResult.success([String this.message = '']) : successful = true;
  CliResult.fail([String this.message = '']) : successful = false;
}

abstract class TaskCli {
  static valueOf(String arg, ArgResults parsedArgs, dynamic fallback) =>
      parsedArgs.wasParsed(arg) ? parsedArgs[arg] : fallback;

  ArgParser get argParser;
  String get command;

  Future<CliResult> run(ArgResults parsedArgs);
}
