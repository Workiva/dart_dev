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
import 'dart:convert';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

RegExp numTestsPassedPattern = new RegExp(r'\+(\d+)(:| )');
const String projectToVerifyUnitTestsRunByDefault =
    'test_fixtures/test/default_unit';
const String projectWithoutTestPackage = 'test_fixtures/test/no_test_package';
const String projectWithFailingTests = 'test_fixtures/test/failing';
const String projectWithPassingTests = 'test_fixtures/test/passing';
const String projectWithPassingIntegrationTests =
    'test_fixtures/test/passingIntegration';
const String projectThatNeedsPubServe = 'test_fixtures/test/needs_pub_serve';

Future<int> runTests(String projectPath,
    {bool unit: true,
    bool integration: false,
    List<String> files,
    String testName: '',
    bool runCustomPubServe: false,
    int pubServePort: 56090}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  List args = ['run', 'dart_dev', 'test', '--no-color'];
  if (unit != null) args.add(unit ? '--unit' : '--no-unit');
  if (integration != null)
    args.add(integration ? '--integration' : '--no-integration');

  if (testName.isNotEmpty) {
    args.addAll(['-n', testName]);
  }

  Process pubServeProcess;
  if (runCustomPubServe) {
    // start a default pub server
    pubServeProcess = await Process.start(
        'pub', ['serve', '--port=$pubServePort', 'test'],
        workingDirectory: '$projectPath');

    Completer completer = new Completer();

    pubServeProcess.stdout
        .transform(UTF8.decoder)
        .transform(new LineSplitter())
        .listen((var line) {
      if (line.contains('Build completed successfully')) {
        completer.complete();
      }
    });

    await completer.future;

    // A port of 0 is ignored to validate a failure scenario for no port + pub-serve-started flag
    if (pubServePort > 0) {
      args.add('--pub-serve-port=$pubServePort');
    }
  }

  args.addAll(files ?? <String>[]);
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  await process.done;
  if ((await process.exitCode) != 0)
    throw new TestFailure('Expected test to pass.');

  String lastLine = await process.stdout.last;

  if (pubServeProcess != null) {
    pubServeProcess.kill();
  }

  var numTestsRun = -1;
  if (numTestsPassedPattern.hasMatch(lastLine)) {
    numTestsRun =
        int.parse(numTestsPassedPattern.firstMatch(lastLine).group(1));
  }
  return numTestsRun;
}

void main() {
  group('Test Task', () {
    test('should fail if some unit tests fail', () async {
      expect(runTests(projectWithFailingTests, unit: true, integration: false),
          throwsA(new isInstanceOf<TestFailure>()));
    });

    test('should fail if some integration tests fail', () async {
      expect(runTests(projectWithFailingTests, unit: false, integration: true),
          throwsA(new isInstanceOf<TestFailure>()));
    });

    test('should run individual unit test', () async {
      expect(
          await runTests(projectWithPassingTests,
              files: ['test/passing_unit_test.dart']),
          equals(1));
    });

    test('should run individual unit tests', () async {
      expect(
          await runTests(projectWithPassingTests, files: [
            'test/passing_unit_test.dart',
            'test/passing_integration_test.dart'
          ]),
          equals(2));
    });

    test('should run unit tests', () async {
      expect(
          await runTests(projectWithPassingTests,
              unit: true, integration: false),
          equals(1));
    });

    test('should run unit tests by default', () async {
      expect(
          await runTests(projectToVerifyUnitTestsRunByDefault,
              unit: null, integration: null),
          equals(1));
    });

    test('should run integration tests and not unit tests', () async {
      expect(
          await runTests(projectWithPassingIntegrationTests,
              unit: false, integration: true),
          equals(1));
    });

    test('should run unit and integration tests', () async {
      expect(
          await runTests(projectWithPassingTests,
              unit: true, integration: true),
          equals(2));
    });

    test('should warn if "test" package is not immediate dependency', () async {
      expect(runTests(projectWithoutTestPackage),
          throwsA(new isInstanceOf<TestFailure>()));
    });

    test('should run tests that require a Pub server', () async {
      expect(await runTests(projectThatNeedsPubServe), equals(1));
    });

    test('should run tests that provides a Pub server', () async {
      expect(await runTests(projectThatNeedsPubServe, runCustomPubServe: true),
          equals(1));
    });

    test('should run tests with test name specified', () async {
      expect(await runTests(projectWithPassingTests, testName: 'passes'),
          equals(1));
    });

    test('should fail if named test does not exist', () async {
      expect(runTests(projectWithPassingTests, testName: 'non-existent test'),
          throwsA(new isInstanceOf<TestFailure>()));
    });
  });
}
