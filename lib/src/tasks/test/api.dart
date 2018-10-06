// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library dart_dev.src.tasks.test.api;

import 'dart:async';

import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/tools/selenium.dart' show SeleniumHelper;
import 'package:dart_dev/src/util.dart'
    show dartMajorVersion, dartiumExpirationOverrideEnv;
import 'package:dart_dev/util.dart' show hasImmediateDependency;

TestTask test(
    {int concurrency,
    List<String> platforms: const [],
    List<String> presets: const [],
    List<String> testArgs: const [],
    List<String> tests: const []}) {
  final executable = 'pub';
  final args = <String>[];
  if (dartMajorVersion == 2 && hasImmediateDependency('build_test')) {
    args.addAll(['run', 'build_runner', 'test', '--']);
  } else {
    args.addAll(['run', 'test']);
  }

  if (concurrency != null) {
    args.add('--concurrency=$concurrency');
  }
  platforms.forEach((p) {
    args.addAll(['-p', p]);
  });
  presets.forEach((p) {
    args.addAll(['-P', p]);
  });
  args.addAll(['--reporter=expanded']);
  args.addAll(testArgs);
  args.addAll(tests);

  TaskProcess process = new TaskProcess(executable, args,
      environment: dartiumExpirationOverrideEnv);
  Completer outputProcessed = new Completer();
  TestTask task = new TestTask('$executable ${args.join(' ')}',
      Future.wait([process.done, outputProcessed.future]).then((_) => null));

  // TODO: Use this pattern to better parse the test summary even when the output is colorized
  // RegExp resultPattern = new RegExp(r'(\d+:\d+) \+(\d+) ?~?(\d+)? ?-?(\d+)?: (All|Some) tests (failed|passed)');

  StreamController<String> stdoutc = new StreamController<String>();
  process.stdout.listen((line) async {
    stdoutc.add(line);
    if ((line.contains('All tests passed!') ||
            line.contains('Some tests failed.')) &&
        !outputProcessed.isCompleted) {
      task.testSummary = line;
      await SeleniumHelper.killChildrenProcesses();
      outputProcessed.complete();
    }
  });

  stdoutc.stream.listen(task._testOutput.add);
  process.stderr.listen((line) async {
    task._testOutput.addError(line);
    if (line.contains('No tests match regular expression')) {
      await SeleniumHelper.killChildrenProcesses();
      outputProcessed.complete();
    }
  });
  process.exitCode.then((code) {
    if (task.successful == null) {
      task.successful = code <= 0;
    }
  });

  return task;
}

class TestTask extends Task {
  @override
  final Future<Null> done;
  final String testCommand;
  String testSummary;

  StreamController<String> _testOutput = new StreamController();

  TestTask(String this.testCommand, this.done);

  Stream<String> get testOutput => _testOutput.stream;
}
