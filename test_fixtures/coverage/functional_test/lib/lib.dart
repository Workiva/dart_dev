library functional_test.lib;

import 'dart:html';

ButtonElement button = querySelector('#button');
int buttonClickCount = 0;

void setup() {
  button.onClick.listen((event) {
    handleButtonClick();
  });
}

void handleButtonClick() {
  buttonClickCount++;
}
