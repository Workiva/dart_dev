@TestOn('vm')
import 'package:dart_dev/checked_mode.dart';
import 'package:test/test.dart';

void main() {
  test('Checked mode is enabled', () {
    expect(assertCheckedModeEnabled, returnsNormally);
  });
}
