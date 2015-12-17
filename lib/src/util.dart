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

library dart_dev.src.util;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/coverage/exceptions.dart';
import 'package:dart_dev/src/tasks/coverage/config.dart';

void copyDirectory(Directory source, Directory dest) {
  if (!dest.existsSync()) {
    dest.createSync(recursive: true);
  }

  source.listSync(recursive: true).forEach((entity) {
    if (FileSystemEntity.isDirectorySync(entity.path)) {
      Directory orig = entity;
      String p = path.relative(orig.path, from: source.path);
      p = path.join(dest.path, p);
      Directory copy = new Directory(p);
      if (!copy.existsSync()) {
        copy.createSync(recursive: true);
      }
    } else if (FileSystemEntity.isFileSync(entity.path)) {
      File orig = entity;
      String p = path.relative(orig.path, from: source.path);
      p = path.join(dest.path, p);
      File copy = new File(p);
      copy.createSync(recursive: true);
      copy.writeAsBytesSync(orig.readAsBytesSync());
    }
  });
}

/// Returns an open port by creating a temporary Socket.
/// Borrowed from coverage package https://github.com/dart-lang/coverage/blob/master/lib/src/util.dart#L49-L66
Future<int> getOpenPort() async {
  ServerSocket socket;

  try {
    socket = await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  } catch (_) {
    // try again v/ V6 only. Slight possibility that V4 is disabled
    socket = await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V6, 0,
        v6Only: true);
  }

  try {
    return socket.port;
  } finally {
    await socket.close();
  }
}

String parseExecutableFromCommand(String command) {
  return command.split(' ').first;
}

List<String> parseArgsFromCommand(String command) {
  var parts = command.split(' ');
  if (parts.length <= 1) return [];
  return parts.getRange(1, parts.length).toList();
}

class SeleniumServer {
  TaskProcess _server;
  Completer isDone;
  List<int> observatoryPort;
  List<Future> checkPortDone;
  SeleniumServer(
      {String executable: defaultSeleniumCommand,
      List args: const [],
      bool coverage: false}) {
    observatoryPort = new List<int>();
    checkPortDone = new List<Future>();
    RegExp _observatoryPortPattern = new RegExp(
        r'Observatory listening (at|on) http:\/\/127\.0\.0\.1:(\d+)');
    _server = new TaskProcess(executable, args);
    isDone = new Completer();
    _server.stderr.listen((line) async {
//      _coverageErrorOutput.add('    $line');
      if (coverage && line.contains(_observatoryPortPattern)) {
        Match m = _observatoryPortPattern.firstMatch(line);
        observatoryPort.add(int.parse(m.group(2)));
      } else if (line.contains("Failed to start")) {
        await _server.kill();
        throw new PortBoundException(
            "${config.coverage.seleniumCommand} failed to start.  Check if this process is already running.");
      } else if (line.contains(config.coverage.seleniumSuccess)) {
        isDone.complete();
      }
    });
  }
  Future<List<int>> checkPorts() async {
    List<int> validPorts = new List<int>();
    for (int i = 0; i < observatoryPort.length; i++) {
      int port = observatoryPort[i];
      try {
        WebSocket ws = await WebSocket.connect("ws://127.0.0.1:${port}/ws");
        checkPortDone.add(ws.done);
        ws.add("{\"id\":\"3\",\"method\":\"getVM\",\"params\":{}}");
        ws.listen((l) {
          var json = JSON.decode(l);
          List isolates = (json["result"])["isolates"];
          if (isolates != null && isolates.isNotEmpty) {
            validPorts.add(port);
          }
          ws.close();
        });
      } on Exception {}
    }
    for (int i = 0; i < checkPortDone.length; i++) {
      await checkPortDone[i];
    }
    return validPorts;
  }

  Future closeTests() async {
    await _server.killGroup();
    observatoryPort.clear();
    checkPortDone.clear();
  }

  Future kill() async {
    await _server.kill();
  }
}
