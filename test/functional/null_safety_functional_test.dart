@TestOn('vm')
@Timeout(Duration(seconds: 20))
import 'package:test/test.dart';

import '../functional.dart';

void main() {
  group('runs properly in a project that has opted into null safety', () {
    test('without any custom config', () async {
      final process = await runDevToolFunctionalTest(
          'analyze', 'test/functional/fixtures/null_safety/opted_in_no_config');
      await process.shouldExit(0);
    });

    test('with a custom config', () async {
      final process = await runDevToolFunctionalTest(
          'analyze', 'test/functional/fixtures/null_safety/opted_in_custom_config');
      await process.shouldExit(0);
    });

    test('with a custom config that has a language version comment', () async {
      final process = await runDevToolFunctionalTest(
          'analyze', 'test/functional/fixtures/null_safety/opted_in_custom_config_version_comment');
      await process.shouldExit(0);
    });
  });
}
