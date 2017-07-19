import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('fails', () async {
    await new Future.delayed(new Duration(seconds:5));
    expect(true, isFalse);
  });
}
