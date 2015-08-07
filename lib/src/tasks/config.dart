library dart_dev.src.tasks.config;

import 'package:dart_dev/src/tasks/analyze/config.dart';
import 'package:dart_dev/src/tasks/examples/config.dart';
import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/init/config.dart';
import 'package:dart_dev/src/tasks/test/config.dart';

Config config = new Config();

class Config {
  AnalyzeConfig analyze = new AnalyzeConfig();
  ExamplesConfig examples = new ExamplesConfig();
  FormatConfig format = new FormatConfig();
  InitConfig init = new InitConfig();
  TestConfig test = new TestConfig();
}

class TaskConfig {
  List after = [];
  List before = [];
}
