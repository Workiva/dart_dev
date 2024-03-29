import 'dart:io';

import 'package:logging/logging.dart';

import 'ensure_process_exit.dart';
import 'process_declaration.dart';

Future<Process> startProcessAndEnsureExit(ProcessDeclaration processDeclaration,
    {Logger? log}) async {
  final process = await Process.start(
      processDeclaration.executable, processDeclaration.args.toList(),
      mode: processDeclaration.mode ?? ProcessStartMode.normal,
      workingDirectory: processDeclaration.workingDirectory);
  ensureProcessExit(process, log: log);
  return process;
}
