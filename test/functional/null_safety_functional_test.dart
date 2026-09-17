@TestOn('vm')
@Timeout(Duration(seconds: 20))
library;
import 'package:test/test.dart';

import '../functional.dart';

void main() {
  group('runs analyze on a Dart 3 project', () {
    test('without any custom config', () async {
      final process = await runDevToolFunctionalTest(
        'analyze',
        'test/functional/fixtures/null_safety/opted_in_no_config',
      );
      await process.shouldExit(0);
    });

    test('with a custom config', () async {
      final process = await runDevToolFunctionalTest(
        'analyze',
        'test/functional/fixtures/null_safety/opted_in_custom_config',
      );
      await process.shouldExit(0);
    });
  });
}
