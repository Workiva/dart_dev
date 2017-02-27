import 'dart:async';

import 'package:dart_dev/util.dart' show reporter, TaskProcess;

import 'package:dart_dev/src/tasks/task.dart';

Future<TaskRunner> runTasks(tasksToRun) async {
  var taskGroup = new TaskGroup(tasksToRun);
  await taskGroup.run();

  TaskRunner task =
      new TaskRunner(taskGroup.successful, taskGroup.taskGroupStderr);
  return task;
}

class TaskRunner extends Task {
  final Future done = new Future.value();
  final String stderr;
  bool successful;

  TaskRunner(bool this.successful, String this.stderr);
}

class SubTask {
  /// Process to be executed
  final String command;

  /// A string consisting of all the subtask's output
  String taskOutput = '';

  /// Any output created in the subtask's stderr
  String taskError = '';

  TaskProcess taskProcess;

  SubTask(this.command);

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
      this.taskError += '\n$line';
    });
  }
}

class TaskGroup {
  /// List of the individual subtasks executed
  List<String> subTaskCommands = <String>[];

  /// List of the subtasks making up the TaskGroup
  List<SubTask> subTasks = <SubTask>[];

  /// TaskGroup stderr
  String taskGroupStderr = '';

  /// Status of TaskGroup
  bool successful = true;

  TaskGroup(this.subTaskCommands) {
    for (String taskCommand in subTaskCommands) {
      SubTask task = new SubTask(taskCommand);
      subTasks.add(task);
    }
  }

  /// Begin each subtask and wait for completion
  Future run() async {
    List<Future> futures = <Future>[];
    var timer = new Timer.periodic(new Duration(seconds: 30), (_) {
      reporter.log('Tasks running...');
    });
    for (SubTask task in subTasks) {
      task.startProcess();
      task.taskProcess.exitCode.then((int exitCode) {
        reporter.log(task.taskOutput);
        if (exitCode != 0) {
          successful = false;
          reporter.log(task.taskError);
          this.taskGroupStderr +=
              'The command, ${task.command}, contained this in the stderr; ${task.taskOutput}\n ${task.taskError}\n';
          for (SubTask task in subTasks) {
            task.taskProcess.kill();
          }
        }
      });
      futures.add(task.taskProcess.done);
    }
    await Future.wait(futures);

    timer.cancel();
  }
}
