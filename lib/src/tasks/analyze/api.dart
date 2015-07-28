library dart_dev.src.tasks.analyze.api;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/process.dart';

import 'package:dart_dev/src/tasks/analyze/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

AnalyzeTask analyze(
    {List<String> entryPoints: defaultEntryPoints,
    bool fatalWarnings: defaultFatalWarnings,
    bool hints: defaultHints}) {
  var executable = 'dartanalyzer';
  var args = [];
  if (fatalWarnings) {
    args.add('--fatal-warnings');
  }
  if (!hints) {
    args.add('--no-hints');
  }
  args.addAll(_findFilesFromEntryPoints(entryPoints));

  TaskProcess process = new TaskProcess(executable, args);
  AnalyzeTask task =
      new AnalyzeTask('$executable ${args.join(' ')}', process.done);

  process.stdout.listen(task._analyzerOutput.add);
  process.stderr.listen(task._analyzerOutput.addError);
  process.exitCode.then((code) {
    task.successful = code <= 0;
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

  StreamController<String> _analyzerOutput = new StreamController();
  Stream<String> get analyzerOutput => _analyzerOutput.stream;
  AnalyzeTask(String this.analyzerCommand, Future this.done);
}
