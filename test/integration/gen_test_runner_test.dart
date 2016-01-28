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
library dart_dev.test.integration.gen_test_runner;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const String defaultConfig = 'test/fixtures/gen_test_runner/default_config';
const String browserAndVm = 'test/fixtures/gen_test_runner/browser_and_vm';

Future<Runner> generateTestRunnerDocsFor(String projectPath,
    {List<String> additionalArgs: const []}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  var files = [];
  var errors = [];
  var args = ['run', 'dart_dev', 'gen-test-runner'];
  if (additionalArgs.isNotEmpty) {
    additionalArgs.forEach((argument) {
      args.add(argument);
    });
  }
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  await process.done;

  return new Runner(await process.exitCode, errors, files);
}

verifyExistenceAndCleanup(String file,
    {bool delete: false, bool shouldFileExist}) {
  expect(FileSystemEntity.isFileSync(file), equals(shouldFileExist));
  if (shouldFileExist) {
    new File(file).deleteSync();
  }
}

void main() {
  group('gen-test-runner task', () {
    test('should work with default config', () async {
      Runner runner = await generateTestRunnerDocsFor(defaultConfig);
      expect(runner.exitCode, isZero);
      verifyExistenceAndCleanup(
          path.join(defaultConfig, 'test/generated_runner.dart'),
          shouldFileExist: true);
      verifyExistenceAndCleanup(
          path.join(defaultConfig, 'test/generated_runner.html'),
          shouldFileExist: false);
    });

    test('should work with multiple configs', () async {
      Runner runner = await generateTestRunnerDocsFor(browserAndVm);
      expect(runner.exitCode, isZero);
      verifyExistenceAndCleanup(
          path.join(browserAndVm, 'test/browser/generated_runner.dart'),
          shouldFileExist: true);
      verifyExistenceAndCleanup(
          path.join(browserAndVm, 'test/browser/generated_runner.html'),
          shouldFileExist: true);
      verifyExistenceAndCleanup(
          path.join(browserAndVm, 'test/vm/generated_runner.dart'),
          shouldFileExist: true);
      verifyExistenceAndCleanup(
          path.join(browserAndVm, 'test/vm/generated_runner.html'),
          shouldFileExist: false);
    });
  });
}

class Runner {
  final int exitCode;
  final List<String> errors;
  final List<String> files;
  Runner(this.exitCode, this.errors, this.files);
}
