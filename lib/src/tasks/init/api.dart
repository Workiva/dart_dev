library dart_dev.src.tasks.init.api;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/src/tasks/task.dart';

const String _initialConfig = '''library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  // Perform task configuration here as necessary.

  // Available task configurations:
  // config.analyze
  // config.examples
  // config.format
  // config.test

  await dev(args);
}
''';

InitTask init() {
  InitTask task = new InitTask();

  File configFile = new File('tool/dev.dart');
  if (configFile.existsSync()) {
    task.successful = false;
    return task;
  }

  configFile.createSync(recursive: true);
  configFile.writeAsStringSync(_initialConfig);
  task.successful = true;

  return task;
}

class InitTask extends Task {
  final Future done = new Future.value();
  InitTask();
}
