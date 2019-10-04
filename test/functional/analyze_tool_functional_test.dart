@TestOn('vm')
@Timeout(Duration(seconds: 20))
import 'package:test/test.dart';

import '../functional.dart';

void main() {
  test('success', () async {
    final result = await runDevToolFunctionalTest(
        'analyze', 'test/functional/fixtures/analyze/success');
    expect(result, exitsWith(0));
  });

  test('failure', () async {
    final result = await runDevToolFunctionalTest(
        'analyze', 'test/functional/fixtures/analyze/failure');
    expect(result, exitsWith(greaterThan(0)));
  });
}
