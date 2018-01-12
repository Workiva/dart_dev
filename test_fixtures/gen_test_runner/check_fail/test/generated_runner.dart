@TestOn('browser')
library test.generated_runner;

import 'package:test/test.dart';
import './browser_test.dart' as browser_test;

void main() {
  browser_test.main();
  test_that_should_be_removed.main();
}