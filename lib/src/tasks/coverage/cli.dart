library dart_dev.src.tasks.coverage.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show hasImmediateDependency, reporter;

import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/coverage/api.dart';
import 'package:dart_dev/src/tasks/coverage/config.dart';
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
    ..addFlag('open',
        negatable: true,
        defaultsTo: true,
        help: 'Open the HTML report automatically.');

  final String command = 'coverage';

  Future<CliResult> run(ArgResults parsedArgs) async {
    if (!hasImmediateDependency('coverage')) return new CliResult.fail(
        'Package "coverage" must be an immediate dependency in order to run its executables.');

    bool unit = parsedArgs['unit'];
    bool integration = parsedArgs['integration'];

    if (!unit && !integration) {
      return new CliResult.fail(
          'No tests were selected. Include at least one of --unit or --integration.');
    }

    bool html = TaskCli.valueOf('html', parsedArgs, config.coverage.html);
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

    CoverageTask task = CoverageTask.start(tests,
        html: html,
        output: config.coverage.output,
        reportOn: config.coverage.reportOn);
    reporter.logGroup('Collecting coverage',
        outputStream: task.output, errorStream: task.errorOutput);
    CoverageResult result = await task.done;
    if (result.successful && open) {
      Process.run('open', [result.reportIndex.path]);
    }
    return result.successful
        ? new CliResult.success('Coverage collected.')
        : new CliResult.fail('Coverage failed.');
  }
}
