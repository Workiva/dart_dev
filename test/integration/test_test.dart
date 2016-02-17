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
library dart_dev.test.integration.test_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectWithoutTestPackage = 'test/fixtures/test/no_test_package';
const String projectWithFailingTests = 'test/fixtures/test/failing';
const String projectWithPassingTests = 'test/fixtures/test/passing';
const String projectWithPassingIntegrationTests =
    'test/fixtures/test/passingIntegration';
const String projectThatNeedsPubServe = 'test/fixtures/test/needs_pub_serve';

Future<bool> runTests(String projectPath,
    {bool unit: true,
    bool integration: false,
    List<String> files,
    String testName: ''}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  List args = ['run', 'dart_dev', 'test'];
  if (unit != null) args.add(unit ? '--unit' : '--no-unit');
  if (integration != null)
    args.add(integration ? '--integration' : '--no-integration');
  int i;

  if (files != null) {
    int filesLength = files.length;
    if (filesLength > 0) {
      for (i = 0; i < filesLength; i++) {
        args.add(files[i]);
      }
    }
  }

  if (testName.isNotEmpty) {
    args.addAll(['-n', testName]);
  }

  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  await process.done;
  return (await process.exitCode) == 0;
}

void main() {
  group('Test Task', () {
    test('should fail if some unit tests fail', () async {
      expect(
          await runTests(projectWithFailingTests,
              unit: true, integration: false),
          isFalse);
    });

    test('should fail if some integration tests fail', () async {
      expect(
          await runTests(projectWithFailingTests,
              unit: false, integration: true),
          isFalse);
    });

    test('should run individual unit test', () async {
      expect(
          await runTests(projectWithPassingTests, files: [
            'test/fixtures/test/passing/test/passing_unit_test.dart'
          ]),
          isTrue);
    });

    test('should run individual unit tests', () async {
      expect(
          await runTests(projectWithPassingTests, files: [
            'test/fixtures/test/passing/test/passing_unit_test.dart',
            'test/fixtures/test/passing/test/passing_unit_integration.dart'
          ]),
          isTrue);
    });

    test('should run unit tests', () async {
      expect(
          await runTests(projectWithPassingTests,
              unit: true, integration: false),
          isTrue);
    });

    test('should run unit tests by default', () async {
      expect(
          await runTests(projectWithPassingTests,
              unit: null, integration: null),
          isTrue);
    });

    test('should run integration tests and not unit tests', () async {
      expect(
          await runTests(projectWithPassingIntegrationTests,
              unit: false, integration: true),
          isTrue);
    });

    test('should run unit and integration tests', () async {
      expect(
          await runTests(projectWithPassingTests,
              unit: true, integration: true),
          isTrue);
    });

    test('should warn if "test" package is not immediate dependency', () async {
      expect(await runTests(projectWithoutTestPackage), isFalse);
    });

    test('should run tests that require a Pub server', () async {
      expect(await runTests(projectThatNeedsPubServe), isTrue);
    });

    test('should run tests with test name specified', () async {
      expect(
          await runTests(projectWithPassingTests, testName: 'passes'), isTrue);
    });

    test('should fail if named test does not exist', () async {
      expect(
          await runTests(projectWithPassingTests,
              testName: 'non-existent test'),
          isFalse);
    });
  });
}
