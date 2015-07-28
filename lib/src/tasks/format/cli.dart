library dart_dev.src.tasks.format.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/io.dart' show reporter;

import 'package:dart_dev/src/tasks/format/api.dart';
import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class FormatCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addFlag('check',
        defaultsTo: defaultCheck,
        negatable: false,
        help:
            'Dry-run; checks if formatter needs to be run and sets exit code accordingly.');

  final String command = 'format';

  Future<CliResult> run(ArgResults parsedArgs) async {
    bool check = TaskCli.valueOf('check', parsedArgs, config.format.check);
    List<String> directories = config.format.directories;

    FormatTask task = format(check: check, directories: directories);
    reporter.logGroup(task.formatterCommand,
        outputStream: task.formatterOutput);
    await task.done;

    if (task.isDryRun) {
      if (task.successful) return new CliResult.success(
          'You\'re Dart code is good to go!');
      if (task.affectedFiles.isEmpty) return new CliResult.fail(
          'The Dart formatter needs to be run.');
      return new CliResult.fail(
          'The Dart formatter needs to be run. The following files require changes:\n    ' +
              task.affectedFiles.join('\n    '));
    } else {
      if (!task.successful) return new CliResult.fail('Dart formatter failed.');
      if (task.affectedFiles.isEmpty) return new CliResult.success(
          'Success! All files are already formatted correctly.');
      return new CliResult.success(
          'Success! The following files were formatted:\n    ' +
              task.affectedFiles.join('\n    '));
    }
  }
}
