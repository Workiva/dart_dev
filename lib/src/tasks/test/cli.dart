library dart_dev.src.tasks.test.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show hasImmediateDependency, reporter;

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
    if (!hasImmediateDependency('test')) return new CliResult.fail(
        'Package "test" must be an immediate dependency in order to run its executables.');

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

    TestTask task = test(platforms: platforms, tests: tests);
    reporter.logGroup(task.testCommand, outputStream: task.testOutput);
    await task.done;
    return task.successful
        ? new CliResult.success(task.testSummary)
        : new CliResult.fail(task.testSummary);
  }
}
