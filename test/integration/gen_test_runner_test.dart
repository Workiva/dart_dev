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

const String browserAndVm = 'test_fixtures/gen_test_runner/browser_and_vm';
const String checkFail = 'test_fixtures/gen_test_runner/check_fail';
const String checkPass = 'test_fixtures/gen_test_runner/check_pass';
const String defaultConfig = 'test_fixtures/gen_test_runner/default_config';

Future<Runner> generateTestRunner(String projectPath,
    {List<String> additionalArgs: const []}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  var files = [];
  var errors = [];
  var stderr = '';
  var stdout = '';
  var args = ['run', 'dart_dev', 'gen-test-runner'];
  if (additionalArgs.isNotEmpty) {
    additionalArgs.forEach((argument) {
      args.add(argument);
    });
  }
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  process.stdout.listen((line) {
    stdout += line;
  });

  process.stderr.listen((line) {
    stderr += line;
  });

  await process.done;

  return new Runner(await process.exitCode, errors, files, stderr, stdout);
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
      Runner runner = await generateTestRunner(defaultConfig);
      expect(runner.exitCode, isZero);
      verifyExistenceAndCleanup(
          path.join(defaultConfig, 'test/generated_runner.dart'),
          shouldFileExist: true);
      verifyExistenceAndCleanup(
          path.join(defaultConfig, 'test/generated_runner.html'),
          shouldFileExist: false);
    });

    test('should work with multiple configs', () async {
      Runner runner = await generateTestRunner(browserAndVm);
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

    group('--check flag', () {
      test('should succeed if the runner is up to date', () async {
        Runner runner =
            await generateTestRunner(checkPass, additionalArgs: ['--check']);
        expect(runner.exitCode, isZero);
        expect(runner.stderr, equals(''));
        expect(runner.stdout.contains('Generated test runner is up-to-date.'),
            isTrue);
      });

      test('should fail if the runner is not up to date', () async {
        Runner runner =
            await generateTestRunner(checkFail, additionalArgs: ['--check']);
        expect(runner.exitCode, isNot(0));
        expect(
            runner.stderr.contains('Generated test runner is not up-to-date.'),
            isTrue);
        expect(runner.stdout, equals(''));
      });
    });
  });
}

class Runner {
  final int exitCode;
  final List<String> errors;
  final List<String> files;
  final String stderr;
  final String stdout;

  Runner(this.exitCode, this.errors, this.files, this.stderr, this.stdout);
}
