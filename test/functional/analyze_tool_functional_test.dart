@TestOn('vm')
@Timeout(Duration(seconds: 20))
import 'package:test/test.dart';

import '../functional.dart';

void main() {
  test('success', () async {
    final process = await runDevToolFunctionalTest(
        'analyze', 'test/functional/fixtures/analyze/success');
    await process.shouldExit(0);
  });

  test('failure', () async {
    final process = await runDevToolFunctionalTest(
        'analyze', 'test/functional/fixtures/analyze/failure');
    await process.shouldExit(greaterThan(0));
  });
}
