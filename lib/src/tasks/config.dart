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
import 'package:dart_dev/src/tasks/bash_completion/config.dart';
import 'package:dart_dev/src/tasks/copy_license/config.dart';
import 'package:dart_dev/src/tasks/coverage/config.dart';
import 'package:dart_dev/src/tasks/docs/config.dart';
import 'package:dart_dev/src/tasks/examples/config.dart';
import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/gen_test_runner/config.dart';
import 'package:dart_dev/src/tasks/init/config.dart';
import 'package:dart_dev/src/tasks/saucelabs/config.dart';
import 'package:dart_dev/src/tasks/task_runner/config.dart';
import 'package:dart_dev/src/tasks/test/config.dart';
import 'package:dart_dev/src/tasks/local/config.dart';

Config config = new Config();

class Config {
  AnalyzeConfig analyze = new AnalyzeConfig();
  BashCompletionConfig bashCompletion = new BashCompletionConfig();
  CopyLicenseConfig copyLicense = new CopyLicenseConfig();
  CoverageConfig coverage = new CoverageConfig();

  /// Deprecated: 1.10.0
  /// To be removed: 2.0.0
  /// Use the `dartdoc` executable instead.
  @deprecated
  DocsConfig docs = new DocsConfig();

  /// Deprecated 1.10.0
  /// To be removed: 2.0.0
  /// Use `pub serve example` or `pub run build_runner serve example:8080`
  /// instead.
  @deprecated
  ExamplesConfig examples = new ExamplesConfig();

  LocalConfig local = new LocalConfig();
  FormatConfig format = new FormatConfig();
  GenTestRunnerConfig genTestRunner = new GenTestRunnerConfig();
  InitConfig init = new InitConfig();

  /// Deprecated 1.10.0
  /// To be removed: 2.0.0
  @deprecated
  SaucelabsConfig saucelabs = new SaucelabsConfig();

  TaskRunnerConfig taskRunner = new TaskRunnerConfig();
  TestConfig test = new TestConfig();

  Map<String, dynamic> toJson() => {
        'analyze': analyze,
        'bashCompletion': bashCompletion,
        'copyLicense': copyLicense,
        'coverage': coverage,
        // ignore: deprecated_member_use
        'docs': docs,
        // ignore: deprecated_member_use
        'examples': examples,
        'local': local,
        'format': format,
        'genTestRunner': genTestRunner,
        'init': init,
        // ignore: deprecated_member_use
        'saucelabs': saucelabs,
        'taskRunner': taskRunner,
        'test': test,
      };
}

class TaskConfig {
  List after = [];
  List before = [];
}
