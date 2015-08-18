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

Future<bool> runTests(String projectPath,
    {bool unit: true, bool integration: false}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  List args = ['run', 'dart_dev', 'test'];
  args.add(unit ? '--unit' : '--no-unit');
  args.add(integration ? '--integration' : '--no-integration');
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

    test('should run unit tests', () async {
      expect(
          await runTests(projectWithPassingTests,
              unit: true, integration: false),
          isTrue);
    });

    test('should run integration tests', () async {
      expect(
          await runTests(projectWithPassingTests,
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
  });
}
