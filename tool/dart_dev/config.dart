import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'format': FormatTool()
    ..organizeImports = true
    ..exclude = [Glob('test/**/fixtures/**.dart')],
};
