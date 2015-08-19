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

const String projectWithVmTests = 'test/fixtures/coverage/browser';
const String projectWithBrowserTests = 'test/fixtures/coverage/vm';
const String projectWithoutCoveragePackage =
    'test/fixtures/coverage/no_coverage_package';

Future<bool> runCoverage(String projectPath) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  Directory oldCoverage = new Directory('$projectPath/coverage');
  if (oldCoverage.existsSync()) {
    oldCoverage.deleteSync(recursive: true);
  }

  List args = ['run', 'dart_dev', 'coverage', '--no-open'];
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  await process.done;
  return (await process.exitCode) == 0;
}

void main() {
  group('Coverage Task', () {
    test('should generate coverage for Browser tests', () async {
      expect(await runCoverage(projectWithBrowserTests), isTrue);
      File lcov = new File('$projectWithBrowserTests/coverage/coverage.lcov');
      expect(lcov.existsSync(), isTrue);
    }, timeout: new Timeout(new Duration(seconds: 60)));

    test('should generate coverage for VM tests', () async {
      expect(await runCoverage(projectWithVmTests), isTrue);
      File lcov = new File('$projectWithVmTests/coverage/coverage.lcov');
      expect(lcov.existsSync(), isTrue);
    }, timeout: new Timeout(new Duration(seconds: 60)));

    test('should warn if "coverage" package is missing', () async {
      expect(await runCoverage(projectWithoutCoveragePackage), isFalse);
    });
  });
}
