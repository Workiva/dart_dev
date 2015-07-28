library dart_dev.src.tasks.init.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/src/tasks/init/api.dart';
import 'package:dart_dev/src/tasks/cli.dart';

class InitCli extends TaskCli {
  final ArgParser argParser = new ArgParser();

  final String command = 'init';

  Future<CliResult> run(ArgResults parsedArgs) async {
    InitTask task = init();
    await task.done;
    return task.successful
        ? new CliResult.success('dart_dev config initialized: tool/dev.dart')
        : new CliResult.fail('dart_dev config already exists!');
  }
}
