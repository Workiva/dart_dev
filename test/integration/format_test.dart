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

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:dart_dev/util.dart' show TaskProcess, copyDirectory;

const String projectWithChangesNeeded = 'test_fixtures/format/changes_needed';
const String projectWithExclusions = 'test_fixtures/format/exclusions';
const String projectWithInclusions = 'test_fixtures/format/inclusions';
const String projectWithInclusionsDeprecated =
    'test_fixtures/format/inclusions_deprecated';
const String projectWithNoChangesNeeded =
    'test_fixtures/format/no_changes_needed';
const String projectWithoutDartStyle = 'test_fixtures/format/no_dart_style';

/// Runs dart formatter via dart_dev on given project.
///
/// If [check] is true, a dry-run only is run. Returns true if changes are
/// needed, false if the project is well-formatted.
///
/// If [check] is false, an actual formatting run is run. Returns true if
/// formatting was successful, false otherwise.
Future<bool> formatProject(
  String projectPath, {
  Iterable<String> additionalArgs: const <String>[],
  bool check: false,
}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  var args = ['run', 'dart_dev', 'format'];
  if (check) {
    args.add('--check');
  }
  if (additionalArgs != null) {
    args.addAll(additionalArgs);
  }
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  await process.done;
  return (await process.exitCode) == 0;
}

