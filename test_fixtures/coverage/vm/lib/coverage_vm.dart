library coverage_vm;

import 'dart:io';

void notCovered() {
  print('nope');
}

bool works() => stdout is IOSink;