library integration_test_passing.test.failing_unit_test;

import 'package:test/test.dart';

void main() {
  test('passes', () {
    expect(false, isTrue);
  });
}