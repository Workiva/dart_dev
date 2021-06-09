// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
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
