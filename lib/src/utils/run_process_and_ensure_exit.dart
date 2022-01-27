import 'dart:io';

import 'package:logging/logging.dart';

import 'process_declaration.dart';
import 'ensure_process_exit.dart';

Future<int> runProcessAndEnsureExit(ProcessDeclaration processDeclaration,
    {Logger? log}) async {
  final process = await Process.start(
      processDeclaration.executable, processDeclaration.args.cast<String>(),
      mode: processDeclaration.mode ?? ProcessStartMode.normal,
      workingDirectory: processDeclaration.workingDirectory);
  ensureProcessExit(process, log: log);
  return process.exitCode;
}
