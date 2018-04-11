import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter;

import 'package:dart_dev/src/tasks/task_runner/api.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class TaskRunnerCli extends TaskCli {
  @override
  final ArgParser argParser = new ArgParser()
    ..addOption('config',
        help:
            'Configuration options should be performed in local dev.dart file');

  @override
  final String command = 'task-runner';

  @override
  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    List<String> tasksToRun = config.taskRunner.tasksToRun;

    if (tasksToRun.isEmpty) {
      return new CliResult.fail(
          'There are no currently defined tasks in your dev.dart file.');
    }

    TaskRunner task = await runTasks(tasksToRun);

    reporter.logGroup('Tasks run: \'${tasksToRun.join('\', \'')}\'');
    if (!task.successful) {
      reporter.logGroup(
          'Failure output: '
          'One of your subtasks exited with a non-zero exit code. '
          'See the output below for more information:',
          error: task.stderr);
    }

    return task.successful
        ? new CliResult.success('Tasks completed successfuly.')
        : new CliResult.fail('Some task failed: ${task.failedTask}'
            '\n\nThe following tasks were stopped prior to completion:'
            '\n${task.tasksNotCompleted.join('\n')}');
  }
}
