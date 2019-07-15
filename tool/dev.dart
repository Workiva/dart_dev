import 'package:dart_dev/command_builder.dart';
import 'package:dart_dev/commands/analyze_command.dart';
import 'package:dart_dev/commands/format_command.dart';

Map<String, CommandBuilder> get config => {
      'analyze': AnalyzeCommand(),
      'format': FormatCommand(),
    };
