import 'package:args/command_runner.dart';
import 'package:dart_dev/commands/analyze_command.dart';
import 'package:dart_dev/commands/format_command.dart';
import 'package:dart_dev/commands/test_command.dart';

Iterable<Command<int>> build({
  AnalyzeConfig analyzeConfig,
  FormatConfig formatConfig,
  TestConfig testConfig,
}) =>
    [
      // command: analyze
      AnalyzeCommand(
        AnalyzeConfig(
          commandName: 'analyze',
        ),
      ),

      // command: format
      FormatCommand(
        FormatConfig(
          commandName: 'format',

          // Write formatting changes to disk by default. In other words, the user
          // doesn't need to explicitly pass the `-w | --overwrite` flag.
          defaultMode: FormatMode.overwrite,
        ).merge(formatConfig),
      ),

      // command: test
      TestCommand(
        TestConfig().merge(testConfig),
      ),
    ];
