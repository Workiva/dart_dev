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
