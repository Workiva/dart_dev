library dart_dev.src.tasks.coverage.config;

import 'package:dart_dev/src/tasks/config.dart';

const bool defaultHtml = true;
const String defaultOutput = 'coverage/';
const List<String> defaultReportOn = const ['lib/'];

class CoverageConfig extends TaskConfig {
  bool html = defaultHtml;
  String output = defaultOutput;
  List<String> reportOn = defaultReportOn;
}
