import 'package:dart_dev_workiva/workiva.dart';
import 'package:dart_dev_config/tools.dart';
import 'package:glob/glob.dart';

final config = {
  ...workivaConfig,
  'format': FormatTool()..exclude = [Glob('test/tools/fixtures/**.dart')],
  'serve': WebdevServeTool()..webdevArgs = ['test'],
};
