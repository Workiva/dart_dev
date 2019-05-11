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

library dart_dev.src.task_process;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:dart2_constant/convert.dart' as convert;
import 'package:dart_dev/util.dart';

class TaskProcess {
  Completer _donec = new Completer();
  Completer _errc = new Completer();
  Completer _outc = new Completer();
  Completer<int> _procExitCode = new Completer();
  Process _process;

  StreamController<String> _stdout = new StreamController();
  StreamController<String> _stderr = new StreamController();

  TaskProcess(String executable, List<String> arguments,
      {String workingDirectory, Map<String, String> environment}) {
    Process.start(executable, arguments,
            workingDirectory: workingDirectory, environment: environment)
        .then((process) {
      _process = process;
      process.stdout
          .transform(convert.utf8.decoder)
          .transform(new LineSplitter())
          .listen(_stdout.add, onDone: _outc.complete);
      process.stderr
          .transform(convert.utf8.decoder)
          .transform(new LineSplitter())
          .listen(_stderr.add, onDone: _errc.complete);
      _outc.future.then((_) => _stdout.close());
      _errc.future.then((_) => _stderr.close());
      process.exitCode.then(_procExitCode.complete);
      Future.wait([_outc.future, _errc.future, process.exitCode])
          .then((_) => _donec.complete());
      _setUpSignalKillListeners(process, '$executable $arguments.join(' ')');
    });
  }

  Future get done => _donec.future;

  Future<int> get exitCode => _procExitCode.future;

  Stream<String> get stderr => _stderr.stream;
  Stream<String> get stdout => _stdout.stream;

  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) =>
      _process.kill(signal);

  /// __Deprecated__ Use [killAllDescendants] instead
  @Deprecated('3.0.0')
  Future<bool> killAllChildren(
          [ProcessSignal signal = ProcessSignal.SIGTERM]) async =>
      killAllDescendants(signal);

  bool killProcessAndAllDescendants(
      [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    // Take care to not short circuit via boolean operators or iteration here.
    // For example, `killA() && killB()` will not run `killB()`
    // if `killA()` returns false.
    final allDescendantsKilled = killAllDescendants();
    final killed = kill();
    return allDescendantsKilled && killed;
  }

  bool killAllDescendants([ProcessSignal signal = ProcessSignal.SIGTERM]) {
    var allKilled = true;
    for (var pid in _getAllDescendantPids()) {
      // Take care to not short circuit via boolean operators or iteration here.
      // For example, `killA() && killB()` will not run `killB()`
      // if `killA()` returns false.
      final killed = Process.killPid(pid, signal);
      if (!killed) {
        allKilled = false;
      }
    }
    return allKilled;
  }

  List<int> _getAllDescendantPids({List<int> pids}) {
    pids ??= [_process.pid];
    final descendantPids = <int>[];
    for (var pid in pids) {
      final result = Process.runSync('pgrep', ['-P', pid.toString()]);
      final outputLines = const LineSplitter().convert(result.stdout as String);
      descendantPids.addAll(outputLines.map(int.parse));
    }

    if (descendantPids.isNotEmpty) {
      descendantPids.addAll(_getAllDescendantPids(pids: descendantPids));
    }
    return descendantPids;
  }

  void _setUpSignalKillListeners(Process process, String description) {
    final listener = StreamGroup.merge([
      ProcessSignal.SIGINT.watch(),
      ProcessSignal.SIGTERM.watch(),
    ]).listen((signal) {
      reporter?.warning('Signal $signal received. '
          'Killing process `$description` and its children.');
      killProcessAndAllDescendants();
    });
    process.exitCode.then((_) => listener.cancel());
  }
}
