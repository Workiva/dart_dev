library test_failing.test.failing_integration_test;

import 'package:test/test.dart';

void main() {
  test('fails', () {
    expect(true, isFalse);
  });
}