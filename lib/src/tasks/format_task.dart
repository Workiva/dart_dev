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
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import 'package:dart_dev/src/config/dart_dev_config.dart';
import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/utils/platform_utils.dart' as platform;
import 'package:dart_dev/src/utils/process_utils.dart';
import 'package:dart_dev/src/utils/text_utils.dart' as text;

class FormatTask extends Task {
  @override
  final ArgParser argParser = null;

  @override
  final String command = 'format';

  @override
  Future<Null> help(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) async {
    reporter.important(
        'Usage: pub run dart_dev format [-n|-w] [files or directories...]');
    reporter.writeln();
    reporter.writeln('The dart_dev format task proxies dartfmt.');
    reporter.writeln();

    _packageConfig(config, reporter, verbose: verbose);

    reporter.h1('Command Line Options (dartfmt)');
    reporter.writeln();
    reporter.indent();
    reporter.writeln(await _getDartfmtHelp());
    reporter.dedent();
  }

  @override
  Future<int> run(DartDevConfig config, LenientArgResults parsedArgs,
      text.Reporter reporter) async {
    _packageConfig(config, reporter);

    if (!(await platform.hasImmediateDependency('dartdoc'))) {
      reporter.writeln();
      reporter.error('Package "dart_style" must be an immediate dependency in '
          'order to run its executables.');
      reporter.error('Please add "dart_style" to your pubspec.yaml.');
      reporter.dedent();
      return 1;
    }

    reporter.h1('Running Formatter');
    reporter.indent();

    final List<Glob> includeGlobs = [];
    if (config.format.includes.isNotEmpty) {
      includeGlobs
          .addAll(config.format.includes.map((pattern) => new Glob(pattern)));
    } else {
      includeGlobs.add(new Glob('lib/'));
    }

    final List<Glob> excludeGlobs = [];
    if (config.format.excludes.isNotEmpty) {
      excludeGlobs
          .addAll(config.format.excludes.map((pattern) => new Glob(pattern)));
    }

    // TODO: expand dirs to all files minus excludes (only way to do this since foramtter doesn't support excluding)
    /*

      // Build the list of files by expanding the given directories, looking for
      // all .dart files that don't match any excluded path.
      List<String> filesToFormat = [];
      for (var p in directories) {
        Directory dir = new Directory(p);
        var files = dir.listSync(recursive: true);
        for (FileSystemEntity entity in files) {
          // Skip directories and links.
          if (!FileSystemEntity.isFileSync(entity.path)) continue;
          // Skip non-dart files.
          if (!entity.path.endsWith('.dart')) continue;
          // Skip dependency files.
          if (entity.absolute.path.contains('/packages/')) continue;

          // Skip excluded files.
          bool isExcluded = false;
          for (var excluded in exclude) {
            if (entity.absolute.path.startsWith(excluded)) {
              isExcluded = true;
              break;
            }
          }
          if (isExcluded) {
            excludedFiles.add(entity.path);
            continue;
          }

          // File should be formatted.
          filesToFormat.add(entity.path);
        }
      }

     */

    final filesAndDirectories = <String>[];
    for (final includeGlob in includeGlobs) {
      for (final entity in includeGlob.listSync()) {
        for (final excludeGlob in excludeGlobs) {
          if (excludeGlob.matches(entity.path)) continue;
        }
        filesAndDirectories.add(entity.path);
      }
    }

    final executable = 'pub';
    final args = <String>['run', 'dart_style:format'];

    // Forward all flags & options to the dartanalyzer exectuable.
    args.addAll(parsedArgs.unknownOptions);

    bool isDryRun = parsedArgs.unknownOptions.contains('-n') ||
        parsedArgs.unknownOptions.contains('--dry-run');

    final isDryRunOrOverwriteSelected =
        parsedArgs.unknownOptions.contains('-n') ||
            parsedArgs.unknownOptions.contains('--dry-run') ||
            parsedArgs.unknownOptions.contains('-w') ||
            parsedArgs.unknownOptions.contains('--overwrite');

    // Default to doing a dry-run instead of the default dartfmt behavior of
    // dumping all changes to stdout.
    if (!isDryRunOrOverwriteSelected) {
      args.add('--dry-run');
      isDryRun = true;
    }

    if (parsedArgs.rest.isNotEmpty) {
      // If files/directories are explicitly passed in (as args), format them.
      args.addAll(parsedArgs.rest);
    } else {
      // Otherwise, format the configured files/directories.
      args.addAll(filesAndDirectories);
    }

    reporter.important('command: $executable ${args.join(' ')}');
    reporter.writeln();

    final process = ProcessHelper.start(executable, args);
    final affectedFiles = <String>[];
    final unaffectedFiles = <String>[];

    final cwdPattern = new RegExp('Formatting directory (.+):');
    final formattedPattern = new RegExp('Formatted (.+\.dart)');
    final unchangedPattern = new RegExp('Unchanged (.+\.dart)');

    String cwd = '';
    process.stdout.listen((line) {
      if (isDryRun) {
        final filePath = line.trim();
        affectedFiles.add(filePath);
        reporter.writeln('x  $filePath');
      } else {
        if (cwdPattern.hasMatch(line)) {
          cwd = cwdPattern.firstMatch(line).group(1);
        } else {
          if (formattedPattern.hasMatch(line)) {
            final filePath =
                path.join(cwd, formattedPattern.firstMatch(line).group(1));
            affectedFiles.add(filePath);
            reporter.writeln('√  $filePath');
          } else if (unchangedPattern.hasMatch(line)) {
            unaffectedFiles
                .add('$cwd${unchangedPattern.firstMatch(line).group(1)}');
          }
        }
      }
    });

    await process.done;

    int exitCode;
    if (isDryRun) {
      if (affectedFiles.isEmpty) {
        exitCode = 0;
        reporter.success('Your Dart code is good to go!');
      } else {
        exitCode = 1;
        reporter.writeln();
        reporter.error('${affectedFiles.length} files need to be formatted.');
      }
    } else {
      exitCode = 0;
      if (affectedFiles.isEmpty) {
        reporter.success(
            'All ${unaffectedFiles.length} files are already formatted.');
      } else {
        reporter.writeln();
        reporter.success('Formatted ${affectedFiles.length} files.');
      }
    }

    reporter.dedent();
    return exitCode;
  }

  Future<String> _getDartfmtHelp() {
    final process =
        ProcessHelper.start('pub', ['run', 'dart_style:format', '--help']);
    return process.stdout.join('\n');
  }

  void _packageConfig(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) {
    reporter.h1('Package Configuration');
    reporter.writeln();
    reporter.indent();
    reporter.h2('Files/Directories to be Formatted (from dart_dev.yaml)');
    if (config.format.includes == null || config.format.includes.isEmpty) {
      reporter.writeln('[none specified]');
    } else {
      for (final include in config.format.includes) {
        reporter.writeln('- $include');
      }
    }
    reporter.writeln();

    if (config.format.excludes.isNotEmpty) {
      reporter.h2('Excluded Files/Directories (from dart_dev.yaml)');
      for (final exclude in config.format.excludes) {
        reporter.writeln('- $exclude');
      }
      reporter.writeln();
    }

    if (config.format.lineLength != null) {
      reporter.h2('Other options (from dart_dev.yaml)');
      reporter.writeln('- Line-length: ${config.format.lineLength}');
      reporter.writeln();
    }

    reporter.dedent();
  }
}
