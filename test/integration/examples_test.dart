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
library dart_dev.test.integration.examples_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectWithExamples = 'test/fixtures/examples/examples_dir';
const String projectWithoutExamples = 'test/fixtures/examples/no_examples_dir';

Future<bool> serveExamplesFor(String projectPath) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  TaskProcess process = new TaskProcess('pub', ['run', 'dart_dev', 'examples'],
      workingDirectory: projectPath);

  bool served = false;

  Pattern pubServePattern = new RegExp(r'pub serve .* example');
  process.stdout.listen((line) async {
    if (line.contains(pubServePattern)) {
      served = true;
      await process.killGroup();
      process.kill();
    }
  });

  await process.done;
  return served;
}

void main() {
  group('Examples Task', () {
    test('should warn if no examples directory found', () async {
      expect(await serveExamplesFor(projectWithoutExamples), isFalse);
    });

    test('should serve if examples directory found', () async {
      expect(await serveExamplesFor(projectWithExamples), isTrue);
    });
  });
}
