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
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/src/config/utils.dart' as config_utils;
import 'package:dart_dev/src/lenient_args/lenient_parser.dart';
import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';
import 'package:dart_dev/src/tasks/analyze_task.dart';
import 'package:dart_dev/src/tasks/apply_license_task.dart';
import 'package:dart_dev/src/tasks/coverage_task.dart';
import 'package:dart_dev/src/tasks/docs_task.dart';
import 'package:dart_dev/src/tasks/format_task.dart';
import 'package:dart_dev/src/tasks/test_task.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/utils/text_utils.dart' as text;
import 'package:dart_dev/src/version.dart';

final _dartDevArgParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('color', defaultsTo: true, help: 'Colorize the output.')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Shows this usage.')
  ..addFlag('version',
      negatable: false, help: 'Shows the dart_dev package version.');

final _tasks = <String, Task>{};

Future<Null> run(List<String> args) async {
  args = new List.from(args);

  bool help = false;
  bool useColor = true;
  bool version = false;

  // Pull out the global dart_dev flags.
  if (args.contains('--no-color')) {
    useColor = false;
    args.remove('--no-color');
  }
  if (args.contains('--help')) {
    help = true;
    args.remove('--help');
  }
  if (args.contains('-h')) {
    help = true;
    args.remove('-h');
  }
  if (args.contains('--version')) {
    version = true;
    args.remove('--version');
  }

  final reporter = new text.Reporter(stdout, useColor: useColor);
  reporter.writeln();

  // Parse the dart_dev config (dart_dev.yaml).
  final config = config_utils.loadDartDevConfig();

  // Register all dart_dev tasks.
  _registerTask(new AnalyzeTask());
  _registerTask(new ApplyLicenseTask());
  _registerTask(new CoverageTask());
  _registerTask(new DocsTask());
  _registerTask(new FormatTask());
  _registerTask(new TestTask());

  // TODO: Handle local tasks

  // Parse the given arguments.
  LenientArgResults parsedArgs;
  try {
    parsedArgs = LenientParser.parseArgs(_dartDevArgParser, args);
  } on FormatException catch (e) {
    reporter.error('${e.message}');
    _help(reporter);
    exitCode = 1;
    return;
  }

  String taskName;
  if (parsedArgs.command != null) {
    taskName = parsedArgs.command.name;
  } else {
    _help(reporter);
    return;
  }

  // Display the version number if requestd.
  if (version) {
    if (!printVersion()) {
      reporter.error('Couldn\'t find version number.');
      exitCode = 1;
    }
    return;
  }

  // If a task is specified, ensure that it's valid.
  if (taskName != null && !_tasks.containsKey(taskName)) {
    reporter.error('Invalid task: $taskName');
    reporter.writeln();
    _help(reporter);
    exitCode = 1;
    return;
  }

  Task task = _tasks[taskName];

  // Display help text if requested.
  if (help) {
    if (taskName == null) {
      _help(reporter);
      return;
    } else {
      await task.help(config, reporter);
      return;
    }
  }

  // Run the task and exit accordingly.
  exitCode = await task.run(config, parsedArgs.command, reporter);
  reporter.writeln();
  if (exitCode == 0) {
    reporter.success('√  `ddev ${taskName}` completed successfully');
  } else {
    reporter.error('x  `ddev ${taskName}` failed (exit code $exitCode)');
  }
}

void _help(text.Reporter reporter) {
  reporter.writeln('Standardized tooling for Dart projects.');
  reporter.writeln();
  reporter.important('Usage: pub run dart_dev [task] [options]');
  reporter.writeln();
  reporter.h1('Command Line Options');
  reporter.indent();
  reporter.writeln();
  reporter.writeln(_dartDevArgParser.usage);
  reporter.writeln();
  reporter.dedent();

  reporter.h1('Available Tasks');
  reporter.writeln();
  reporter.indent();
  reporter.writeln(_tasks.keys.join('\n'));
  reporter.writeln();
  reporter.writeln('For more info: pub run dart_dev [task] --help');
  reporter.dedent();
}

void _registerTask(Task task) {
  _tasks[task.command] = task;
  _dartDevArgParser.addCommand(task.command, task.argParser);
}
