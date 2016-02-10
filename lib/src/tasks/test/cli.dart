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

import 'package:dart_dev/util.dart' show reporter, TaskProcess;

import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';
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
    ..addFlag('pub-serve',
        negatable: false,
        defaultsTo: defaultPubServe,
        help: 'Spins up a Pub server and uses it to serve browser tests.');

  final String command = 'test';

  Future<String> getUsage() async {
    var usage = [
      'dart_dev test options',
      '=====================',
      '${argParser.usage}',
      '',
      'test package options',
      '====================',
    ].join('\n');
    var process = new TaskProcess('pub', ['run', 'test', '-h']);
    usage += await process.stdout.join('\n');
    return usage;
  }

  bool hasRestParams(LenientArgResults parsedArgs) {
    return parsedArgs.rest.length > 0;
  }

  bool isExplicitlyFalse(bool value) {
    return value != null && value == false;
  }

  Future<CliResult> run(LenientArgResults parsedArgs) async {
    if (!platform_util.hasImmediateDependency('test'))
      return new CliResult.fail(
          'Package "test" must be an immediate dependency in order to run its executables.');

    List<String> cliArgs = [];

    bool unit = parsedArgs['unit'];
    bool integration = parsedArgs['integration'];
    List<String> tests = [];
    int individualTests = 0;

    bool pubServe =
        TaskCli.valueOf('pub-serve', parsedArgs, config.test.pubServe);

    List<String> platforms = [];
    if (!parsedArgs.unknownOptions.any(
        (option) => option.contains('-p') || option.contains('--platform'))) {
      platforms = config.test.platforms;
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

    if (tests.isEmpty && parsedArgs.rest.isEmpty) {
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
      cliArgs.add('--pub-serve=${serveInfo.port}');

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

    var forwardedArgs = parsedArgs.unknownOptions.toList()
      ..addAll(parsedArgs.rest);
    print('\nForwarding the following options and args to `pub run test`:');
    print(forwardedArgs);

    cliArgs.addAll(forwardedArgs);

    TestTask task = test(tests: tests, platforms: platforms, cliArgs: cliArgs);
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
