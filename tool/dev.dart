import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'format': FormatTool()..exclude = [Glob('test/tools/fixtures/**.dart')],
  'serve': WebdevServeTool()..webdevArgs = ['test'],
};
