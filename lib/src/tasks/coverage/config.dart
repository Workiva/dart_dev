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

library dart_dev.src.tasks.coverage.config;

import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/test/config.dart';

const List defaultAfterFunctional = const [];
const List defaultBeforeFunctional = const [];
const bool defaultHtml = true;
const String defaultOutput = 'coverage/';
const List<String> defaultReportOn = const ['lib/'];

class CoverageConfig extends TaskConfig {
  List afterFunctionalTests = defaultAfterFunctional;
  List beforeFunctionalTests = defaultBeforeFunctional;
  
  /// Enable or disable HTML generation.
  /// Defaults to true.
  bool html = defaultHtml;
  
  /// Output directory for coverage artifacts.
  /// Defaults to 'coverage/'.
  String output = defaultOutput;
  
  /// Whether or not to serve browser tests using a Pub server.
  /// If true, make sure to follow the test package's setup instructions and include the test/pub_serve transformer.
  /// Defaults to false.
  bool pubServe = defaultPubServe;
  
  /// List of paths to include in the generated coverage report (LCOV and HTML).
  /// Defaults to 'lib/'.
  List<String> reportOn = defaultReportOn;
}
