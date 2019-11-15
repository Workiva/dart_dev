import 'dart:async';
import 'dart:io';

import 'package:dart_dev/src/utils/start_process_and_ensure_exit.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/logging.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('Process');

/// A utility class designed to make it simple to create a [DevTool] that runs a
/// process, waits for it to complete, and forwards its exit code.
///
/// To create a [ProcessTool], all that is needed is an executable and args:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'github': ProcessTool(
///         'open', ['https://github.com/Workiva/dart_dev']),
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     ProcessTool(exe, args).run();
class ProcessTool extends DevTool {
  ProcessTool(String executable, List<String> args,
      {ProcessStartMode mode, String workingDirectory})
      : _args = args,
        _executable = executable,
        _mode = mode,
        _workingDirectory = workingDirectory;

  final List<String> _args;
  final String _executable;
  final ProcessStartMode _mode;
  final String _workingDirectory;

  Process get process => _process;
  Process _process;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    context ??= DevToolExecutionContext();
    if (context.argResults != null) {
      assertNoPositionalArgsNorArgsAfterSeparator(
          context.argResults, context.usageException,
          commandName: context.commandName);
    }
    logSubprocessHeader(_log, '$_executable ${_args.join(' ')}');
    _process = await startProcessAndEnsureExit(
        ProcessDeclaration(_executable, _args,
            mode: _mode, workingDirectory: _workingDirectory),
        log: _log);
    return _process.exitCode;
  }
}
