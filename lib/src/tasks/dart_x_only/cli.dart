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

library dart_dev.src.tasks.dart1_only.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show TaskProcess, reporter;

import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/util.dart';

class Dart1OnlyCli extends DartXOnlyCli {
  @override
  final String command = 'dart1-only';

  Dart1OnlyCli(Iterable<String> availableTasks) : super(availableTasks);

  @override
  bool get shouldRun => dartMajorVersion == 1;
}

class Dart2OnlyCli extends DartXOnlyCli {
  @override
  final String command = 'dart2-only';

  Dart2OnlyCli(Iterable<String> availableTasks) : super(availableTasks);

  @override
  bool get shouldRun => dartMajorVersion == 2;
}

abstract class DartXOnlyCli extends TaskCli {
  @override
  final ArgParser argParser = new ArgParser();

  final Iterable<String> _availableTasks;

  bool get shouldRun;

  @override
  String get usage => '${super.usage} <task or executable> [args]';

  DartXOnlyCli(Iterable<String> availableTasks)
      : _availableTasks = availableTasks;

  @override
  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    if (parsedArgs.rest.isEmpty) {
      return new CliResult.fail('A task or executable is required.');
    }

    if (!shouldRun) {
      return new CliResult.success('Skipped (Dart $dartMajorVersion)');
    }

    final target = parsedArgs.rest.first;
    final targetArgs = parsedArgs.rest.sublist(1);

    String executable;
    List<String> args;
    if (_availableTasks.contains(target)) {
      executable = 'pub';
      args = <String>['run', 'dart_dev', target]..addAll(targetArgs);
    } else {
      executable = target;
      args = targetArgs;
    }

    final process = new TaskProcess(executable, args);
    reporter.logGroup('$executable ${args.join(' ')}',
        outputStream: process.stdout, errorStream: process.stderr);
    await process.done;
    return await process.exitCode == 0
        ? new CliResult.success()
        : new CliResult.fail();
  }
}
