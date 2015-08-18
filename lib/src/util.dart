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

import 'dart:io';

import 'package:yaml/yaml.dart';

bool hasImmediateDependency(String packageName) {
  File pubspec = new File('pubspec.yaml');
  Map pubspecYaml = loadYaml(pubspec.readAsStringSync());
  List deps = [];
  if (pubspecYaml.containsKey('dependencies')) {
    deps.addAll((pubspecYaml['dependencies'] as Map).keys);
  }
  if (pubspecYaml.containsKey('dev_dependencies')) {
    deps.addAll((pubspecYaml['dev_dependencies'] as Map).keys);
  }
  return deps.contains(packageName);
}

String parseExecutableFromCommand(String command) {
  return command.split(' ').first;
}

List<String> parseArgsFromCommand(String command) {
  var parts = command.split(' ');
  if (parts.length <= 1) return [];
  return parts.getRange(1, parts.length).toList();
}
