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
const String browserAndVmRunner =
    'test_fixtures/gen_test_runner/browser_and_vm_runner';
const String checkFail = 'test_fixtures/gen_test_runner/check_fail';
const String checkPass = 'test_fixtures/gen_test_runner/check_pass';
const String activeTestsRegex = 'test_fixtures/gen_test_runner/active_tests_regex';
const String defaultConfig = 'test_fixtures/gen_test_runner/default_config';

Future<Runner> generateTestRunner(String projectPath,
    {List<String> additionalArgs: const []}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  var files = <String>[];
  var errors = <String>[];
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

verifyExistenceCommentedLinesAndCleanup(
    String filename, String offendingRegex) {
  expect(FileSystemEntity.isFileSync(filename), isTrue);
  var file = new File(filename);
  var lines = file.readAsLinesSync();
  for (var line in lines) {
    if (line.trim().startsWith('//')) {
      expect(line.contains(offendingRegex), isTrue);
    } else {
      expect(line.contains(offendingRegex), isFalse);
    }
  }

  return null;
}

verifyContent(String filePath, String expectedContent) {
  var file = new File(filePath);
  var fileContent = file.readAsStringSync();
  expect(fileContent.contains(expectedContent), isTrue);
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

    test('should create runner with both vm and browser annotation', () async {
      Runner runner = await generateTestRunner(browserAndVmRunner);
      expect(runner.exitCode, isZero);
      String runnerPath =
          path.join(browserAndVmRunner, 'test/generated_runner.dart');
      File testRunner = new File(runnerPath);
      String fileContents = testRunner.readAsStringSync();
      expect(fileContents.contains('@TestOn(\'browser || vm\')'), isTrue);
      verifyExistenceAndCleanup(runnerPath, shouldFileExist: true);
    });

    group('--check flag', () {
      test('should succeed if the runner is up to date', () async {
        Runner runner =
            await generateTestRunner(checkPass, additionalArgs: ['--check']);
        expect(runner.exitCode, isZero);
        expect(runner.stderr, equals(''));
        expect(runner.stdout.contains('Generated test runner is up-to-date.'),
            isTrue);
        verifyContent(
            checkPass + '/test/generated_runner.dart',
            '// Generated by `pub run dart_dev gen-test-runner -d test/ -e '
            'Environment.browser --genHtml`');
        // This verifies that the html file was not overwritten during the check
        // task
        verifyContent(checkPass + '/test/generated_runner.html',
            '<div>custom item</div>');
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

    group('--activeTestRegex option', () {
      test('generates normally', () async {
        Runner runner = await generateTestRunner(activeTestsRegex);
        expect(runner.exitCode, isZero);
        var actGeneratedFilename =
            path.join(activeTestsRegex, 'test/generated_runner.dart');
        verifyExistenceCommentedLinesAndCleanup(actGeneratedFilename, '');
        verifyExistenceAndCleanup(actGeneratedFilename, shouldFileExist: true);
        verifyExistenceAndCleanup(
            path.join(activeTestsRegex, 'test/generated_runner.html'),
            shouldFileExist: false);
      });

      group('comments out tests matching a given regex', () {
        test('long form', () async {
          Runner runner = await generateTestRunner(activeTestsRegex,
              additionalArgs: ['--activeTestsRegex', 'totally_active']);
          expect(runner.exitCode, isZero);
          var actGeneratedFilename =
              path.join(activeTestsRegex, 'test/generated_runner.dart');
          verifyExistenceCommentedLinesAndCleanup(
              actGeneratedFilename, 'totally_active');
          verifyExistenceAndCleanup(actGeneratedFilename,
              shouldFileExist: true);
          verifyExistenceAndCleanup(
              path.join(activeTestsRegex, 'test/generated_runner.html'),
              shouldFileExist: false);
        });

        test('short form', () async {
          Runner runner = await generateTestRunner(activeTestsRegex,
              additionalArgs: ['-t', 'totally_active']);
          expect(runner.exitCode, isZero);
          var actGeneratedFilename =
              path.join(activeTestsRegex, 'test/generated_runner.dart');
          verifyExistenceCommentedLinesAndCleanup(
              actGeneratedFilename, 'totally_active');
          verifyExistenceAndCleanup(actGeneratedFilename,
              shouldFileExist: true);
          verifyExistenceAndCleanup(
              path.join(activeTestsRegex, 'test/generated_runner.html'),
              shouldFileExist: false);
        });
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
