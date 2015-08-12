library dart_dev.src.tasks.analyze.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter;

import 'package:dart_dev/src/tasks/analyze/api.dart';
import 'package:dart_dev/src/tasks/analyze/config.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class AnalyzeCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addFlag('fatal-warnings',
        defaultsTo: defaultFatalWarnings,
        negatable: true,
        help: 'Treat non-type warnings as fatal.')
    ..addFlag('hints',
        defaultsTo: defaultHints, negatable: true, help: 'Show hint results.');

  final String command = 'analyze';

  Future<CliResult> run(ArgResults parsedArgs) async {
    List<String> entryPoints = config.analyze.entryPoints;
    bool fatalWarnings = TaskCli.valueOf(
        'fatal-warnings', parsedArgs, config.analyze.fatalWarnings);
    bool hints = TaskCli.valueOf('hints', parsedArgs, config.analyze.hints);

    AnalyzeTask task = analyze(
        entryPoints: entryPoints, fatalWarnings: fatalWarnings, hints: hints);
    reporter.logGroup(task.analyzerCommand, outputStream: task.analyzerOutput);
    await task.done;
    return task.successful
        ? new CliResult.success('Analysis completed.')
        : new CliResult.fail('Analysis failed.');
  }
}
