import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show reporter, TaskProcess;

import 'package:dart_dev/src/tasks/task.dart';

Future<TaskRunner> runTasks({List<String> tasksToRun}) async {
  var taskGroup = new TaskGroup(tasksToRun);
  await taskGroup.startTaskGroup();
  taskGroup.taskGroupOutput();

  TaskRunner task = new TaskRunner(await taskGroup.checkExitCodes(),
      taskGroup.taskGroupStdout, taskGroup.taskGroupStderr);
  return task;
}

class TaskRunner extends Task {
  final Future done = new Future.value();
  final String stdout;
  final String stderr;
  bool successful;

  TaskRunner(int exitCode, String this.stdout, String this.stderr) {
    exitCode == 0 ? this.successful = true : this.successful = false;
  }
}

class SubTask {
  /// Process to be executed
  String command;

  /// A string consisting of all the subtask's output
  String taskOutput = '';

  /// Any output created in the subtask's stderr
  String taskError = '';

  TaskProcess taskProcess;

  SubTask(String task) {
    command = task;
  }

  /// Starts the provided subtask and wires up a stream to allow
  /// the TaskGroup to listen for subtask completion.
  startProcess() {
    var taskArguments = command.split(' ');
    taskProcess =
        new TaskProcess(taskArguments.first, taskArguments.sublist(1));
    taskProcess.stdout.listen((line) {
      this.taskOutput += '\n$line';
    });
    taskProcess.stderr.listen((line) {
      this.taskOutput += '\n$line';
      this.taskError += '\n$line';
    });
  }
}

class TaskGroup {
  /// List of the individual subtasks executed
  List<String> subTaskCommands = [];

  /// List of the subtasks making up the TaskGroup
  List<SubTask> subTasks = [];

  /// TaskGroup stdout
  String taskGroupStdout = '';

  /// TaskGroup stderr
  String taskGroupStderr = '';

  TaskGroup(List<String> this.subTaskCommands) {
    for (String taskCommand in subTaskCommands) {
      SubTask task = new SubTask(taskCommand);
      subTasks.add(task);
    }
  }

  /// Begin each subtask and wait for completion
  startTaskGroup() async {
    List<Future> futures = [];
    var timer = new Timer.periodic(new Duration(seconds: 30), (_) {
      reporter.log('Tasks running...');
    });
    for (SubTask task in subTasks) {
      task.startProcess();
      futures.add(task.taskProcess.exitCode);
    }
    await Future.wait(futures);
    timer.cancel();
  }

  /// Retrieve output from subtasks
  taskGroupOutput() {
    String output = '';
    for (SubTask task in subTasks) {
      output += task.taskOutput + '\n';
    }
    this.taskGroupStdout = output;
  }

  /// Determine if subtasks completed successfully
  Future<int> checkExitCodes() async {
    for (SubTask task in subTasks) {
      if (await task.taskProcess.exitCode != 0) {
        exitCode = 1;
        this.taskGroupStderr +=
            'The command, ${task.command}, contained this in the stderr; \n${task.taskError}\n';
      }
    }
    if (exitCode != 0) {
      this.taskGroupStderr =
          'One of your subtasks exited with a non-zero exit code. '
          'See the output below for more information: \n${this.taskGroupStderr}';
    }
    return exitCode;
  }
}
