/// An opinionated `tool/dev.dart` base configuration intended to help
/// standardize dart_dev configuration and command-line usage across Dart
/// projects in the Workiva organization.
library dart_dev.configs.workiva;

import 'package:dart_dev/dart_dev.dart';

final sassTool = SassTool()..sourceDir = 'lib/';

Map<String, DevTool> get workivaConfig => {
  'analyze': AnalyzeTool(),
  'format': FormatTool(),
  'sass': sassTool,
  'sass-release': sassTool.toReleaseSassTool(),
  'serve': WebdevServeTool(),
  'test': TestTool(),
};
