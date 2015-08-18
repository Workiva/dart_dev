@TestOn('browser')
library coverage.browser.test.browser_custom_test;

import 'dart:js' show context;

import 'package:coverage_browser/coverage_browser.dart' as lib;
import 'package:test/test.dart';

main() {
  test('browser test', () {
    expect(lib.works(), isTrue);
    expect(context['customScript'], isTrue);
  });
}