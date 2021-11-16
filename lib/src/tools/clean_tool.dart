import 'dart:async';
import 'dart:io';

import 'package:io/io.dart';

import '../dart_dev_tool.dart';
import '../utils/dart_dev_paths.dart' show DartDevPaths;

class CleanTool extends DevTool {
  @override
  final String? description = 'Cleans up temporary files used by dart_dev.';

  @override
  FutureOr<int?> run([DevToolExecutionContext? context]) {
    final cache = Directory(DartDevPaths().cache());
    if (cache.existsSync()) {
      cache.deleteSync(recursive: true);
    }
    return ExitCode.success.code;
  }
}
