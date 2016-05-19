@TestOn('vm')
library test.integration.generated_runner;

import './analyze_test.dart' as analyze_test;
import './copy_license_test.dart' as copy_license_test;
import './coverage_test.dart' as coverage_test;
import './docs_test.dart' as docs_test;
import './examples_test.dart' as examples_test;
import './format_test.dart' as format_test;
import './gen_test_runner_test.dart' as gen_test_runner_test;
import './init_test.dart' as init_test;
import './local_test.dart' as local_test;
import './test_test.dart' as test_test;
import 'package:test/test.dart';

void main() {
  analyze_test.main();
  copy_license_test.main();
  coverage_test.main();
  docs_test.main();
  examples_test.main();
  format_test.main();
  gen_test_runner_test.main();
  init_test.main();
  local_test.main();
  test_test.main();
}
