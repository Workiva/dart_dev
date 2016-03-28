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

library dart_dev.src.tasks.saucelab_tests.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter, TaskProcess;

import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/saucelab_tests/api.dart';
import 'package:dart_dev/src/tasks/saucelab_tests/sauce_runner.dart'
    as sauceRunner;
import 'package:dart_dev/src/tasks/saucelab_tests/xml_reporter.dart';

class SauceRunnerCli extends TaskCli {
  final ArgParser argParser = new ArgParser();

  final String command = 'saucelab-tests';

  final String sauceAccessKey = env['SAUCE_ACCESS_KEY'];
  final String sauceUserName = env['SAUCE_USERNAME'];

  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    if (sauceUserName == null || sauceAccessKey == null) {
      return new CliResult.fail('Sauce Labs credentials must be available via '
          'the `SAUCE_ACCESS_KEY` and `SAUCE_USERNAME` SauceRunnerConfig instance.');
    }

    if (config.saucelabTests.filesToTest.isEmpty) {
      return new CliResult.fail('You must specify files to test.');
    }

    List<sauceRunner.SauceTest> sauceTests = [];

    for (String file in config.saucelabTests.filesToTest) {
      String filePath = '${Directory.current.path}/test/$file';
      var tempFile = new File(filePath);
      if (!tempFile.existsSync()) {
        return new CliResult.fail('$filePath doesn\'t exist in this project.');
      }
      sauceTests.add(new sauceRunner.SauceTest(file, file));
    }

    var pubServe = env['PUB_SERVE'];
    final int pubServePort =
        pubServe != null ? config.saucelabTests.pubServer : 0;

    var autoSauceConnect;
    var tunnelIdentifier;
    if (env['SAUCE_CONNECT_TUNNEL_IDENTIFIER'] != null) {
      autoSauceConnect = false;
      tunnelIdentifier = env['SAUCE_CONNECT_TUNNEL_IDENTIFIER'];
    } else {
      autoSauceConnect = true;
      tunnelIdentifier = generateTunnelIdentifier();
    }

    var results = await sauceRunner.run(sauceTests,
        config.saucelabTests.platforms, sauceUserName, sauceAccessKey,
        autoSauceConnect: autoSauceConnect,
        tunnelIdentifier: tunnelIdentifier,
        options: getSauceBuildOptions(),
        pubServePort: pubServePort);

    var failed = false;

    for (var i = 0; i < results['js tests'].length; i++) {
      if (results['js tests'][i]['result']['failed'] > 0) {
        failed = true;
      }
    }

    reporter.log('');
    reporter.log(
        'Writing xUnit test report to ${config.saucelabTests.testReportPath}.');
    var reportXml = sauceResultsToXunitXml(results);
    var reportOutput = new File(config.saucelabTests.testReportPath);
    await reportOutput.create(recursive: true);
    await reportOutput.writeAsString(reportXml);

    if (failed) {
      return new CliResult.fail('Fail, there was an error in running your tests'
          ' please review the output above and the test report located at'
          ' ${config.saucelabTests.testReportPath}.');
    } else {
      return new CliResult.success(
          'Success, your tests completely successfully'
          ' on saucelabs.');
    }
  }
}
