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

library dart_dev.src.tasks.analyze.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter, TaskProcess;

import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';
import 'package:dart_dev/src/tasks/analyze/api.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class AnalyzeCli extends TaskCli {
  static Future<String> getAnalyzerUsage() {
    var process = new TaskProcess('dartanalyzer', ['--help']);
    return process.stdout.join();
  }

  final ArgParser argParser = new ArgParser();

  final String command = 'analyze';

  Future<String> getUsage() async {
    var usage = ['dartanalyzer options', '====================', ''].join('\n');
    var process = new TaskProcess('dartanalyzer', ['--help']);
    usage += await process.stderr.join('\n');
    return usage;
  }

  Future<CliResult> run(LenientArgResults parsedArgs) async {
    List<String> entryPoints = config.analyze.entryPoints;
    var cliArgs = parsedArgs.unknownOptions.toList()..addAll(parsedArgs.rest);

    print('\nForwarding the following options and args to dartanalyzer:');
    print(cliArgs);

    AnalyzeTask task = analyze(
        entryPoints: entryPoints,
        fatalWarnings: config.analyze.fatalWarnings,
        hints: config.analyze.hints,
        fatalHints: config.analyze.fatalHints,
        strong: config.analyze.strong,
        cliArgs: cliArgs);
    var title = task.analyzerCommand;

    reporter.logGroup(title, outputStream: task.analyzerOutput);
    await task.done;
    return task.successful
        ? new CliResult.success('Analysis completed.')
        : new CliResult.fail('Analysis failed.');
  }
}
