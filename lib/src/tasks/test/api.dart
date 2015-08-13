library dart_dev.src.tasks.test.api;

import 'dart:async';

import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/task.dart';

TestTask test(
    {List<String> platforms: const [], List<String> tests: const []}) {
  var executable = 'pub';
  var args = ['run', 'test'];
  platforms.forEach((p) {
    args.addAll(['-p', p]);
  });
  args.addAll(tests);
  args.addAll(['--reporter=expanded']);

  TaskProcess process = new TaskProcess(executable, args);
  Completer outputProcessed = new Completer();
  TestTask task = new TestTask('$executable ${args.join(' ')}',
      Future.wait([process.done, outputProcessed.future]));

  // TODO: Use this pattern to better parse the test summary even when the output is colorized
  // RegExp resultPattern = new RegExp(r'(\d+:\d+) \+(\d+) ?~?(\d+)? ?-?(\d+)?: (All|Some) tests (failed|passed)');

  StreamController stdoutc = new StreamController();
  process.stdout.listen((line) {
    stdoutc.add(line);
    if (line.contains('All tests passed!') ||
        line.contains('Some tests failed.')) {
      task.testSummary = line;
      outputProcessed.complete();
    }
  });

  stdoutc.stream.listen(task._testOutput.add);
  process.stderr.listen(task._testOutput.addError);
  process.exitCode.then((code) {
    if (task.successful == null) {
      task.successful = code <= 0;
    }
  });

  return task;
}

class TestTask extends Task {
  final Future done;
  final String testCommand;
  String testSummary;

  StreamController<String> _testOutput = new StreamController();

  TestTask(String this.testCommand, Future this.done);

  Stream<String> get testOutput => _testOutput.stream;
}
