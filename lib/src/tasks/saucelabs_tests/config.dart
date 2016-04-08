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

library dart_dev.src.tasks.saucelabs_tests.config;

import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/saucelabs_tests/platforms.dart';

const String defaultBuildName = 'saucelabs-run';
const List<SaucePlatform> defaultPlatforms = const <SaucePlatform>[
  chromeWindows,
  firefoxWindows,
  chromeOsx,
  firefoxOsx,
  ie10,
  ie11,
];
const int defaultPubServer = 0;
const String defaultSauceConnectTunnelIdentifier = null;
const String defaultTestReportsPath = 'test_reports/sauce_labs_unit_tests.xml';

class SaucelabsTestsConfig extends TaskConfig {
  String buildName = defaultBuildName;
  List<String> filesToTest = [];
  List<SaucePlatform> platforms = defaultPlatforms;
  int pubServer = defaultPubServer;
  String sauceConnectTunnelIdentifier = defaultSauceConnectTunnelIdentifier;
  String testReportPath = defaultTestReportsPath;
}
