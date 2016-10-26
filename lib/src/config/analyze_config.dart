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

class AnalyzeConfig {
  static const String key = 'analyze';
  static const String librariesKey = 'libraries';
  static const String linterKey = 'linter';
  static const String linterRulesKey = 'rules';

  static AnalyzeConfig parse(Map dartDevAnalyzeYaml, Map analysisOptionsYaml) {
    dartDevAnalyzeYaml ??= {};
    analysisOptionsYaml ??= {};

    // libraries - from dart_dev.yaml
    final libraries = dartDevAnalyzeYaml[librariesKey];

    // excluded - from analysis_options.yaml/.analysis_options
    // TODO
    Iterable<String> excluded;

    // lintRules - from analysis_options.yaml/.analysis_options
    Iterable<String> linterRules;
    if (analysisOptionsYaml.containsKey(linterKey)) {
      final linterOptions = analysisOptionsYaml[linterKey];
      if (linterOptions is Map &&
          linterOptions.containsKey(linterRulesKey) &&
          linterOptions[linterRulesKey] is Iterable<String>) {
        linterRules = linterOptions[linterRulesKey];
      }
    }

    return new AnalyzeConfig(
        excluded: excluded, libraries: libraries, lintRules: linterRules);
  }

  final Iterable<String> excluded;
  final Iterable<String> libraries;
  final Iterable<String> linterRules;

  AnalyzeConfig(
      {Iterable<String> excluded,
      Iterable<String> libraries,
      Iterable<String> lintRules})
      : excluded = excluded ?? const [],
        libraries = libraries ?? const [],
        linterRules = lintRules ?? const [];
}
