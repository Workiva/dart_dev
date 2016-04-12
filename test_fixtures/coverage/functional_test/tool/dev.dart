library tool.dev;

import 'dart:async';

import 'package:dart_dev/dart_dev.dart' show dev, config;
import 'package:dart_dev/util.dart' show SeleniumHelper, TaskProcess;


SeleniumHelper selenium;
TaskProcess serveWebDir;

Future<Null> startSeleniumAndServeWebDir() async {
  serveWebDir = new TaskProcess('pub', ['serve', 'web', '--port', '8014']);
  serveWebDir.stdout.listen((l) => print('    $l'));
  serveWebDir.stderr.listen((l) => print('    $l'));
  selenium = new SeleniumHelper(executablePath: 'tool/selenium-server');
  await selenium.start();
}

Future<Null> stopSeleniumAndPubServe() async {
  serveWebDir.kill();
  await selenium.stop();
}

main(List<String> args) async {
  config.test
    ..unitTests = []
    ..functionalTests = ['test/functional/']
    ..before = [startSeleniumAndServeWebDir]
    ..after = [stopSeleniumAndPubServe];
  config.coverage
    ..before = [startSeleniumAndServeWebDir]
    ..after = [stopSeleniumAndPubServe];

  await dev(args);
}
