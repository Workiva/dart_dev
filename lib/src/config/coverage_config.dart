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

class CoverageConfig {
  static const String filenameKey = 'filename';
  static const String generateHtmlKey = 'generate_html';
  static const String key = 'coverage';
  static const String outputKey = 'output';
  static const String pathsKey = 'paths';
  static const String reportOnKey = 'report_on';

  static CoverageConfig parse(Map dartDevCoverageYaml, Map dartTestYaml) {
    dartDevCoverageYaml ??= {};
    dartTestYaml ??= {};

    // dart_dev.yaml options
    final generateHtml = dartDevCoverageYaml[generateHtmlKey];
    final output = dartDevCoverageYaml[outputKey];
    final reportOn = dartDevCoverageYaml[reportOnKey];

    // dart_test.yaml options
    final filenamePattern = dartTestYaml[filenameKey];
    final paths = dartTestYaml[pathsKey];

    return new CoverageConfig(
        filenamePattern: filenamePattern,
        generateHtml: generateHtml,
        output: output,
        paths: paths,
        reportOn: reportOn);
  }

  final String filenamePattern;
  final bool generateHtml;
  final String output;
  final Iterable<String> paths;
  final Iterable<String> reportOn;

  CoverageConfig(
      {String filenamePattern,
      bool generateHtml,
      String output,
      Iterable<String> paths,
      Iterable<String> reportOn})
      : filenamePattern = filenamePattern ?? '*_test.dart',
        generateHtml = generateHtml ?? true,
        output = output ?? 'coverage/',
        paths = paths ?? ['test/'],
        reportOn = reportOn ?? ['lib/'];
}
