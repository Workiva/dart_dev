library dart_dev.src.tasks.test.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/io.dart';

import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/test/api.dart';
import 'package:dart_dev/src/tasks/test/config.dart';

class TestCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addFlag('unit',
        defaultsTo: defaultUnit, help: 'Includes the unit test suite.')
    ..addFlag('integration',
        defaultsTo: defaultIntegration,
        help: 'Includes the integration test suite.')
    ..addOption('platform',
        abbr: 'p',
        allowMultiple: true,
        help:
            'The platform(s) on which to run the tests.\n[vm (default), dartium, content-shell, chrome, phantomjs, firefox, safari]');

  final String command = 'test';

  Future<CliResult> run(ArgResults parsedArgs) async {
    bool unit = parsedArgs['unit'];
    bool integration = parsedArgs['integration'];
    List<String> platforms =
        TaskCli.valueOf('platform', parsedArgs, config.test.platforms);

    if (!unit && !integration) {
      return new CliResult.fail(
          'No tests were selected. Include at least one of --unit or --integration.');
    }

    List<String> tests = [];
    if (unit) {
      if (config.test.unitTests.isEmpty) {
        return new CliResult.fail(
            'This project does not specify any unit tests.');
      }
      tests.addAll(config.test.unitTests);
    }
    if (integration) {
      if (config.test.integrationTests.isEmpty) {
        return new CliResult.fail(
            'This project does not specify any integration tests.');
      }
      tests.addAll(config.test.integrationTests);
    }

    TestTask task = test(platforms: platforms, tests: tests);
    reporter.logGroup(task.testCommand, outputStream: task.testOutput);
    await task.done;
    return task.successful
        ? new CliResult.success(task.testSummary)
        : new CliResult.fail(task.testSummary);
  }
}
