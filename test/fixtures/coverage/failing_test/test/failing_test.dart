@TestOn('browser')
library coverage_failing_test.test.failing_test;

import 'package:coverage_failing_test/coverage_failing_test.dart' as lib;
import 'package:test/test.dart';

main() {
  test('fails', () {
    expect(1, isTrue);
  });
}
