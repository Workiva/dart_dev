import 'package:test/test.dart';
import 'package:webdriver/io.dart';
import 'package:dart_dev/src/task_process.dart';

void main() {
  WebDriver driver;

  setUp(() async{
    TaskProcess dartium = new TaskProcess("which",["dartium"]);
    String dartpath;
    dartium.stdout.listen((l){dartpath = l;});
    await dartium.done;
    print(dartpath);
    driver = await createDriver(
        desired: {'browserName': 'chrome','chromeOptions':{'binary': dartpath}});
  });

  //The webdriver is not quit because the functional coverage tool will forcibly close the browser after coverage collection
//  tearDown(() => driver.quit());

  test('Test1', () async {
    await driver.get('http://localhost:8080');
  });
  test('Test2', () async {
    await driver.get('http://localhost:8080');
  });
}