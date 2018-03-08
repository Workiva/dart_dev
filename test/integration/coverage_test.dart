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
library dart_dev.test.integration.coverage_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectWithDartFile = 'test_fixtures/coverage/non_test_file';
const String projectWithBrowserTests = 'test_fixtures/coverage/browser';
const String projectWithVmTests = 'test_fixtures/coverage/vm';
const String projectWithFunctionalTests =
    'test_fixtures/coverage/functional_test/';
const String projectWithBrowserTestsThatNeedsPubServe =
    'test_fixtures/coverage/browser_needs_pub_serve';
const String projectWithoutCoveragePackage =
    'test_fixtures/coverage/no_coverage_package';
const String projectWithFailingTests = 'test_fixtures/coverage/failing_test';

class CoverageResponse {
  bool successfulExit;
  List<String> outputs = [];
  List<String> errors = [];
}

Future<CoverageResponse> runCoverage(String projectPath,
    {bool html: false, bool functional: false}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  Directory oldCoverage = new Directory('$projectPath/coverage');
  if (oldCoverage.existsSync()) {
    oldCoverage.deleteSync(recursive: true);
  }

  List args = ['run', 'dart_dev', 'coverage'];
  if (functional) {
    args.add('--functional');
    args.add('--no-unit');
  }
  args.add(html ? '--html' : '--no-html');
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);
  var response = new CoverageResponse();
  StreamSubscription<String> outSub =
      process.stdout.listen(response.outputs.add);
  StreamSubscription<String> errSub =
      process.stderr.listen(response.errors.add);

  try {
    await process.done;
    response.successfulExit = (await process.exitCode) == 0;
    return response;
  } finally {
    try {
      await outSub.cancel();
      await errSub.cancel();
    } catch (e) {
      print(e);
    }
  }
}

void main() {
  group('Coverage Task', () {
    test('should generate coverage for Browser tests', () async {
      expect(
          (await runCoverage(projectWithBrowserTests)).successfulExit, isTrue);
      File lcov = new File('$projectWithBrowserTests/coverage/coverage.lcov');
      expect(lcov.existsSync(), isTrue);
    }, timeout: new Timeout(new Duration(seconds: 90)));

    test('should generate coverage for Browser tests that require a Pub server',
        () async {
      expect(
          (await runCoverage(projectWithBrowserTestsThatNeedsPubServe))
              .successfulExit,
          isTrue);
      File lcov = new File(
          '$projectWithBrowserTestsThatNeedsPubServe/coverage/coverage.lcov');
      expect(lcov.existsSync(), isTrue);
    }, timeout: new Timeout(new Duration(seconds: 90)));

    test('should generate coverage for VM tests', () async {
      expect((await runCoverage(projectWithVmTests)).successfulExit, isTrue);
      File lcov = new File('$projectWithVmTests/coverage/coverage.lcov');
      expect(lcov.existsSync(), isTrue);
    }, timeout: new Timeout(new Duration(seconds: 90)));

    test('should fail if "coverage" package is missing', () async {
      expect((await runCoverage(projectWithoutCoveragePackage)).successfulExit,
          isFalse);
    });

    test('should fail if there is a test that fails', () async {
      expect(
          (await runCoverage(projectWithFailingTests)).successfulExit, isFalse);
    }, timeout: new Timeout(new Duration(seconds: 90)));

    test(
        'should output test failure info to stderr if there is a test that fails',
        () async {
      CoverageResponse response = (await runCoverage(projectWithFailingTests));
      expect(response.successfulExit, isFalse);
      print(response.errors.join('\n'));
      print('err len=${response.errors.length}');
      expect(response.errors, isNotEmpty);

      expect(
          response.errors.join(),
          stringContainsInOrder([
            '00:00 +0 -1: fails [E]',
            'Expected: true',
            'Actual: <1>',
            'package:test/src/frontend/expect.dart',
          ]));
    }, timeout: new Timeout(new Duration(seconds: 90)));

    test('should create coverage with non_test file specified', () async {
      expect((await runCoverage(projectWithDartFile)).successfulExit, isTrue);
      File lcov = new File('$projectWithDartFile/coverage/coverage.lcov');
      expect(lcov.existsSync(), isTrue);
    }, timeout: new Timeout(new Duration(seconds: 90)));

    test('should generate coverage for Functional tests', () async {
      expect(
          (await runCoverage(projectWithFunctionalTests, functional: true))
              .successfulExit,
          isTrue);
      File lcov =
          new File('$projectWithFunctionalTests/coverage/coverage.lcov');
      expect(lcov.existsSync(), isTrue);
    }, timeout: new Timeout(new Duration(seconds: 300)));

//    TODO: Will need to mock out the `genhtml` command as well.
//    test('should not fail if "lcov" is installed and --html is set', () async {
//       MockPlatformUtil.install();
//       expect(MockPlatformUtil.installedExecutables, contains('lcov'));
//       expect((await runCoverage(projectWithVmTests, html: true)).successfulExit, isTrue);
//       MockPlatformUtil.uninstall();
//    });

//    TODO: Will need to run coverage programmatically for these to work. See https://github.com/Workiva/dart_dev/issues/21
//    test('should fail if "lcov" is not installed and --html is set', () async {
//      MockPlatformUtil.install();
//      MockPlatformUtil.installedExecutables.remove('lcov');
//      expect((await runCoverage(projectWithVmTests, html: true)).successfulExit, isFalse);
//      MockPlatformUtil.uninstall();
//    });
//    test('should not fail if "lcov" is not installed but --html is not set', () async {
//      MockPlatformUtil.install();
//      MockPlatformUtil.installedExecutables.remove('lcov');
//      expect((await runCoverage(projectWithVmTests, html: false)).successfulExit, isTrue);
//      MockPlatformUtil.uninstall();
//    });
  });
}
