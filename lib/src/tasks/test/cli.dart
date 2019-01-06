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

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter, isPortBound;

import 'package:dart_dev/src/platform_util/api.dart' as platform_util;
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/serve/api.dart';
import 'package:dart_dev/src/tasks/test/api.dart';
import 'package:dart_dev/src/tasks/test/config.dart';
import 'package:dart_dev/src/util.dart' show dartMajorVersion, inCi, runAll;

class TestCli extends TaskCli {
  @override
  final ArgParser argParser = new ArgParser()
    ..addFlag('unit', defaultsTo: null, help: 'Includes the unit test suite.')
    ..addFlag('integration',
        defaultsTo: defaultIntegration,
        help: 'Includes the integration test suite.')
    ..addFlag('functional',
        defaultsTo: defaultFunctional,
        help: 'Includes the functional test suite.')
    ..addOption('concurrency',
        abbr: 'j',
        defaultsTo: '$defaultConcurrency',
        help: 'The number of concurrent test suites run.')
    ..addFlag('pub-serve',
        negatable: true,
        defaultsTo: defaultPubServe,
        help: 'Serves browser tests using a Pub server.')
    ..addFlag('pause-after-load',
        help: 'Pauses for debugging before any tests execute.\n'
            'Implies --concurrency=1 and --timeout=none.\n'
            'Currently only supported for browser tests.',
        negatable: false)
    ..addOption('pub-serve-port',
        help:
            'Port used by the Pub server for browser tests. The default value will randomly select an open port to use.')
    ..addOption('platform',
        abbr: 'p',
        allowMultiple: true,
        help:
            'The platform(s) on which to run the tests.\n[vm (default), chrome, firefox, safari]')
    ..addOption('preset',
        abbr: 'P',
        allowMultiple: true,
        help: 'The configuration preset(s) to use.')
    ..addOption('name',
        abbr: 'n',
        help:
            'A substring of the name of the test to run.\nRegular expression syntax is supported.')
    ..addOption('web-compiler',
        abbr: 'w', help: ' The JavaScript compiler to use to serve the tests.');

  @override
  final String command = 'test';

  @override
  String get usage => '${super.usage} [files or directories...]';

  bool isExplicitlyFalse(bool value) {
    return value != null && value == false;
  }

  @override
  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    if (!platform_util.hasImmediateDependency('test')) {
      return new CliResult.fail(
          'Package "test" must be an immediate dependency in order to run its executables.');
    }

    final testArgs = <String>[];
    List<String> tests = [];

    if (!color) {
      testArgs.add('--no-color');
    }

    bool pauseAfterLoad =
        TaskCli.valueOf('pause-after-load', parsedArgs, defaultPauseAfterLoad);

    bool pubServe =
        TaskCli.valueOf('pub-serve', parsedArgs, config.test.pubServe);

    var pubServePort =
        TaskCli.valueOf('pub-serve-port', parsedArgs, config.test.pubServePort);
    if (pubServePort is String) {
      pubServePort = int.parse(pubServePort);
    }

    var concurrency =
        TaskCli.valueOf('concurrency', parsedArgs, config.test.concurrency);
    if (concurrency is String) {
      concurrency = int.parse(concurrency);
    }
    List<String> platforms =
        TaskCli.valueOf('platform', parsedArgs, config.test.platforms);
    List<String> presets =
        TaskCli.valueOf('preset', parsedArgs, const <String>[]);

    // CLI user can specify individual test files to run.
    bool individualTestsSpecified = parsedArgs.rest.isNotEmpty;

    // The unit test suite should be run by default.
    bool unit = parsedArgs['unit'] ?? true;

    // The integration suite should only be run if the --integration is set.
    bool integration = parsedArgs['integration'] ?? false;

    // The functional suite should only be run if the --functional is set.
    bool functional = parsedArgs['functional'] ?? false;

    // CLI user can filter tests by name.
    bool testNamed = parsedArgs['name'] != null;

    bool compilerSpecified = parsedArgs['web-compiler'] != null;

    if (!individualTestsSpecified && !unit && !integration && !functional) {
      return new CliResult.fail(
          'No tests were selected. Include at least one of --unit, '
          '--integration, --functional or pass in one or more test '
          'files/directories');
    }

