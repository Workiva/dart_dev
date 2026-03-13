import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  'format': FormatTool()
    ..formatter = Formatter.dartFormat
    ..languageVersion = '3.0'
    ..exclude = [Glob('tool/**')],
};
