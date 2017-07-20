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

library dart_dev.src.tasks.format.api;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

// ignore: deprecated_member_use
/// [directories] is deprecated; use [paths] instead.
FormatTask format({
  bool check: defaultCheck,
  List<String> exclude: defaultExclude,
  int lineLength: defaultLineLength,
  List<String> paths: defaultPaths,
  @Deprecated('2.0.0') List<String> directories,
}) {
  // ignore: deprecated_member_use
  if (directories != null) paths = directories;

  var executable = 'pub';
  var args = ['run', 'dart_style:format'];

  args.addAll(['-l', '$lineLength']);

  if (check) {
    args.add('-n');
  } else {
    args.add('-w');
  }

  var filesToFormat = getFilesToFormat(paths: paths, exclude: exclude);

  FormatTask task;
  if (filesToFormat.files.isEmpty) {
    task = new FormatTask(null, new Future(() {}))..successful = true;
  } else {
    args.addAll(filesToFormat.files);

    TaskProcess process = new TaskProcess(executable, args);
    task = new FormatTask('$executable ${args.join(' ')}', process.done);

    RegExp cwdPattern = new RegExp('Formatting directory (.+):');
    RegExp formattedPattern = new RegExp('Formatted (.+\.dart)');
    RegExp unchangedPattern = new RegExp('Unchanged (.+\.dart)');

    String cwd = '';
    process.stdout.listen((line) {
      if (check) {
        task.affectedFiles.add(line.trim());
      } else {
        if (cwdPattern.hasMatch(line)) {
          cwd = cwdPattern.firstMatch(line).group(1);
        } else if (formattedPattern.hasMatch(line)) {
          task.affectedFiles
              .add('$cwd${formattedPattern.firstMatch(line).group(1)}');
        } else if (unchangedPattern.hasMatch(line)) {
          task.unaffectedFiles
              .add('$cwd${unchangedPattern.firstMatch(line).group(1)}');
        }
      }
      task._formatterOutput.add(line);
    });
    process.stderr.listen(task._formatterOutput.addError);
    process.exitCode.then((code) {
      task.successful = check ? task.affectedFiles.isEmpty : code <= 0;
    });
  }

  task
    ..isDryRun = check
    ..excludedFiles.addAll(filesToFormat.excluded);

  return task;
}

/// Returns a set of files within [paths] to be formatted, with [exclude] excluded.
///
/// [paths] can contain both files and directories. Files within directories
/// will be processed recursively, ignoring symlinks.
///
/// If [exclude] is not empty, the return value will include [paths], expanded
/// to all matching files. Otherwise, it will not be expanded.
///
/// To force expansion, set [alwaysExpand] to `true`.
FilesToFormat getFilesToFormat({
  List<String> paths: defaultPaths,
  List<String> exclude: defaultExclude,
  bool alwaysExpand: false,
}) {
  var filesToFormat = new FilesToFormat();

  if (exclude.isEmpty && !alwaysExpand) {
    // If no files are excluded, we can use the paths and let the dart
    // formatter expand the files.
    filesToFormat.files.addAll(paths);
  } else {
    // Convert paths to relative paths, so they can be efficiently
    // compared to the files we're listing.
    paths = paths.map(path.relative).toList();
    exclude = exclude.map(path.relative).toList();

    // Build the list of files by expanding the given paths, looking for
    // all .dart files that don't match any excluded path.
    for (var p in paths) {
      List<FileSystemEntity> files = FileSystemEntity.isFileSync(p)
          ? [new File(p)]
          : new Directory(p).listSync(recursive: true, followLinks: false);

      for (FileSystemEntity entity in files) {
        // Skip directories and links.
        if (entity is! File) continue;
        // Skip non-dart files.
        if (!entity.path.endsWith('.dart')) continue;

        var pathParts = path.split(entity.path);
        // Skip dependency files.
        if (pathParts.contains('packages')) continue;
        // Skip contents of .pub directories.
        if (pathParts.contains('.pub')) continue;

        // Skip excluded files.
        bool isExcluded = exclude.any((excluded) =>
            entity.path == excluded || path.isWithin(excluded, entity.path));

        if (isExcluded) {
          filesToFormat.excluded.add(entity.path);
          continue;
        }

        // File should be formatted.
        filesToFormat.files.add(entity.path);
      }
    }
  }

  return filesToFormat;
}

/// Data around included/excluded files, returned [getFilesToFormat].
class FilesToFormat {
  /// Matching/included that should be formatted.
  List<String> files = [];

  /// Excluded files that should not be formatted.
  List<String> excluded = [];
}

class FormatTask extends Task {
  List<String> affectedFiles = [];
  List<String> excludedFiles = [];
  final Future<TaskResult> done;
  final String formatterCommand;
  bool isDryRun;
  List<String> unaffectedFiles = [];

  StreamController<String> _formatterOutput = new StreamController();

  FormatTask(String this.formatterCommand, Future<TaskResult> this.done) {
    done.whenComplete(() => _formatterOutput.close());
  }

  Stream<String> get formatterOutput => _formatterOutput.stream;
}
