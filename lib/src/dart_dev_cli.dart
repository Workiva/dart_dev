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

library dart_dev.src.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart'
    show
        TaskProcess,
        parseArgsFromCommand,
        parseExecutableFromCommand,
        reporter;

import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

import 'package:dart_dev/src/tasks/analyze/cli.dart';
import 'package:dart_dev/src/tasks/copy_license/cli.dart';
import 'package:dart_dev/src/tasks/coverage/cli.dart';
import 'package:dart_dev/src/tasks/docs/cli.dart';
import 'package:dart_dev/src/tasks/examples/cli.dart';
import 'package:dart_dev/src/tasks/format/cli.dart';
import 'package:dart_dev/src/tasks/gen_test_runner/cli.dart';
import 'package:dart_dev/src/tasks/init/cli.dart';
import 'package:dart_dev/src/tasks/test/cli.dart';

import 'package:dart_dev/src/version.dart' show printVersion;

ArgParser _parser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('color', defaultsTo: true, help: 'Colorize the output.')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Shows this usage.')
  ..addFlag('quiet',
      abbr: 'q', negatable: false, help: 'Minimizes the logging output.')
  ..addFlag('version',
      negatable: false, help: 'Shows the dart_dev package version.');

Map<String, TaskCli> _cliTasks = {};
Map<String, TaskConfig> _cliConfigs = {};

String _topLevelUsage = _parser.usage;

dev(List<String> args) async {
  registerTask(new AnalyzeCli(), config.analyze);
  registerTask(new CopyLicenseCli(), config.copyLicense);
  registerTask(new CoverageCli(), config.coverage);
  registerTask(new DocsCli(), config.docs);
  registerTask(new ExamplesCli(), config.examples);
  registerTask(new FormatCli(), config.format);
  registerTask(new GenTestRunnerCli(), config.genTestRunner);
  registerTask(new InitCli(), config.init);
  registerTask(new TestCli(), config.test);

  await _run(args);
  exit(exitCode);
}

void registerTask(TaskCli cli, TaskConfig config) {
  _cliTasks[cli.command] = cli;
  _cliConfigs[cli.command] = config;
}

String _generateUsage([String task]) {
  StringBuffer u = new StringBuffer();
  u.writeln('Standardized tooling for Dart projects.');
  u.writeln();

  if (task != null && _cliTasks.containsKey(task)) {
    u.writeln('Usage: pub run dart_dev $task [options]');
    u.writeln();
    u.writeln(_cliTasks[task].argParser.usage);
  } else {
    u.writeln('Usage: pub run dart_dev [task] [options]');
    u.writeln();
    u.writeln(_topLevelUsage);
    u.writeln();
    u.writeln('Supported tasks:');
    u.writeln();
    u.writeln('    ${_cliTasks.keys.join('\n    ')}');
  }

  return u.toString();
}

Future _run(List<String> args) async {
  _cliTasks.forEach((command, cli) {
    _parser.addCommand(command, cli.argParser);
  });

  ArgResults env;
  try {
    env = _parser.parse(args);
  } on FormatException catch (e) {
    reporter.error('${e.message}\n', shout: true);
    reporter.log(_generateUsage(), shout: true);
    exitCode = 1;
    return;
  }

  String task;
  if (env.command != null) {
    task = env.command.name;
  }

  reporter
    ..color = env['color']
    ..quiet = env['quiet'];

  if (env['version']) {
    if (!printVersion()) {
      reporter.error('Couldn\'t find version number.', shout: true);
      exitCode = 1;
    }
    return;
  }

  if (task != null && !_cliTasks.containsKey(task)) {
    reporter.error('Invalid task: $task', shout: true);
    reporter.log(_generateUsage(), shout: true);
    exitCode = 1;
    return;
  }

  if (env['help'] || task == null) {
    reporter.log(_generateUsage(task), shout: true);
    return;
  }

  TaskConfig config = _cliConfigs[task];
  await _runAll(config.before);
  CliResult result = await _cliTasks[task].run(env.command);
  await _runAll(config.after);

  reporter.log('');
  if (result.successful) {
    reporter.success(result.message, shout: true);
  } else {
    reporter.error(result.message, shout: true);
    exitCode = 1;
  }
}

Future _runAll(List tasks) async {
  for (int i = 0; i < tasks.length; i++) {
    if (tasks[i] is Function) {
      await tasks[i]();
    } else if (tasks[i] is String) {
      TaskProcess process = new TaskProcess(
          parseExecutableFromCommand(tasks[i]), parseArgsFromCommand(tasks[i]));
      reporter.logGroup(tasks[i],
          outputStream: process.stdout, errorStream: process.stderr);
      await process.done;
    }
  }
}
