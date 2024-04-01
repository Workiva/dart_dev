import 'dart:async';
import 'dart:io';

import 'package:dart_dev/src/utils/logging.dart';
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
      log.info('Deleting ${cache.path}');
      cache.deleteSync(recursive: true);
    } else {
      log.info('Nothing to do: no ${cache.path} found');
    }
    return ExitCode.success.code;
  }
}
