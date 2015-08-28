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

library dart_dev.src.tasks.config;

import 'package:dart_dev/src/tasks/analyze/config.dart';
import 'package:dart_dev/src/tasks/copy_license/config.dart';
import 'package:dart_dev/src/tasks/coverage/config.dart';
import 'package:dart_dev/src/tasks/docs/config.dart';
import 'package:dart_dev/src/tasks/examples/config.dart';
import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/init/config.dart';
import 'package:dart_dev/src/tasks/test/config.dart';

Config config = new Config();

class Config {
  AnalyzeConfig analyze = new AnalyzeConfig();
  CopyLicenseConfig copyLicense = new CopyLicenseConfig();
  CoverageConfig coverage = new CoverageConfig();
  DocsConfig docs = new DocsConfig();
  ExamplesConfig examples = new ExamplesConfig();
  FormatConfig format = new FormatConfig();
  InitConfig init = new InitConfig();
  TestConfig test = new TestConfig();
}

class TaskConfig {
  List after = [];
  List before = [];
}
