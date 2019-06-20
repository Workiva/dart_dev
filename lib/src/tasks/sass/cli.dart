// Copyright 2019 Workiva Inc.
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

library dart_dev.src.tasks.sass.cli;

import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_dev/util.dart' show reporter;
import 'package:w_common/sass.dart' as wc;

import 'package:dart_dev/src/tasks/sass/api.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

const String releaseArgName = 'release';
const String releaseArgAbbr = 'r';

class SassCli extends TaskCli {
  @override
  final ArgParser argParser = wc.sassCliArgs
    ..addSeparator('-' * 80)
    ..addFlag(releaseArgName,
        negatable: false,
        abbr: releaseArgAbbr,
        help:
            'Whether to compile minified CSS for bundling with a pub package. \n'
            'Typically only set during a CI run. \n'
            'A check of the unminified output will be performed first.');

  @override
  final String command = 'sass';

  @override
  String get usage =>
      '${super.usage} [.scss file(s)...] \n\n${argParser.usage}';

  @override
  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    bool help = TaskCli.valueOf('help', parsedArgs, false);
    if (help) {
      print(usage);
      return new CliResult.success();
    }

    String sourceDir =
        TaskCli.valueOf(wc.sourceDirArg, parsedArgs, config.sass.sourceDir);
    String outputDir = TaskCli.valueOf(
        wc.outputDirArg, parsedArgs, config.sass.outputDir ?? sourceDir);
    List<String> watchDirs =
        TaskCli.valueOf(wc.watchDirsArg, parsedArgs, config.sass.watchDirs);
    bool release =
        TaskCli.valueOf(releaseArgName, parsedArgs, config.sass.release);

    if (release && !parsedArgs['help']) {
      // If running in "release mode", we want to first run a check on the committed (unminified) CSS output
      // and then immediately run it again to generate a minified copy using the same .scss sources to be
      // tar'd up for pub package assets in CI
      SassTask checkTask = sass(
        sourceDir: sourceDir,
        outputDir: outputDir,
        watchDirs: watchDirs,
        release: false,
        preReleaseCheck: true,
        parsedArgs: parsedArgs,
      );
      if (checkTask.sassCommand != null) {
        reporter.logGroup(checkTask.sassCommand,
            outputStream: checkTask.sassOutput);
      }
      await checkTask.done;

      if (!checkTask.successful) return new CliResult.fail();
    }

    SassTask task = sass(
      sourceDir: sourceDir,
      outputDir: outputDir,
      watchDirs: watchDirs,
      release: release,
      parsedArgs: parsedArgs,
    );
    if (task.sassCommand != null) {
      reporter.logGroup(task.sassCommand, outputStream: task.sassOutput);
    }
    await task.done;

    if (!task.successful) return new CliResult.fail('Sass compilation failed.');

    return new CliResult.success('Sass compilation completed successfully');
  }
}
