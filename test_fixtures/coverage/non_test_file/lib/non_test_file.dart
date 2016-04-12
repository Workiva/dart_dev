library non_test_file;

import 'dart:io';

void notCovered() {
  print('nope');
}

bool works() => stdout is IOSink;