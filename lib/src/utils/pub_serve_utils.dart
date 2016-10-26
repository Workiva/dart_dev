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

import 'package:dart_dev/src/utils/process_utils.dart';

class PubServeInfo {
  static final regExp =
      new RegExp(r'^Serving [^ ]+ +([^ ]+) +on http://localhost:(\d+)$');

  final int port;
  final String directory;

  PubServeInfo(String this.directory, int this.port);
}

class PubServe {
  /// Starts a Pub server on the specified [port] and returns the associated
  /// [PubServeTask].
  ///
  /// If [port] is 0, `pub serve` will pick its own port automatically.
  static PubServe start({int port: 0, List<String> additionalArgs}) {
    return new PubServe._(port: port, additionalArgs: additionalArgs);
  }

  String _command;
  ProcessHelper _process;
  StreamController<String> _pubServeStdErr = new StreamController();
  StreamController<String> _pubServeStdOut = new StreamController();
  final StreamController<PubServeInfo> _serveInfos =
      new StreamController<PubServeInfo>();

  PubServe._({int port: 0, List<String> additionalArgs}) {
    final executable = 'pub';
    final args = <String>['serve', '--port=${port ?? 0}'];
    if (additionalArgs != null) {
      args.addAll(additionalArgs);
    }

    _command = '$executable ${args.join(' ')}';
    _process = ProcessHelper.start(executable, args);

    _process.stdout.listen((line) {
      _pubServeStdOut.add(line);

      final match = PubServeInfo.regExp.firstMatch(line);
      if (match != null) {
        var directory = match[1];
        var port = int.parse(match[2]);
        _serveInfos.add(new PubServeInfo(directory, port));
      }
    });
    _process.stderr.listen(_pubServeStdErr.add);

    _process.done.then((_) {
      _serveInfos.close();
      _pubServeStdOut.close();
      _pubServeStdErr.close();
    });
  }

  String get command => _command;

  Future<Null> get done => _process.done;

  Stream<PubServeInfo> get onServe => _serveInfos.stream;

  Future<bool> kill() => _process.kill();

  Stream<String> get stdOut => _pubServeStdOut.stream;
  Stream<String> get stdErr => _pubServeStdErr.stream;
}
