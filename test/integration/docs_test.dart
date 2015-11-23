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
library dart_dev.test.integration.docs_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const String projectWithDocs = 'test/fixtures/docs/docs';
const String projectWithoutDartdoc = 'test/fixtures/docs/no_dartdoc_package';

Future<bool> generateDocsFor(String projectPath) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  var args = ['run', 'dart_dev', 'docs', '--no-open'];
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);
  await process.done;

  return (await process.exitCode) == 0;
}

void main() {
  group('Docs task', () {
    test('should generate docs for a valid project', () async {
      expect(await generateDocsFor(projectWithDocs), isTrue);
      expect(FileSystemEntity
              .isFileSync(path.join(projectWithDocs, 'doc/api/index.html')),
          isTrue);
    });

    test('should fail if the "dartdoc" package is not an immediate dependency',
        () async {
      expect(await generateDocsFor(projectWithoutDartdoc), isFalse);
    });
  });
}
