library functional_test.test.functional.simple_test;

import 'package:test/test.dart';
import 'package:webdriver/io.dart';
import 'package:dart_dev/util.dart' show TaskProcess;

void main() {
  WebDriver driver;

  setUp(() async {
    TaskProcess whichDartium = new TaskProcess('which', ['dartium']);
    String dartiumPath = await whichDartium.stdout.first;

    var options = {
      'browserName': 'chrome',
      'chromeOptions': {
        'binary': dartiumPath
      }
    };
    driver = await createDriver(desired: options);
  });

  // Do not quit the webdriver because the coverage task will handle closing the
  // browser after coverage has been collected.
  //tearDown(() => driver.quit());

  test('Load the test app', () async {
    await driver.get('http://localhost:8014');
  });

  test('Click the button', () async {
    await driver.get('http://localhost:8014');
    var button = await driver.findElement(new By.id('button'));
    await button.click();
  });
}
