@TestOn('browser')
library coverage.browser.test.browser_test;

import 'package:coverage_browser/coverage_browser.dart' as lib;
import 'package:test/test.dart';

main() {
  test('browser test', () {
    expect(lib.works(), isTrue);
  });
}