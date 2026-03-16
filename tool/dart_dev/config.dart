import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'analyze': AnalyzeTool()..useDartAnalyze = true,
  'format': FormatTool()
    ..languageVersion = 'latest'
    ..organizeDirectives = true
    ..exclude = [Glob('test/**/fixtures/**.dart')]
    ..formatter = Formatter.dartFormat,
};
