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

library dart_dev.src.tasks.local.api;

import 'dart:async';

import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

LocalTask local(String executable, Iterable<String> args) {
  TaskProcess process = new TaskProcess(executable, args, environment: {
    // Make a serialized version of the config available to this task.
    'dart_dev_config': serializeConfig(),
  });

  LocalTask task = new LocalTask('$executable ${args.join(' ')}',
      Future.wait([process.done]).then((_) => null));

  process.stdout.listen(task._commandOutput.add);
  process.stderr.listen(task._commandOutput.addError);
  process.exitCode.then((code) {
    if (task.successful == null) {
      task.successful = code == 0;
    }
  });

  return task;
}

class LocalTask extends Task {
  @override
  final Future<Null> done;
  final String localCommand;

  StreamController<String> _commandOutput = new StreamController();

  LocalTask(String this.localCommand, this.done);

  Stream<String> get localOutput => _commandOutput.stream;
}
