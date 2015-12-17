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
library dart_dev.test.integration.analyze_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectWithErrors = 'test/fixtures/analyze/errors';
const String projectWithHints = 'test/fixtures/analyze/hints';
const String projectWithNoIssues = 'test/fixtures/analyze/no_issues';

Future<Analysis> analyzeProject(String projectPath,
    {bool fatalWarnings: true, bool hints: true}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  var args = ['run', 'dart_dev', 'analyze'];
  args.add(fatalWarnings ? '--fatal-warnings' : '--no-fatal-warnings');
  args.add(hints ? '--hints' : '--no-hints');
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  List<String> files = [];
  int numErrors = 0;
  int numHints = 0;
  int numWarnings = 0;

  RegExp filesPattern = new RegExp(r'Analyzing \[(.*)\]');
  RegExp errorsPattern = new RegExp(r'(\d+) error.* found');
  RegExp hintsPattern = new RegExp(r'(\d+) hint.* found');
  RegExp warningsPattern = new RegExp(r'(\d+) warning.* found');

  process.stdout.listen((line) {
    if (line.contains(filesPattern)) {
      files = filesPattern.firstMatch(line).group(1).split(', ');
    }
    if (line.contains(errorsPattern)) {
      numErrors += int.parse(errorsPattern.firstMatch(line).group(1));
    }
    if (line.contains(hintsPattern)) {
      numHints += int.parse(hintsPattern.firstMatch(line).group(1));
    }
    if (line.contains(warningsPattern)) {
      numWarnings += int.parse(warningsPattern.firstMatch(line).group(1));
    }
  });

  await process.done;
  return new Analysis(
      await process.exitCode, files, numErrors, numHints, numWarnings);
}

class Analysis {
  final int exitCode;
  final List<String> files;
  final int numErrors;
  final int numHints;
  final int numWarnings;
  Analysis(this.exitCode, this.files, this.numErrors, this.numHints,
      this.numWarnings);
  bool get noIssues => numHints + numErrors == 0;
}

void main() {
  group('Analyze Task', () {
    test('should discover all top-level files of defined entry points',
        () async {
      Analysis analysis = await analyzeProject(projectWithNoIssues);
      var expectedFiles = [
        'bin/executable.dart',
        'lib/no_issues.dart',
        'tool/dev.dart'
      ];
      expect(analysis.files, unorderedEquals(expectedFiles));
    });

    test('should report no issues found', () async {
      Analysis analysis = await analyzeProject(projectWithNoIssues);
      expect(analysis.noIssues, isTrue);
    });

    test('should report hints if configured to do so', () async {
      Analysis analysis = await analyzeProject(projectWithHints);
      expect(analysis.numHints, equals(2));
    });

    test('should not report hints if configured to ignore them', () async {
      Analysis analysis = await analyzeProject(projectWithHints, hints: false);
      expect(analysis.numHints, equals(0));
    });

    test('should report warnings as fatal if configured to do so', () async {
      Analysis analysis = await analyzeProject(projectWithErrors);
      expect(analysis.numErrors, equals(2));
      expect(analysis.numWarnings, equals(0));
    });

    test('should not report warnings as fatal if not configured to do so',
        () async {
      Analysis analysis =
          await analyzeProject(projectWithErrors, fatalWarnings: false);
      expect(analysis.numErrors, equals(1));
      expect(analysis.numWarnings, equals(1));
    });
  });
}
