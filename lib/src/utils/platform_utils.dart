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
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:dart_dev/src/utils/process_utils.dart';

/// Checks if an [executable] exists and is in the current path via `which`.
Future<bool> executableExists(String executable) async {
  final checkProcess = ProcessHelper.start('which', [executable]);
  return (await checkProcess.exitCode) == 0;
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

/// Determines whether or not the project in the current working directory has
/// defined [packageName] as an immediate dependency. In other words, this
/// checks if [packageName] is in the project's pubspec.yaml.
bool hasImmediateDependency(String packageName) {
  final pubspec = new File('pubspec.yaml');
  final pubspecYaml = loadYaml(pubspec.readAsStringSync());
  if (pubspecYaml is! YamlMap) return false;

  List deps = [];
  if (pubspecYaml.containsKey('dependencies')) {
    final dependencies = pubspecYaml['dependencies'];
    if (dependencies is YamlMap) {
      deps.addAll(dependencies.keys);
    }
  }
  if (pubspecYaml.containsKey('dev_dependencies')) {
    final devDependencies = pubspecYaml['dev_dependencies'];
    if (devDependencies is YamlMap) {
      deps.addAll(devDependencies.keys);
    }
  }
  return deps.contains(packageName);
}

/// Determines whether or not [executable] is installed on this platform.
Future<bool> isExecutableInstalled(String executable) async {
  ProcessResult result = await Process.run('which', [executable]);
  return result.exitCode == 0;
}
