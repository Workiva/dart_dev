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

import 'package:meta/meta.dart' show required;

import 'package:dart_dev/src/config/analyze_config.dart';
import 'package:dart_dev/src/config/apply_license_config.dart';
import 'package:dart_dev/src/config/coverage_config.dart';
import 'package:dart_dev/src/config/docs_config.dart';
import 'package:dart_dev/src/config/format_config.dart';
import 'package:dart_dev/src/config/test_config.dart';

class DartDevConfig {
  static DartDevConfig parse(
      Map dartDevYaml, Map analysisOptionsYaml, Map dartTestYaml) {
    dartDevYaml ??= {};
    analysisOptionsYaml ??= {};
    dartTestYaml ??= {};

    // TODO: validate yaml using json_schema

    final dartDevAnalyzeYaml = dartDevYaml[AnalyzeConfig.key];
    final analyze =
        AnalyzeConfig.parse(dartDevAnalyzeYaml, analysisOptionsYaml);

    final dartDevApplyLicenseYaml = dartDevYaml[ApplyLicenseConfig.key];
    final applyLicense = ApplyLicenseConfig.parse(dartDevApplyLicenseYaml);

    final dartDevCoverageYaml = dartDevYaml[CoverageConfig.key];
    final coverage = CoverageConfig.parse(dartDevCoverageYaml, dartTestYaml);

    final dartDevDocsYaml = dartDevYaml[DocsConfig.key];
    final docs = DocsConfig.parse(dartDevDocsYaml);

    final dartDevFormatYaml = dartDevYaml[FormatConfig.key];
    final format = FormatConfig.parse(dartDevFormatYaml);

    final dartDevTestYaml = dartDevYaml[TestConfig.key];
    final test = TestConfig.parse(dartDevTestYaml);

    return new DartDevConfig(
        analyze: analyze,
        applyLicense: applyLicense,
        coverage: coverage,
        docs: docs,
        format: format,
        test: test);
  }

  final AnalyzeConfig analyze;
  final ApplyLicenseConfig applyLicense;
  final CoverageConfig coverage;
  final DocsConfig docs;
  final FormatConfig format;
  final TestConfig test;

  DartDevConfig(
      {@required this.analyze,
      @required this.applyLicense,
      @required this.coverage,
      @required this.docs,
      @required this.format,
      @required this.test});
}
