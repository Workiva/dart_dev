library coverage_browser;

import 'dart:html';

void notCovered() {
  print('nope');
}

bool works() => document is Document;