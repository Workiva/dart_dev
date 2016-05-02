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

@TestOn('vm')
library dart_dev.test.integration.local_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String noTaskProject = 'test_fixtures/local/no_tasks';
const String noExecutableProject = 'test_fixtures/local/no_executable';
const String validTaskProject = 'test_fixtures/local/good_tasks';

Future<TaskProcess> local(String projectPath,
    {List<String> taskArgs: const []}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  var p = new TaskProcess('pub', ['run', 'dart_dev']..addAll(taskArgs),
      workingDirectory: projectPath);

  return p;
}

Future expectExitWith(Future<TaskProcess> process, Matcher match) async {
  var p = await process;
  await p.done;

  var statusCode = await p.exitCode;

  expect(statusCode, match,
      reason: 'Expected process to exit with given exit code');
}

Future expectOutput(Future<TaskProcess> process, String pattern) async {
  var p = await process;
  await p.done;

  var outputContainsPattern =
      await p.stdout.any((line) => line.contains(pattern));
  expect(outputContainsPattern, isTrue,
      reason: 'Expected process output to contain ${pattern} but did not');
}

void main() {
  group('Local Task', () {
    test('should work as expected without any tasks', () async {
      await expectExitWith(local(noTaskProject), equals(0));
    });

    test('should return with non zero when unknown executable task is called',
        () async {
      await expectExitWith(
          local(noExecutableProject, taskArgs: ['noExec']), isNot(0));
      await expectOutput(local(noExecutableProject, taskArgs: ['noExec']),
          'A executable was not defined for the discovered task noExec.');
    });

    test('should contain discovered tasks when no dart_dev task given',
        () async {
      await expectOutput(local(validTaskProject), "exampleTask");
    });

    test('should execute a task when given the local task', () async {
      await expectOutput(
          // Executes the example local task which appends the first argument
          // provided to a the 'Hello ' string.
          local(validTaskProject, taskArgs: ['exampleTask', 'world!']),
          "Hello world!");
    });
  });
}
