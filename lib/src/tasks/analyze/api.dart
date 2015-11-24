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

library dart_dev.src.tasks.analyze.api;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/analyze/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

AnalyzeTask analyze(
    {List<String> entryPoints: defaultEntryPoints,
    bool fatalWarnings: defaultFatalWarnings,
    bool hints: defaultHints,
    bool fatalHints: defaultFatalHints}) {
  var executable = 'dartanalyzer';
  var args = [];
  if (fatalWarnings) {
    args.add('--fatal-warnings');
  }
  if (!hints) {
    args.add('--no-hints');
  }
  args.addAll(_findFilesFromEntryPoints(entryPoints));

  var postProcessCompleter = new Completer();
  TaskProcess process = new TaskProcess(executable, args);
  AnalyzeTask task = new AnalyzeTask(
      '$executable ${args.join(' ')}', postProcessCompleter.future);

  var matchingLineFuture = task.analyzerOutput
      .firstWhere((line) => line.contains('[hint] '), defaultValue: () => null);

  var stdoutDone = process.stdout.listen(task._analyzerOutput.add).asFuture();
  var stderrDone = process.stderr.listen(task._analyzerOutput.add).asFuture();
  Future.wait([stdoutDone, stderrDone])
      .then((_) => task._analyzerOutput.close());

  matchingLineFuture.then((matchingLine) {
    process.exitCode.then((exitCode) async {
      if (exitCode > 0) {
        task.successful = false;
      } else if (fatalHints) {
        task.successful = matchingLine == null;
      } else {
        task.successful = true;
      }
      postProcessCompleter.complete();
    });
  });

  return task;
}

List<String> _findFilesFromEntryPoints(List<String> entryPoints) {
  List<String> files = [];
  entryPoints.forEach((p) {
    if (FileSystemEntity.isDirectorySync(p)) {
      Directory dir = new Directory(p);
      List<FileSystemEntity> entities = dir.listSync();
      files.addAll(entities
          .where((e) =>
              FileSystemEntity.isFileSync(e.path) && e.path.endsWith('.dart'))
          .map((e) => e.path));
    } else if (FileSystemEntity.isFileSync(p) && p.endsWith('.dart')) {
      files.add(p);
    } else {
      throw new ArgumentError('Entry point does not exist: $p');
    }
  });
  return files;
}

class AnalyzeTask extends Task {
  final String analyzerCommand;
  final Future done;

  StreamController<String> _analyzerOutput = new StreamController.broadcast();
  Stream<String> get analyzerOutput => _analyzerOutput.stream;
  AnalyzeTask(String this.analyzerCommand, Future this.done);
}
