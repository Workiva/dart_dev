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

library dart_dev.src.tasks.analyze.config;

import 'package:dart_dev/src/tasks/config.dart';

const List<String> defaultEntryPoints = const ['lib/'];
const bool defaultFatalWarnings = true;
const bool defaultHints = true;
const bool defaultFatalHints = false;
const bool defaultStrong = false;

class AnalyzeConfig extends TaskConfig {
  List<String> entryPoints = defaultEntryPoints.toList();
  bool fatalWarnings = defaultFatalWarnings;
  bool hints = defaultHints;
  bool fatalHints = defaultFatalHints;
  bool strong = defaultStrong;
}
