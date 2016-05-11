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

library dart_dev.src.tasks.gen_test_runner.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/gen_test_runner/api.dart';

class GenResultGroup {
  List<bool> passing = [];
  List<GenTestRunnerTask> tasks = [];
}

class GenTestRunnerCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addOption('config',
        help:
            'Configuration options should be performed in local dev.dart file');

  final String command = 'gen-test-runner';

  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    GenResultGroup results = new GenResultGroup();

    for (var currentConfig in config.genTestRunner.configs) {
      if (!new Directory(currentConfig.directory).existsSync()) {
        return new CliResult.fail(
            'Must return a valid directory path, ${currentConfig.directory} is not a valid path');
      }

      GenTestRunnerTask task = await genTestRunner(currentConfig);
      await task.done;
      results.tasks.add(task);
      results.passing.add(task.successful);
    }

    if (results.passing.contains(false)) {
      var failedFiles = '';
      for (var task in results.tasks) {
        if (!task.successful) {
          failedFiles += ' ${task.runnerFile}';
        }
      }
      return new CliResult.fail('Failed to generate test runner.'
          '\nThe following file(s) failed to generate:$failedFiles');
    } else {
      String resultMessage = '';
      for (var i = 0; i < results.tasks.length; i++) {
        resultMessage +=
            'Generated using ${results.tasks[i].generateCommand}\n';
        results.tasks[i].excludedFiles.forEach((filename) {
          resultMessage += '[NOTICE] Found non-test dart file: $filename\n';
        });
        resultMessage += '\n';
        results.tasks[i].testFiles.forEach((filename) {
          resultMessage += 'Found test dart file: $filename\n';
        });
        resultMessage +=
            '\nCreated runner file: ${results.tasks[i].runnerFile}\n';
      }
      return new CliResult.success('$resultMessage\nTest runner generated');
    }
  }
}
