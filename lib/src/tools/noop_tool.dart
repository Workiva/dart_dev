import 'dart:async';

import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';

final _log = Logger('Noop');

class NoopTool extends DevTool {
  String buildArg;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) {
    _log.severe(red.wrap(buildArg));
    return ExitCode.config.code;
  }
}