    // Build the list of tests to run.
    if (individualTestsSpecified) {
      // Individual tests explicitly passed in should override the test suites.
      tests.addAll(parsedArgs.rest);
    } else {
      // Unit and/or integration suites should only run if individual tests
      // were not specified.
      if (unit) {
        tests.addAll(config.test.unitTests);
      }
      if (integration) {
        tests.addAll(config.test.integrationTests);
      }
      if (functional) {
        tests.addAll(config.test.functionalTests);
      }
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
      if (functional && config.test.functionalTests.isEmpty) {
        return new CliResult.fail(
            'This project does not specify any functional tests.');
      }
    }

    if (pauseAfterLoad) {
      testArgs.add('--pause-after-load');
    }

    Duration pubServeStartupTime;
    PubServeTask pubServeTask;

    if (pubServe) {
      if (dartMajorVersion == 2) {
        reporter.warning('''Pub serve was removed in Dart 2.
A pub serve instance will not be started.''');
      } else {
        bool isPubServeRunning = await isPortBound(pubServePort);

        if (!isPubServeRunning) {
          // Start `pub serve` on the `test` directory
          var pubServeArgs = ['test'];
          if (compilerSpecified) {
            pubServeArgs.add('--web-compiler=${parsedArgs['web-compiler']}');
          }

          final stopwatch = new Stopwatch()..start();
          pubServeTask =
              startPubServe(port: pubServePort, additionalArgs: pubServeArgs);
          pubServeTask.ready.then((_) {
            stopwatch.stop();
            pubServeStartupTime = stopwatch.elapsed;
          }, onError: (_) {});

          var startupLogFinished = new Completer();
          reporter.logGroup(pubServeTask.command,
              outputStream: pubServeTask.stdOut
                  .transform(until(startupLogFinished.future)),
              errorStream: pubServeTask.stdErr
                  .transform(until(startupLogFinished.future)));

          var serveInfo = await pubServeTask.serveInfos.first;
          pubServePort = serveInfo.port;

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

        testArgs.add('--pub-serve=$pubServePort');
      }
    }

    if (testNamed) {
      testArgs.addAll(['-n', '${parsedArgs['name']}']);
    }

    if (functional && config.test.beforeFunctionalTests.isNotEmpty) {
      await runAll(config.test.beforeFunctionalTests);
    }

    TestTask task = test(
        tests: tests,
        concurrency: concurrency,
        platforms: platforms,
        presets: presets,
        testArgs: testArgs);
    reporter.logGroup(task.testCommand, outputStream: task.testOutput);

    await task.done;

    if (pubServeTask != null) {
      pubServeTask.stop();
      // Wait for the task to finish to flush its output.
      await pubServeTask.done;
    }

    if (functional && config.test.afterFunctionalTests.isNotEmpty) {
      await runAll(config.test.after = config.test.afterFunctionalTests);
    }

    // This will be null if we didn't start a Pub server or it never finished.
    if (pubServeStartupTime != null) {
      printPubServeSpeedMessage(pubServeStartupTime);
    }

    return task.successful
        ? new CliResult.success(task.testSummary)
        : new CliResult.fail(task.testSummary);
  }
}

void printPubServeSpeedMessage(Duration startupTime) {
  const longStartupThreshold = const Duration(seconds: 5);
  if (startupTime < longStartupThreshold || inCi()) {
    return;
  }

  final boldWhite = new AnsiPen()..white(bold: true);
  final boldYellow = new AnsiPen()..yellow(bold: true);
  final seconds =
      (startupTime.inMilliseconds / Duration.MILLISECONDS_PER_SECOND)
          .toStringAsFixed(1);
  reporter.log('''

********************************************************************
* ${boldWhite('Did you know?')} 
* You don't have to wait to start new Pub server for each test run!                                                               
*                                                                 
* Reusing a Pub server would have made this test run                                                                 
* at least ${boldYellow('$seconds seconds faster')}.                                                                
*                                                                
* To do this, start a Pub server on any open port: 
*     pub serve test --port 8083
* 
* And then in a different terminal, run your tests and 
* provide that same port via `--pub-serve-port`.
*     ddev test --pub-serve-port=8083
*
* Happy testing!                                                                
********************************************************************''');
}
