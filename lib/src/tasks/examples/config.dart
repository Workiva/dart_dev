library dart_dev.src.tasks.examples.config;

import 'package:dart_dev/src/tasks/config.dart';

const String defaultHostname = 'localhost';
const int defaultPort = 8080;

class ExamplesConfig extends TaskConfig {
  String hostname = defaultHostname;
  int port = defaultPort;
}
