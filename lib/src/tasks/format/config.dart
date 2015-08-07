library dart_dev.src.tasks.format.config;

import 'package:dart_dev/src/tasks/config.dart';

const bool defaultCheck = false;
const List<String> defaultDirectories = const ['lib/'];

class FormatConfig extends TaskConfig {
  bool check = defaultCheck;
  List<String> directories = defaultDirectories;
}
