import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter;

import 'package:dart_dev/src/tasks/task_runner/api.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class TaskRunnerCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addOption('config',
        help:
            'Configuration options should be performed in local dev.dart file');

  final String command = 'task-runner';

  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    List<String> tasksToRun = config.taskRunner.tasksToRun;

    if (tasksToRun.isEmpty) {
      return new CliResult.fail(
          'There are no currently defined tasks in your dev.dart file.');
    }

    TaskRunner task = await runTasks(tasksToRun);

    reporter.logGroup('Tasks run: \'${tasksToRun.join('\', \'')}\'',
        output: task.stdout);
    if (!task.successful) {
      reporter.logGroup('Failure output:', error: task.stderr);
    }

    return task.successful
        ? new CliResult.success('Tasks completed successfuly.')
        : new CliResult.fail('Some task / tasks failed.');
  }
}
