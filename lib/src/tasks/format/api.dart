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

import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

FormatTask format(
    {bool check: defaultCheck,
    List<String> directories: defaultDirectories,
    int lineLength: defaultLineLength}) {
  var executable = 'pub';
  var args = ['run', 'dart_style:format'];

  args.addAll(['-l', '$lineLength']);

  if (check) {
    args.add('-n');
  } else {
    args.add('-w');
  }

  args.addAll(directories);

  TaskProcess process = new TaskProcess(executable, args);
  FormatTask task = new FormatTask(
      '$executable ${args.join(' ')}', process.done)..isDryRun = check;

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

  return task;
}

class FormatTask extends Task {
  List<String> affectedFiles = [];
  final Future done;
  final String formatterCommand;
  bool isDryRun;
  List<String> unaffectedFiles = [];

  StreamController<String> _formatterOutput = new StreamController();

  FormatTask(String this.formatterCommand, Future this.done);

  Stream<String> get formatterOutput => _formatterOutput.stream;
}
