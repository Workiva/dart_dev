// Copyright 2016 Workiva Inc.
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

library dart_dev.src.tasks.local.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

import 'package:dart_dev/util.dart' show reporter;
import 'package:dart_dev/src/tasks/config.dart';

import 'package:dart_dev/src/tasks/local/api.dart';
import 'package:dart_dev/src/tasks/cli.dart';

class Executable {
  final String path;
  final String extension;
  final String name;

  Executable(this.path, this.name, this.extension);
}

typedef Executable CommandParser(FileSystemEntity entity);
typedef bool CommandPatternMatcher(FileSystemEntity entity);

CommandParser _commandParser(String pattern) => (entity) {
      var matches = new RegExp(pattern).firstMatch(basename(entity.path));
      return new Executable(entity.path, matches.group(1), matches.group(2));
    };

CommandPatternMatcher _commandPatternMatcher(String pattern) =>
    (entity) => new RegExp(pattern).hasMatch(basename(entity.path));

class LocalCli extends TaskCli {
  @override
  final ArgParser argParser = new ArgParser();
  @override
  final String command;
  final Executable executable;
  final List<String> originalArgs;

  static Map<String, Executable> discover(List<String> paths) {
    final commandFiles = paths
        .map((path) => new Directory(path))
        .where((directory) => directory.existsSync())
        .expand((directory) => directory.listSync(
            recursive: true, followLinks: config.local.followSymlinks))
        .where(_commandPatternMatcher(config.local.commandFilePattern));

    return commandFiles
        .map(_commandParser(config.local.commandFilePattern))
        .fold({}, (m, c) {
      m[c.name] = c;
      return m;
    });
  }

  LocalCli(this.command, this.executable, {List<String> this.originalArgs});

  @override
  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    var executableParams = config.local.executables[executable.extension];

    if (executableParams == null) {
      var failedExecutableLookup =
          'An executable was not defined for the discovered task '
          '${executable.name}.\n\nPlease provide an updated local configuration '
          'which defines what executable to use for the '
          '"${executable.extension}" file extension.';

      return new CliResult.fail(failedExecutableLookup);
    }

    LocalTask task = local(
        '${executableParams.first}',
        executableParams.sublist(1)
          ..add(executable.path)
          ..addAll(this.originalArgs.sublist(1) ?? parsedArgs.arguments));

    var title = task.localCommand;

    reporter.logGroup(title, outputStream: task.localOutput);

    await task.done;
    return task.successful
        ? new CliResult.success('${task.localCommand} completed.')
        : new CliResult.fail('${task.localCommand} failed.');
  }
}
