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

library dart_dev.src.tasks.gen_test_runner.config;

import 'package:dart_dev/src/tasks/config.dart';

const String defaultDirectory = 'test';
const Environment defaultEnv = Environment.browser;
const String defaultFilename = 'generated_runner';
const bool defaultGenHtml = false;
const bool defaultReact = true;
const List<String> defaultScriptTags = const [
  'packages/react/react_with_addons.js'
];

enum Environment { vm, browser }

class SingleRunnerConfig {
  String directory = defaultDirectory;
  Environment env = defaultEnv;
  String filename = defaultFilename;
  bool genHtml = defaultGenHtml;
  bool react = defaultReact;
  List<String> scriptTags = defaultScriptTags;

  SingleRunnerConfig(
      {String this.directory: defaultDirectory,
      Environment this.env: defaultEnv,
      String this.filename: defaultFilename,
      bool this.genHtml: defaultGenHtml,
      bool this.react: defaultReact,
      List<String> this.scriptTags: defaultScriptTags});
}

class GenTestRunnerConfig extends TaskConfig {
  List<SingleRunnerConfig> configs = [new SingleRunnerConfig()];
}
