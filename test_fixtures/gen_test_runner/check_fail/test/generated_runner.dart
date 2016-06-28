@TestOn('browser')
library test.generated_runner;

import './browser_test.dart' as browser_test;
import 'package:test/test.dart';

void main() {
  browser_test.main();
  test_that_should_be_removed.main();
}