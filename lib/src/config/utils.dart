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

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:dart_dev/src/config/dart_dev_config.dart';

DartDevConfig loadDartDevConfig() {
  Map dartDevYaml = {};
  if (FileSystemEntity.isFileSync('dart_dev.yaml')) {
    final dartDevYamlFile = new File('dart_dev.yaml');
    YamlNode yamlNode;
    try {
      yamlNode = loadYaml(dartDevYamlFile.readAsStringSync());
    } on YamlException catch (e) {
      throw new FormatException('Failed to parse dart_dev.yaml:\n\n$e');
    }

    if (yamlNode is YamlMap) {
      dartDevYaml = yamlNode;
    } else {
      throw new FormatException('Invalid dart_dev.yaml.');
    }
  }

  Map analysisOptionsYaml = {};
  File analysisOptionsFile;
  if (FileSystemEntity.isFileSync('analysis_options.yaml')) {
    analysisOptionsFile = new File('analysis_options.yaml');
  } else if (FileSystemEntity.isFileSync('.analysis_options')) {
    analysisOptionsFile = new File('.analysis_options');
  }
  if (analysisOptionsFile != null) {
    final yamlNode = loadYaml(analysisOptionsFile.readAsStringSync());
    if (yamlNode is YamlMap) {
      analysisOptionsYaml = yamlNode;
    }
  }

  Map dartTestYaml = {};
  if (FileSystemEntity.isFileSync('dart_test.yaml')) {
    final dartTestYamlFile = new File('dart_test.yaml');
    final yamlNode = loadYaml(dartTestYamlFile.readAsStringSync());
    if (yamlNode is YamlMap) {
      dartTestYaml = yamlNode;
    }
  }

  return DartDevConfig.parse(dartDevYaml, analysisOptionsYaml, dartTestYaml);
}
