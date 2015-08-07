library dart_dev.src.tasks.analyze.config;

import 'package:dart_dev/src/tasks/config.dart';

const List<String> defaultEntryPoints = const ['lib/'];
const bool defaultFatalWarnings = true;
const bool defaultHints = true;

class AnalyzeConfig extends TaskConfig {
  List<String> entryPoints = defaultEntryPoints.toList();
  bool fatalWarnings = defaultFatalWarnings;
  bool hints = defaultHints;
}
