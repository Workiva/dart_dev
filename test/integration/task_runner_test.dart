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
import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectPassingTasks = 'test_fixtures/task_runner/passing_tasks';
const String projectFailingTasks = 'test_fixtures/task_runner/failing_tasks';

const String failedFormatting = 'The Dart formatter needs to be run.';
const String successfulFormatting = 'Your Dart code is good to go!';
const String successfulAnalysis = 'Analysis completed.';

/// Runs the task-runner task via dart_dev on a given project.
Future<TasksRun> runTasks(String projectPath) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  var args = ['run', 'dart_dev', 'task-runner'];
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);
  List<String> failedTasks = [];
  List<String> successfulTasks = [];

  process.stdout.listen((line) {
    if (line.contains(successfulFormatting)) {
      successfulTasks.add(successfulFormatting);
    }
    if (line.contains(successfulAnalysis)) {
      successfulTasks.add(successfulAnalysis);
    }
    if (line.contains(failedFormatting)) {
      failedTasks.add(failedFormatting);
    }
  });

  await process.done;

  return new TasksRun(await process.exitCode, successfulTasks, failedTasks);
}

class TasksRun {
  final int exitCode;
  final List<String> successfulTasks;
  final List<String> failedTasks;
  TasksRun(this.exitCode, this.successfulTasks, this.failedTasks);
}

void main() {
  group('Task Runner,', () {
    test('tasks completed successfully', () async {
      TasksRun tasks = await runTasks(projectPassingTasks);
      expect(tasks.exitCode, isZero);
      expect(tasks.successfulTasks.contains(successfulAnalysis), isTrue);
      expect(tasks.successfulTasks.contains(successfulFormatting), isTrue);
    });

    test('a task failed', () async {
      TasksRun tasks = await runTasks(projectFailingTasks);
      expect(tasks.exitCode, isNonZero);
      expect(tasks.successfulTasks.contains(successfulAnalysis), isTrue);
      expect(tasks.successfulTasks.contains(successfulFormatting), isFalse);
      expect(tasks.failedTasks.contains(failedFormatting), isTrue);
    });
  });
}
