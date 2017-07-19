import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('passes', () async {
    // Wait so that the test task doesn't complete too quickly.
    await new Future.delayed(const Duration(seconds: 2));
    expect(true, isTrue);
  });
}
