/// A `tool/dart_dev/config.dart` base configuration with the core Dart
/// developer tasks. Intended to help standardize dart_dev configuration and
/// command-line usage across Dart projects.
library dart_dev.src.core_config;

import 'package:dart_dev/dart_dev.dart';

Map<String, DevTool> get coreConfig => {
      'analyze': AnalyzeTool(),
      'format': FormatTool(),
      'test': TestTool(),
      'tdd': TddTool(),
    };
