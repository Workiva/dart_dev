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

library dart_dev.src.tasks.unlink_dependency.api;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/src/constants.dart';
import 'package:dart_dev/src/tasks/task.dart';

class UnlinkDependencyResult extends TaskResult {
  UnlinkDependencyResult() : super.success();
}

class UnlinkDependencyFailure implements Exception {}

class UnlinkDependencyTask extends Task {
  static Future<UnlinkDependencyTask> start() async {
    UnlinkDependencyTask task = new UnlinkDependencyTask._();
    task._run();
    return task;
  }

  static Future<UnlinkDependencyResult> run() async {
    UnlinkDependencyTask task = new UnlinkDependencyTask._();
    return task._run();
  }

  Stream<String> _dartdocStderr;
  Stream<String> _dartdocStdout;
  String _pubCommand;

  Completer<UnlinkDependencyResult> _done = new Completer();

  UnlinkDependencyTask._();

  Future<UnlinkDependencyResult> get done => _done.future;
  Stream<String> get errorOutput => _dartdocStderr;
  Stream<String> get output => _dartdocStdout;
  String get pubCommand => _pubCommand;

  Future<UnlinkDependencyResult> _run() async {
    var pubspecLines = new File('pubspec.yaml').readAsLinesSync();
    var pubspecFile = new File('pubspec.yaml').openSync(mode: FileMode.WRITE);

    bool insideLinkBlock = false;
    pubspecLines.forEach((line) {
      if (line.startsWith(linkStartFence)) {
        insideLinkBlock = true;
      }
      if (line.startsWith(linkEndFence)) {
        insideLinkBlock = false;
        return;
      }
      if (insideLinkBlock) {
        return;
      }
      pubspecFile.writeStringSync('$line\n');
    });

    _done.complete(new UnlinkDependencyResult());
    return _done.future;
  }
}
