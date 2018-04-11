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

import 'dart:async';
import 'dart:io';

import 'package:dart2_constant/convert.dart' as convert;
import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectWithConfig =
    'test_fixtures/export_config/with_format_config';
const String projectWithNoConfig = 'test_fixtures/export_config/with_no_config';

/// Runs `ddev export-config` for a given [projectPath] and returns the stdout
/// output.
Future<String> exportConfigForProject(String projectPath,
    {bool check: false}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  var args = ['run', 'dart_dev', 'export-config'];
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);

  var outputFuture = process.stdout.join('\n');

  expect(await process.exitCode, 0);

  return await outputFuture;
}

void main() {
  group('Export Config Task', () {
    test('should emit JSON-parseable output', () async {
      var output = await exportConfigForProject(projectWithConfig);

      var json;
      expect(() {
        json = convert.json.decode(output);
      }, returnsNormally);

      expect(json, const isInstanceOf<Map>());
    });

    test('should emit JSON with default config for projects without a dev.dart',
        () async {
      var json = convert.json
          .decode(await exportConfigForProject(projectWithNoConfig));

      // Just test the format task for now, since it's currently
      // the only config with serialization implemented.
      expect(json, contains('format'));

      var formatConfig = json['format'];
      // default values
      expect(formatConfig, containsPair('check', false));
      expect(formatConfig, containsPair('directories', ['lib/']));
      expect(formatConfig, containsPair('exclude', []));
      expect(formatConfig, containsPair('lineLength', 80));
    });

    test('should emit JSON that includes custom config values', () async {
      var json =
          convert.json.decode(await exportConfigForProject(projectWithConfig));

      // Just test the format task for now, since it's currently
      // the only config with serialization implemented.
      expect(json, contains('format'));

      var formatConfig = json['format'];
      // default values
      expect(formatConfig, containsPair('check', false));
      expect(formatConfig, containsPair('directories', ['lib/']));
      // custom values
      expect(formatConfig, containsPair('exclude', ['foo', 'bar']));
      expect(formatConfig, containsPair('lineLength', 1234));
    });
  });
}
