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

library dart_dev.src.tasks.coverage.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter;

import 'package:dart_dev/src/platform_util/api.dart' as platform_util;
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/coverage/api.dart';
import 'package:dart_dev/src/tasks/coverage/config.dart';
import 'package:dart_dev/src/tasks/coverage/exceptions.dart';
import 'package:dart_dev/src/tasks/test/config.dart';

class CoverageCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addFlag('unit',
        defaultsTo: defaultUnit, help: 'Includes the unit test suite.')
    ..addFlag('integration',
        defaultsTo: defaultIntegration,
        help: 'Includes the integration test suite.')
    ..addFlag('html',
        negatable: true,
        defaultsTo: defaultHtml,
        help: 'Generate and open an HTML report.')
    ..addFlag('pub-serve',
        negatable: true,
        defaultsTo: defaultPubServe,
        help: 'Serves browser tests using a Pub server.')
    ..addFlag('open',
        negatable: true,
        defaultsTo: true,
        help: 'Open the HTML report automatically.');

  final String command = 'coverage';

  Future<CliResult> run(ArgResults parsedArgs) async {
    if (!platform_util.hasImmediateDependency('coverage'))
      return new CliResult.fail(
          'Package "coverage" must be an immediate dependency in order to run its executables.');

    bool unit = parsedArgs['unit'];
    bool integration = parsedArgs['integration'];

    if (!unit && !integration) {
      return new CliResult.fail(
          'No tests were selected. Include at least one of --unit or --integration.');
    }

    bool html = TaskCli.valueOf('html', parsedArgs, config.coverage.html);
    bool pubServe =
        TaskCli.valueOf('pub-serve', parsedArgs, config.coverage.pubServe);
    bool open = TaskCli.valueOf('open', parsedArgs, true);

    List<String> tests = [];
    if (unit) {
      tests.addAll(config.test.unitTests);
    }
    if (integration) {
      tests.addAll(config.test.integrationTests);
    }
    if (tests.isEmpty) {
      if (unit && config.test.unitTests.isEmpty) {
        return new CliResult.fail(
            'This project does not specify any unit tests.');
      }
      if (integration && config.test.integrationTests.isEmpty) {
        return new CliResult.fail(
            'This project does not specify any integration tests.');
      }
    }

    CoverageResult result;
    try {
      CoverageTask task = CoverageTask.start(tests,
          html: html,
          pubServe: pubServe,
          output: config.coverage.output,
          reportOn: config.coverage.reportOn);
      reporter.logGroup('Collecting coverage',
          outputStream: task.output, errorStream: task.errorOutput);
      result = await task.done;
    } on MissingLcovException catch (e) {
      return new CliResult.fail(e.message);
    }

    if (result.successful && html && open) {
      await Process.run('open', [result.reportIndex.path]);
    }
    return result.successful
        ? new CliResult.success('Coverage collected.')
        : new CliResult.fail('Coverage failed.');
  }
}
