import 'package:dart_dev_config/tools.dart';

/// An opinionated `tool/dev.dart` base configuration intended to help
/// standardize dart_dev configuration and command-line usage across Dart
/// projects in the Workiva organization.
final workivaConfig = <String, DevTool>{
  'analyze': AnalyzeTool(),
  'format': FormatTool(),
  'test': TestTool(),
  'serve': WebdevServeTool(),
};
