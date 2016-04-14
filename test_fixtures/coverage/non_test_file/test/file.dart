@TestOn('vm')
library coverage.non_test_file.test.file;

import 'package:non_test_file/non_test_file.dart' as lib;
import 'package:test/test.dart';

main() {
  test('non_test_file', () {
    expect(lib.works(), isTrue);
  });
}