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
