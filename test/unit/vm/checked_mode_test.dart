@TestOn('vm')
import 'dart:io';

import 'package:dart_dev/checked_mode.dart';
import 'package:test/test.dart';

void main() {
  test('Checked mode is enabled', () {
    expect(assertCheckedModeEnabled, returnsNormally);
  });

  test('Checked mode is disabled', () {
    final result =
        Process.runSync('dart', ['test_fixtures/checked_mode_disabled.dart']);
    expect(result.exitCode, isNot(0));
  });
}
