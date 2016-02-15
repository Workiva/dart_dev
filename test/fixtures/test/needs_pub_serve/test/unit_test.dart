library test_failing.test.passing_unit_test;

import 'package:test/test.dart';

final bool wasTransformed = false;

void main() {
  test('passes', () {
    expect(wasTransformed, isTrue);
  });
}
