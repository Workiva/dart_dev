import 'dart:async';

import 'package:dart_dev/util.dart' show reporter, TaskProcess;

import 'package:dart_dev/src/tasks/task.dart';

Future<TaskRunner> runTasks(tasksToRun) async {
  var taskGroup = new TaskGroup(tasksToRun);
  await taskGroup.run();

  TaskRunner task = new TaskRunner(taskGroup.failedTask, taskGroup.successful,
      taskGroup.taskGroupStderr, taskGroup.tasksNotCompleted);
  return task;
}

class TaskRunner extends Task {
  final Future done = new Future.value();
  String failedTask;
  final String stderr;
  bool successful;
  List<String> tasksNotCompleted;

  TaskRunner(this.failedTask, bool this.successful, String this.stderr,
      List<String> this.tasksNotCompleted);
}

class SubTask {
  /// Process to be executed
  final String command;

  /// A string consisting of all the subtask's output
  String taskOutput = '';

  /// Any output created in the subtask's stderr
  String taskError = '';

  TaskProcess taskProcess;

  Completer<Null> _done = new Completer<Null>();

  SubTask(this.command);

  Future<Null> get done => _done.future;

  /// Starts the provided subtask and wires up a stream to allow
  /// the TaskGroup to listen for subtask completion.
  startProcess() {
    var taskArguments = command.split(' ');
    taskProcess =
        new TaskProcess(taskArguments.first, taskArguments.sublist(1));

    final stdoutc = new Completer<Null>();
    final stderrc = new Completer<Null>();
    taskProcess.stdout.listen((line) {
      this.taskOutput += '\n$line';
    }, onDone: () => stdoutc.complete());
    taskProcess.stderr.listen((line) {
      this.taskError += '\n$line';
    }, onDone: () => stderrc.complete());
    Future
        .wait([taskProcess.done, stdoutc.future, stderrc.future])
        .then((_) => _done.complete())
        .catchError((e) => _done.completeError(e));
  }
}

class TaskGroup {
  /// Failed task
  String failedTask = '';

  /// List of the individual subtasks executed
  List<String> subTaskCommands = <String>[];

  /// List of the subtasks making up the TaskGroup
  List<SubTask> subTasks = <SubTask>[];

  /// TaskGroup stderr
  String taskGroupStderr = '';

  /// Status of TaskGroup
  bool successful = true;

  /// Tasks cancelled prior to completion
  List<String> tasksNotCompleted = [];

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
      task.done.then((_) async {
        final exitCode = await task.taskProcess.exitCode;
        reporter.log(task.taskOutput);
        // if the task runner kills outstanding tasks it currently sets the exit code to -15
        if (exitCode != 0 && exitCode != -15) {
          failedTask = task.command;
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

    for (SubTask task in subTasks) {
      await task.done;
      if (await task.taskProcess.exitCode == -15) {
        tasksNotCompleted.add(task.command);
      }
    }
    timer.cancel();
  }
}
