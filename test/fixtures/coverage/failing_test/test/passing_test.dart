@TestOn('browser')
library coverage_failing_test.test.passing_testt;

import 'package:coverage_failing_test/coverage_failing_test.dart' as lib;
import 'package:test/test.dart';

main() {
  test('passes', () {
    expect(true, isTrue);
  });
}
