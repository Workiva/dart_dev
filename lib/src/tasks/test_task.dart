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
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/utils/platform_utils.dart' as platform;
import 'package:dart_dev/src/utils/process_utils.dart';
import 'package:dart_dev/src/utils/pub_serve_utils.dart';
import 'package:dart_dev/src/utils/text_utils.dart' as text;

class TestTask extends Task {
  @override
  final ArgParser argParser = null;

  @override
  final String command = 'test';

  @override
  Future<Null> help(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) async {
    reporter
        .important('Usage: pub run dart_dev test [files or directories...]');
    reporter.writeln();
    reporter.writeln('The dart_dev test task proxies pub run test.');
    reporter.writeln();

    _packageConfig(config, reporter, verbose: verbose);

    reporter.h1('Command Line Options (pub run test)');
    reporter.writeln();
    reporter.indent();
    reporter.writeln(await _getTestHelp());
    reporter.dedent();
  }

  @override
  Future<int> run(DartDevConfig config, LenientArgResults parsedArgs,
      text.Reporter reporter) async {
    _packageConfig(config, reporter);

    if (!(await platform.hasImmediateDependency('test'))) {
      reporter.writeln();
      reporter.error('Package "test" must be an immediate dependency in order '
          'to run its executables.');
      reporter.error('Please add "test" to your pubspec.yaml.');
      reporter.dedent();
      return 1;
    }

    PubServe pubServe;
    PubServeInfo pubServeInfo;
    if (config.test.pubServe) {
      reporter.h1('Pub Server');
      reporter.indent();

      pubServe = PubServe
          .start(port: config.test.pubServePort, additionalArgs: ['test']);
      reporter.important('command: ${pubServe.command}');

      try {
        pubServeInfo = await pubServe.onServe.first;
      } on StateError {
        reporter.writeln();
        reporter.error('Failed to start pub server:');
        reporter.indent();
        await pubServe.done;
        reporter.writeln(await pubServe.stdErr.join('\n'));
        reporter.dedent();
        reporter.dedent();
        return 1;
      }

      reporter.writeln('Serving on port ${pubServeInfo.port}');
      reporter.writeln();
      reporter.dedent();
    }

    reporter.h1('Running Tests');
    reporter.indent();

    final executable = 'pub';
    final args = <String>['run', 'test'];

    // Forward all flags, options, and args to the test executable.
    args..addAll(parsedArgs.unknownOptions)..addAll(parsedArgs.rest);

    // Tell the test executable about the pub server if one was started.
    if (pubServeInfo != null) {
      args.add('--pub-serve=${pubServeInfo.port}');
    }

    reporter.important('command: $executable ${args.join(' ')}');

    final process = ProcessHelper.start(executable, args);

    process.stdout.listen(reporter.writeln);
    process.stderr.listen(reporter.warning);

    final exitCode = await process.exitCode;
    if (pubServe != null) {
      await pubServe.kill();
    }

    await process.done;
    reporter.dedent();
    return exitCode;
  }

  Future<String> _getTestHelp() {
    final process = ProcessHelper.start('pub', ['run', 'test', '--help']);
    return process.stdout.join('\n');
  }

  void _packageConfig(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) {
    String pubServePortValue = '${config.test.pubServePort}';
    if (config.test.pubServePort == 0) {
      pubServePortValue += ' (automatic)';
    }

    reporter.h1('Package Configuration');
    reporter.writeln();
    reporter.indent();
    reporter.h2('Pub Serve (from dart_dev.yaml)');
    reporter.writeln('- Enabled: ${config.test.pubServe}');
    if (config.test.pubServe) {
      reporter.writeln('- Port: $pubServePortValue');
    }
    reporter.writeln();

    reporter.dedent();
  }
}
