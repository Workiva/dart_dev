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

class ApplyLicenseConfig {
  static const String key = 'apply-license';
  static const String excludeKey = 'exclude';
  static const String includeKey = 'include';
  static const String licenseKey = 'license';

  static ApplyLicenseConfig parse(Map dartDevApplyLicenseYaml) {
    dartDevApplyLicenseYaml ??= {};

    final excludes = dartDevApplyLicenseYaml[excludeKey];
    final includes = dartDevApplyLicenseYaml[includeKey];
    final license = dartDevApplyLicenseYaml[licenseKey];

    return new ApplyLicenseConfig(
        excludes: excludes, includes: includes, license: license);
  }

  final Iterable<String> excludes;
  final Iterable<String> includes;
  final String license;

  ApplyLicenseConfig(
      {Iterable<String> excludes, Iterable<String> includes, String license})
      : excludes = excludes ?? const [],
        includes = includes ?? const [],
        license = license ?? const [];
}
