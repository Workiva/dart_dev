import 'dart:async';

import 'package:args/args.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';

/// A utility class designed to make it simple to create a [DevTool] from just a
/// Dart function.
///
/// Use [DevTool.fromFunction] to create [FunctionTool] instances.
class FunctionTool extends DevTool {
  FunctionTool(
      FutureOr<int?> Function(DevToolExecutionContext context) function,
      {ArgParser? argParser})
      : _argParser = argParser,
        _function = function;

  final FutureOr<int?> Function(DevToolExecutionContext context) _function;

  // ---------------------------------------------------------------------------
  // DevTool Overrides
  // ---------------------------------------------------------------------------

  @override
  ArgParser? get argParser => _argParser;
  final ArgParser? _argParser;

  @override
  FutureOr<int> run([DevToolExecutionContext? context]) async {
    context ??= DevToolExecutionContext();
    final argResults = context.argResults;
    if (argResults != null) {
      if (argParser == null) {
        assertNoPositionalArgsNorArgsAfterSeparator(
            argResults, context.usageException,
            commandName: context.commandName);
      }
    }
    final exitCode = await _function(context);
    if (exitCode != null) {
      return exitCode;
    }
    Logger('DartFunctionTool').warning(
        '${context.commandName != null ? 'The ${context.commandName}' : 'This'}'
        ' command did not return an exit code.');
    return ExitCode.software.code;
  }
}
