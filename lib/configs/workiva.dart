import '../src/dart_dev_tool.dart';

import '../src/tools/analyze_tool.dart';
import '../src/tools/format_tool.dart';
import '../src/tools/test_tool.dart';
import '../src/tools/webdev_serve_tool.dart';

/// An opinionated `tool/dev.dart` base configuration intended to help
/// standardize dart_dev configuration and command-line usage across Dart
/// projects in the Workiva organization.
final workivaConfig = <String, DevTool>{
  'analyze': AnalyzeTool(),
  'format': FormatTool(),
  'test': TestTool(),
  'serve': WebdevServeTool(),
};
