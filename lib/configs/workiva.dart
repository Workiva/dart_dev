import 'package:dart_dev/tool_api.dart';
import 'package:dart_dev/tools/analyze_tool.dart';
import 'package:dart_dev/tools/format_tool.dart';
import 'package:dart_dev/tools/test_tool.dart';

Iterable<DartDevTool> build({
  AnalyzeConfig analyzeConfig,
  FormatConfig formatConfig,
}) =>
    [
      // command: analyze
      AnalyzeTool(
        AnalyzeConfig(
          commandName: 'analyze',
        ),
      ),

      // command: format
      FormatTool(
        FormatConfig(
          commandName: 'format',

          // Write formatting changes to disk by default. In other words, the user
          // doesn't need to explicitly pass the `-w | --overwrite` flag.
          defaultMode: FormatMode.overwrite,
        ).merge(formatConfig),
      ),

      // command: test
      TestTool(
        TestConfig(),
      ),
    ];
