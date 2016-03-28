library coverage_failing_test.coverage_failing_test;

import 'dart:html';

void notCovered() {
  print('nope');
}

bool works() => document is Document;
