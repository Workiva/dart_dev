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

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/src/config/dart_dev_config.dart';
import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';
import 'package:dart_dev/src/utils/process_utils.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/utils/platform_utils.dart' as platform;
import 'package:dart_dev/src/utils/text_utils.dart' as text;

class AnalyzeTask extends Task {
  @override
  final ArgParser argParser = null;

  @override
  final String command = 'analyze';

  @override
  Future<Null> help(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) async {
    reporter.important(
        'Usage: pub run dart_dev analyze [options...] <libraries to analyze...>');
    reporter.writeln();
    reporter.writeln('The dart_dev analyze task proxies dartanalyzer.');
    reporter.writeln();

    _packageConfig(config, reporter, verbose: verbose);

    reporter.h1('Command Line Options (dartanalyzer)');
    reporter.writeln();
    reporter.indent();
    reporter.writeln(await _getDartanalyzerHelp());
    reporter.dedent();
  }

  @override
  Future<int> run(DartDevConfig config, LenientArgResults parsedArgs,
      text.Reporter reporter) async {
    _packageConfig(config, reporter);

    reporter.h1('Running Analyzer');
    reporter.indent();

    if (!(await platform.isExecutableInstalled('dartanalyzer'))) {
      reporter.writeln();
      reporter.error('Could not find the `dartanalyzer` executable.');
      reporter.dedent();
      return 1;
    }

    final executable = 'dartanalyzer';
    final args = <String>[];

    // Forward all flags & options to the dartanalyzer executable.
    args.addAll(parsedArgs.unknownOptions);

    if (parsedArgs.rest.isNotEmpty) {
      // If libraries are explicitly passed in (as args), analyze them.
      args.addAll(parsedArgs.rest);
    } else {
      // Otherwise, analyze the libraries specified in dart_dev.yaml.
      args.addAll(config.analyze.libraries);
    }

    final process = ProcessHelper.start(executable, args);

    reporter.important('command: $executable ${args.join(' ')}');
    reporter.writeln();

    process.stdout.listen(reporter.writeln);
    process.stderr.listen(reporter.warning);

    await process.done;
    reporter.dedent();
    return process.exitCode;
  }

  Future<String> _getDartanalyzerHelp() {
    final process = ProcessHelper.start('dartanalyzer', ['--help']);
    return process.stderr.join('\n');
  }

  void _packageConfig(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) {
    reporter.h1('Package Configuration');
    reporter.writeln();
    reporter.indent();
    reporter.h2('Libraries to be Analyzed (from dart_dev.yaml)');
    if (config.analyze.libraries.isNotEmpty) {
      for (final lib in config.analyze.libraries) {
        reporter.writeln('- $lib');
      }
    } else {
      reporter.writeln('[none]');
    }
    reporter.writeln();
    reporter.h2('Lint Rules (from analysis_options.yaml/.analysis_options)');
    if (config.analyze.linterRules.isNotEmpty) {
      for (final lintRule in config.analyze.linterRules) {
        reporter.writeln('- $lintRule');
      }
    } else {
      reporter.writeln('[none]');
    }
    reporter.writeln();
    reporter.dedent();
  }
}
