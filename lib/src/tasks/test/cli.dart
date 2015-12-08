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

library dart_dev.src.tasks.test.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter;

import 'package:dart_dev/src/platform_util/api.dart' as platform_util;
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/serve/api.dart';
import 'package:dart_dev/src/tasks/test/api.dart';
import 'package:dart_dev/src/tasks/test/config.dart';

class TestCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addFlag('unit', defaultsTo: null, help: 'Includes the unit test suite.')
    ..addFlag('integration',
        defaultsTo: defaultIntegration,
        help: 'Includes the integration test suite.')
    ..addOption('concurrency',
        abbr: 'j',
        defaultsTo: '$defaultConcurrency',
        help: 'The number of concurrent test suites run.')
    ..addFlag('pub-serve',
        negatable: true,
        defaultsTo: defaultPubServe,
        help: 'Serves browser tests using a Pub server.')
    ..addOption('platform',
        abbr: 'p',
        allowMultiple: true,
        help:
            'The platform(s) on which to run the tests.\n[vm (default), dartium, content-shell, chrome, phantomjs, firefox, safari]');

  final String command = 'test';

  bool hasRestParams(ArgResults parsedArgs) {
    return parsedArgs.rest.length > 0;
  }

  Future addToTestsFromRest(List<String> tests, List<String> rest) async {
    int restLength = rest.length;
    int individualTests = 0;
    //verify this is a test-file and it exists.
    for (var i = 0; i < restLength; i++) {
      String filePath = rest[i];
      await new File(filePath).exists().then((bool exists) {
        if (exists) {
          individualTests++;
          tests.add(filePath);
        } else {
          print("Ignoring unknown argument");
        }
      });
    }
    return individualTests;
  }

  bool isExplicitlyFalse(bool value) {
    return value != null && value == false;
  }

  Future<CliResult> run(ArgResults parsedArgs) async {
    if (!platform_util.hasImmediateDependency('test'))
      return new CliResult.fail(
          'Package "test" must be an immediate dependency in order to run its executables.');

    List<String> additionalArgs = [];

    bool unit = parsedArgs['unit'];
    bool integration = parsedArgs['integration'];
    List<String> tests = [];
    int individualTests = 0;

    bool pubServe =
        TaskCli.valueOf('pub-serve', parsedArgs, config.test.pubServe);

    var concurrency =
        TaskCli.valueOf('concurrency', parsedArgs, config.test.concurrency);
    if (concurrency is String) {
      concurrency = int.parse(concurrency);
    }
    List<String> platforms =
        TaskCli.valueOf('platform', parsedArgs, config.test.platforms);

    if (hasRestParams(parsedArgs)) {
      individualTests = await addToTestsFromRest(tests, parsedArgs.rest);
    }

    if (isExplicitlyFalse(unit) && !integration && individualTests == 0) {
      return new CliResult.fail(
          'No tests were selected. Include at least one of --unit or --integration.');
    } else {
      if (individualTests == 0) unit = true;
    }

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

    PubServeTask pubServeTask;
    if (pubServe) {
      // Start `pub serve` on the `test` directory
      pubServeTask = startPubServe(additionalArgs: ['test']);

      var startupLogFinished = new Completer();
      reporter.logGroup(pubServeTask.command,
          outputStream:
              pubServeTask.stdOut.transform(until(startupLogFinished.future)),
          errorStream:
              pubServeTask.stdErr.transform(until(startupLogFinished.future)));

      var serveInfo = await pubServeTask.serveInfos.first;
      additionalArgs.add('--pub-serve=${serveInfo.port}');

      startupLogFinished.complete();
      pubServeTask.stdOut.join('\n').then((stdOut) {
        if (stdOut.isNotEmpty) {
          reporter.logGroup('`${pubServeTask.command}` (buffered stdout)',
              output: stdOut);
        }
      });
      pubServeTask.stdErr.join('\n').then((stdErr) {
        if (stdErr.isNotEmpty) {
          reporter.logGroup('`${pubServeTask.command}` (buffered stderr)',
              error: stdErr);
        }
      });
    }

    TestTask task = test(
        tests: tests,
        concurrency: concurrency,
        platforms: platforms,
        additionalArgs: additionalArgs);
    reporter.logGroup(task.testCommand, outputStream: task.testOutput);

    await task.done;

    if (pubServeTask != null) {
      pubServeTask.stop();
      // Wait for the task to finish to flush its output.
      await pubServeTask.done;
    }

    return task.successful
        ? new CliResult.success(task.testSummary)
        : new CliResult.fail(task.testSummary);
  }
}
