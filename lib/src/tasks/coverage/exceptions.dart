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

library dart_dev.src.tasks.coverage.exceptions;

const String missingLcovMessage = '''
The "lcov" dependency is missing. It's required for generating the HTML report.

If using brew, you can install it with:
    brew update
    brew install lcov

Otherwise, visit http://ltp.sourceforge.net/coverage/lcov.php
''';

/// Thrown when collecting coverage on a test suite that has failing tests.
class CoverageTestSuiteException implements Exception {
  final String message;
  CoverageTestSuiteException(String testSuite)
      : this.message = 'Test suite has failing tests: $testSuite';
  String toString() => 'CoverageTestSuiteException: $message';
}

/// Thrown when attempting to generate the HTML coverage report without the
/// required "lcov" dependency being installed.
class MissingLcovException implements Exception {
  final String message = missingLcovMessage;
  String toString() => 'MissingLcovException: $message';
}
