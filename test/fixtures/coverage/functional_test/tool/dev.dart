library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;
import 'package:dart_dev/util.dart' show TaskProcess;

main(List<String> args) async {
  TaskProcess pubServe;
  void _startPubServe() {
    pubServe = new TaskProcess("pub",["serve","--port=8080"]);
    pubServe.stdout.listen((l){print(l);});
  }

  void _stopPubServe(){
    pubServe.kill();
  }

  config.test
      ..functionalTests = ['test']
      ..before = [_startPubServe]
      ..after = [_stopPubServe];
  config.coverage
    ..before = [_startPubServe]
    ..after = [_stopPubServe];


  await dev(args);
}