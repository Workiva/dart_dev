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
library dart_dev.test.integration.format_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess, copyDirectory;
import 'package:test/test.dart';

const String projectWithChangesNeeded = 'test/fixtures/format/changes_needed';
const String projectWithNoChangesNeeded =
    'test/fixtures/format/no_changes_needed';
const String projectWithoutDartStyle = 'test/fixtures/format/no_dart_style';

/// Runs dart formatter via dart_dev on given project.
///
/// If [check] is true, a dry-run only is run. Returns true if changes are
/// needed, false if the project is well-formatted.
///
/// If [check] is false, an actual formatting run is run. Returns true if
/// formatting was successful, false otherwise.
Future<bool> formatProject(String projectPath, {bool check: false}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  var args = ['run', 'dart_dev', 'format'];
  if (check) {
    args.add('--check');
  }
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  await process.done;
  return (await process.exitCode) == 0;
}

void main() {
  group('Format Task', () {
    test('--check should succeed if no files need formatting', () async {
      expect(
          await formatProject(projectWithNoChangesNeeded, check: true), isTrue);
    });

    test('--check should fail if one or more files need formatting', () async {
      expect(
          await formatProject(projectWithChangesNeeded, check: true), isFalse);
    });

    test('should not make any changes to a well-formatted project', () async {
      File file = new File('$projectWithNoChangesNeeded/lib/main.dart');
      String contentsBefore = file.readAsStringSync();
      expect(await formatProject(projectWithNoChangesNeeded), isTrue);
      String contentsAfter = file.readAsStringSync();
      expect(contentsBefore, equals(contentsAfter));
    });

    test('should format an ill-formatted project', () async {
      // Copy the ill-formatted project fixture to a temporary directory for
      // testing purposes (necessary since formatter will make changes).
      String testProject = '${projectWithChangesNeeded}_temp';
      Directory temp = new Directory(testProject);
      copyDirectory(new Directory(projectWithChangesNeeded), temp);

      File dirtyFile = new File('$testProject/lib/main.dart');
      File cleanFile = new File('$projectWithNoChangesNeeded/lib/main.dart');
      String contentsBefore = dirtyFile.readAsStringSync();
      expect(await formatProject(testProject), isTrue);
      String contentsAfter = dirtyFile.readAsStringSync();
      expect(contentsBefore, isNot(equals(contentsAfter)));
      expect(contentsAfter, equals(cleanFile.readAsStringSync()));

      // Clean up the temporary test project created for this test case.
      temp.deleteSync(recursive: true);
    });

    test('should warn if "dart_style" is not an immediate dependency',
        () async {
      expect(await formatProject(projectWithoutDartStyle), isFalse);
    });
  });
}
