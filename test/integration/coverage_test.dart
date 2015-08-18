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
