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

class DocsTask extends Task {
  @override
  final ArgParser argParser = null;

  @override
  final String command = 'docs';

  @override
  Future<Null> help(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) async {
    reporter.important('Usage: pub run dart_dev docs [options...]');
    reporter.writeln();
    reporter.writeln('The dart_dev docs task proxies dartdoc.');
    reporter.writeln();

    reporter.h1('Command Line Options: dartdoc');
    reporter.writeln();
    reporter.indent();
    reporter.writeln(await _getDartdocHelp());
    reporter.dedent();
  }

  @override
  Future<int> run(DartDevConfig config, LenientArgResults parsedArgs,
      text.Reporter reporter) async {
    reporter.h1('Running Dartdoc');
    reporter.indent();

    if (!(await platform.hasImmediateDependency('dartdoc'))) {
      reporter.writeln();
      reporter.error('Package "dartdoc" must be an immediate dependency in '
          'order to run its executables.');
      reporter.error('Please add "dartdoc" to your pubspec.yaml.');
      reporter.dedent();
      return 1;
    }

    final executable = 'dartdoc';
    final args = <String>[];

    // Forward all flags & options to the dartanalyzer exectuable.
    args.addAll(parsedArgs.unknownOptions);

    final process = ProcessHelper.start(executable, args);

    reporter.important('command: $executable ${args.join(' ')}');
    reporter.writeln();

    process.stdout.listen(reporter.writeln);
    process.stderr.listen(reporter.warning);

    await process.done;
    reporter.dedent();
    return process.exitCode;
  }

  Future<String> _getDartdocHelp() {
    final process = ProcessHelper.start('dartdoc', ['--help']);
    return process.stdout.join('\n');
  }
}
