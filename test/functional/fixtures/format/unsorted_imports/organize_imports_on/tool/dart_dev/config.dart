import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  'format': FormatTool()
    ..organizeImports = true
    ..exclude = [Glob('tool/**')],
};
