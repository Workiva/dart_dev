library coverage_browser;

import 'dart:html';

void notCovered() {
  print('nope');
}

final bool wasTransformed = false;

bool works() => document is Document && wasTransformed;
