import 'package:unittest/unittest.dart';
import 'package:webdriver/webdriver.dart' show WebDriver;

void main() {
  WebDriver driver;

  setUp(() async{
    driver = await WebDriver.createDriver(
        desiredCapabilities: {'browserName': 'chrome','chromeOptions':{'binary': '/usr/local/bin/dartium'}});
  });

//  tearDown(() => driver.quit());

  test('Test1', () async {
    await driver.get('http://localhost:8080');
  });
  test('Test2', () async {
    await driver.get('http://localhost:8080');
  });
}