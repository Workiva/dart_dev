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
library dart_dev.test.integration.copy_license_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess, copyDirectory;
import 'package:test/test.dart';

const String projectWithLicenses = 'test/fixtures/copy_license/has_licenses';
const String projectWithoutLicenseFile =
    'test/fixtures/copy_license/no_license_file';
const String projectWithoutLicenses = 'test/fixtures/copy_license/no_licenses';
const String projectWithUntrimmedLicense =
    'test/fixtures/copy_license/license_with_empty_lines';

Future<String> createTemporaryProject(String source) async {
  String tempProject = '${source}_temp';
  Directory temp = new Directory(tempProject);
  copyDirectory(new Directory(source), temp);
  return tempProject;
}

Future<List<String>> copyLicense(String projectPath) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  TaskProcess process = new TaskProcess(
      'pub', ['run', 'dart_dev', 'copy-license', '--no-color'],
      workingDirectory: projectPath);

  String licenseAppliedPattern = 'License successfully applied';
  String noLicenseFilePattern = 'does not exist';
  bool didApplyLicense = false;
  bool noLicenseFile = false;
  List<String> files = [];

  await for (var line in process.stdout) {
    if (didApplyLicense) {
      files.add(line.trim());
    }
    if (line.contains(licenseAppliedPattern)) {
      didApplyLicense = true;
    }
  }

  await for (var line in process.stderr) {
    if (line.contains(noLicenseFilePattern)) {
      noLicenseFile = true;
    }
  }

  await process.done;
  if (noLicenseFile) throw new NoLicenseFileException();
  return files;
}

void deleteTemporaryProject(String path) {
  Directory temp = new Directory(path);
  temp.deleteSync(recursive: true);
}

class NoLicenseFileException implements Exception {}

void main() {
  group('Copy License Task', () {
    test('should warn if the license file does not exist', () async {
      expect(copyLicense(projectWithoutLicenseFile),
          throwsA(new isInstanceOf<NoLicenseFileException>()));
    });

    test('should not apply license to files that already have it', () async {
      expect(await copyLicense(projectWithLicenses), isEmpty);
    });

    test('should apply license to all files that need it', () async {
      String projectPath = await createTemporaryProject(projectWithoutLicenses);
      List<String> expectedFiles = [
        'lib/index.html',
        'lib/main.dart',
        'lib/script.js',
        'lib/style.css'
      ];
      expect(await copyLicense(projectPath), unorderedEquals(expectedFiles));
      deleteTemporaryProject(projectPath);
    });

    test('should trim leading and trailing empty lines from license', () async {
      String projectPath =
          await createTemporaryProject(projectWithUntrimmedLicense);
      expect(await copyLicense(projectPath), isNotEmpty);
      String contents =
          new File('$projectPath/lib/main.dart').readAsStringSync();
      var lines = contents.split('\n');
      var licenseLines = lines.where((line) => line.startsWith('//'));
      expect(licenseLines.length, equals(3));
      deleteTemporaryProject(projectPath);
    });
  });
}
