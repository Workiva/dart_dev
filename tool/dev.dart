import 'package:dart_dev/configs/workiva.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...workivaConfig,
  'format': FormatTool()..exclude = [Glob('test/tools/fixtures/**.dart')],
  'serve': WebdevServeTool()..webdevArgs = ['test'],
};
