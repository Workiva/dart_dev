library test_failing.test.passing_unit_test;

import 'package:test/test.dart';

void main() {
  test('passes', () {
    expect(true, isTrue);
  });
}