// Returns the path to a new temporary copy of the [project] fixture
// testing purposes, necessary since formatter may make changes to ill-formatted files.
String copyProject(String project) {
  final String testProject = '${project}_temp';

  final Directory temp = new Directory(testProject);
  copyDirectory(new Directory(project), temp);
  addTearDown(() {
    // Clean up the temporary test project created for this test case.
    temp.deleteSync(recursive: true);
  });

  return testProject;
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

    group('on an ill-formatted project', () {
      String testProject;

      const allFiles = const [
        'lib/library_1.dart',
        'lib/library_2.dart',
      ];

      setUp(() {
        testProject = copyProject(projectWithChangesNeeded);
      });

      Map<String, String> getAllFilesContents() => new Map.fromIterable(
          allFiles,
          value: (file) => new File('$testProject/$file').readAsStringSync());

      test('should format all ill-formatted files', () async {
        var contentsBefore = getAllFilesContents();
        expect(await formatProject(testProject), isTrue);
        var contentsAfter = getAllFilesContents();

        for (var file in allFiles) {
          expect(contentsBefore[file], isNot(contentsAfter[file]),
              reason: '$file should have been formatted');
        }
      });

      test('should format only the paths specified as arguments', () async {
        // It's important that these are relative paths to the project root
        const expectedModifiedFiles = const [
          'lib/library_1.dart',
        ];

        var contentsBefore = getAllFilesContents();
        expect(
            await formatProject(testProject,
                additionalArgs: expectedModifiedFiles),
            isTrue);
        var contentsAfter = getAllFilesContents();

        for (var file in allFiles) {
          if (expectedModifiedFiles.contains(file)) {
            expect(contentsBefore[file], isNot(contentsAfter[file]),
                reason: '$file should have been formatted');
          } else {
            expect(contentsBefore[file], contentsAfter[file],
                reason: '$file should not have been formatted');
          }
        }
      });
    });

    test('should handle when all files specified as arguments are excluded',
        () async {
      const excludedFile = 'lib/excluded_file.dart';

      var contentsBefore =
          new File('$projectWithExclusions/$excludedFile').readAsStringSync();
      expect(
          await formatProject(projectWithExclusions,
              additionalArgs: [excludedFile]),
          isTrue);
      var contentsAfter =
          new File('$projectWithExclusions/$excludedFile').readAsStringSync();

      expect(contentsBefore, contentsAfter,
          reason: '$excludedFile should not have been formatted');
    });

    test('should resolve absolute paths for files specified as arguments',
        () async {
      const excludedFile = 'lib/excluded_file.dart';
      const relativeExcludedFilePath = '$projectWithExclusions/$excludedFile';

      final absoluteExcludedFilePath = p.absolute(relativeExcludedFilePath);

      var contentsBefore =
          new File(relativeExcludedFilePath).readAsStringSync();
      expect(
          await formatProject(projectWithExclusions,
              additionalArgs: [absoluteExcludedFilePath]),
          isTrue);
      var contentsAfter = new File(relativeExcludedFilePath).readAsStringSync();

      expect(contentsBefore, contentsAfter,
          reason: '$excludedFile should not have been formatted');
    });

    test('should warn if "dart_style" is not an immediate dependency',
        () async {
      expect(await formatProject(projectWithoutDartStyle), isFalse);
    });

    test('should allow files/directories to be excluded', () async {
      const expectedUntouchedFiles = const [
        '$projectWithExclusions/lib/excluded_file.dart',
        '$projectWithExclusions/lib/excluded_dir_1/inside_excluded_dir.dart',
        '$projectWithExclusions/lib/excluded_dir_2/inside_excluded_dir.dart',
      ];

      var contentsBefore = new Map<String, String>.fromIterable(
          expectedUntouchedFiles,
          value: (file) => new File(file).readAsStringSync());

      expect(await formatProject(projectWithExclusions), isTrue);

      var contentsAfter = new Map<String, String>.fromIterable(
          expectedUntouchedFiles,
          value: (file) => new File(file).readAsStringSync());

      for (var file in expectedUntouchedFiles) {
        expect(contentsBefore[file], contentsAfter[file],
            reason: '$file should not have been formatted');
      }
    });

    group('should allow files/directories to be explicitly included', () {
      const allFiles = const [
        'lib/included_dir_1/inside_included_dir.dart',
        'lib/included_dir_2/inside_included_dir.dart',
        'lib/included.dart',
        'lib/not_included.dart',
      ];

      test('using `config.format.paths`', () async {
        var testProject = copyProject(projectWithInclusions);

        // It's important that these are relative paths to the project root
        const expectedUntouchedFiles = const [
          'lib/not_included.dart',
        ];

        Map<String, String> getAllFilesContents() => new Map.fromIterable(
            allFiles,
            value: (file) => new File('$testProject/$file').readAsStringSync());

        var contentsBefore = getAllFilesContents();
        expect(await formatProject(testProject), isTrue);
        var contentsAfter = getAllFilesContents();

        for (var file in allFiles) {
          if (expectedUntouchedFiles.contains(file)) {
            expect(contentsBefore[file], contentsAfter[file],
                reason: '$file should not have been formatted');
          } else {
            expect(contentsBefore[file], isNot(contentsAfter[file]),
                reason: '$file should have been formatted');
          }
        }
      });

      test('using the deprecated `config.format.directories`', () async {
        var testProject = copyProject(projectWithInclusionsDeprecated);

        // It's important that these are relative paths to the project root
        const expectedUntouchedFiles = const [
          'lib/not_included.dart',
        ];

        Map<String, String> getAllFilesContents() => new Map.fromIterable(
            allFiles,
            value: (file) => new File('$testProject/$file').readAsStringSync());

        var contentsBefore = getAllFilesContents();
        expect(await formatProject(testProject), isTrue);
        var contentsAfter = getAllFilesContents();

        for (var file in allFiles) {
          if (expectedUntouchedFiles.contains(file)) {
            expect(contentsBefore[file], contentsAfter[file],
                reason: '$file should not have been formatted');
          } else {
            expect(contentsBefore[file], isNot(contentsAfter[file]),
                reason: '$file should have been formatted');
          }
        }
      });
    });

    test('should skip files in "packages" when excludes specified', () async {
      File file = new File('$projectWithExclusions/lib/packages/main.dart');
      String contentsBefore = file.readAsStringSync();
      expect(await formatProject(projectWithExclusions), isTrue);
      String contentsAfter = file.readAsStringSync();
      expect(contentsBefore, equals(contentsAfter));
    });

    test('should skip files in ".pub" when excludes specified', () async {
      File file = new File('$projectWithExclusions/lib/.pub/main.dart');
      String contentsBefore = file.readAsStringSync();
      expect(await formatProject(projectWithExclusions), isTrue);
      String contentsAfter = file.readAsStringSync();
      expect(contentsBefore, equals(contentsAfter));
    });
  });
}
