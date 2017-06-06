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

library dart_dev.src.tasks.format.config;

import 'package:dart_dev/src/tasks/config.dart';

const bool defaultCheck = false;
const List<String> defaultPaths = const ['lib/'];
const List<String> defaultExclude = const [];
const int defaultLineLength = 80;

/// Deprecated; use [defaultPaths] instead.
@Deprecated('2.0.0')
const List<String> defaultDirectories = defaultPaths;

class FormatConfig extends TaskConfig {
  bool check = defaultCheck;
  List<String> paths = defaultPaths;
  List<String> exclude = defaultExclude;
  int lineLength = defaultLineLength;

  /// Deprecated; use [paths] instead.
  @Deprecated('2.0.0')
  List<String> get directories => paths;

  /// Deprecated; use [paths] instead.
  @Deprecated('2.0.0')
  set directories(List<String> value) => paths = value;

  Map<String, dynamic> toJson() => {
        'check': check,
        'paths': paths,
        'exclude': exclude,
        'lineLength': lineLength,
      };
}
