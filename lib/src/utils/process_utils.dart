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
import 'dart:convert';
import 'dart:io';

class ProcessHelper {
  static ProcessHelper start(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      ProcessStartMode mode: ProcessStartMode.NORMAL}) {
    final processFuture = Process.start(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        mode: mode);
    return new ProcessHelper._(processFuture);
  }

  Completer _donec = new Completer();
  Completer _errc = new Completer();
  Completer _outc = new Completer();
  Completer<int> _procExitCode = new Completer();
  Process _process;
  Future<Process> _processFuture;

  StreamController<String> _stdout = new StreamController();
  StreamController<String> _stderr = new StreamController();

  ProcessHelper._(Future<Process> processFuture)
      : _processFuture = processFuture {
    processFuture.then((process) {
      _process = process;

      _process.stdout
          .transform(UTF8.decoder)
          .transform(new LineSplitter())
          .listen(_stdout.add, onDone: _outc.complete);
      _process.stderr
          .transform(UTF8.decoder)
          .transform(new LineSplitter())
          .listen(_stderr.add, onDone: _errc.complete);
      _outc.future.then((_) => _stdout.close());
      _errc.future.then((_) => _stderr.close());
      _process.exitCode.then(_procExitCode.complete);
      Future.wait([_outc.future, _errc.future, process.exitCode]).then(
          (_) => _donec.complete());
    });
  }

  Future get done => _donec.future;

  Future<int> get exitCode => _procExitCode.future;

  Stream<String> get stderr => _stderr.stream;

  Stream<String> get stdout => _stdout.stream;

  Future<bool> kill() async {
    await _processFuture;
    return _process.kill();
    // TODO: kill child processes
  }
}
