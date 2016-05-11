@TestOn('vm')
library coverage.vm.test.vm_test;

import 'package:coverage_vm/coverage_vm.dart' as lib;
import 'package:test/test.dart';

main() {
  test('browser test', () {
    expect(lib.works(), isTrue);
  });
}