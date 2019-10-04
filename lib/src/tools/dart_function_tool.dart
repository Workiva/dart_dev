import 'dart:async';

import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';

/// A utility class designed to make it simple to create a [DevTool] from just a
/// Dart function.
///
/// To create a [DartFunctionTool], all that is needed is a function of type:
///     FutureOr<int> Function(DartFunctionToolContext context)
///
/// The `DartFunctionToolContext context` contains info about the context in
/// which the tool is being run, which can be used in the function. Currently,
/// it only contains one piece if info: whether or not "verbose" mode is
/// enabled.
///     import 'package:dart_dev/dart_dev.dart';
///     import 'package:io/io.dart';
///
///     int helloWorld(DartFunctionToolContext context) {
///       print('Hello world!');
///       return ExitCode.success.code; // 0
///     }
///
///     final config = {
///       'hello': DartFunctionTool(helloWorld),
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     DartFunctionTool(fn).run();
class DartFunctionTool extends DevTool {
  DartFunctionTool(
      FutureOr<int> Function(DartFunctionToolContext context) function)
      : _function = function;

  final FutureOr<int> Function(DartFunctionToolContext context) _function;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    context ??= DevToolExecutionContext();
    if (context.argResults != null) {
      assertNoPositionalArgsNorArgsAfterSeparator(
          context.argResults, context.usageException,
          commandName: context.commandName);
    }
    final exitCode =
        await _function(DartFunctionToolContext(verbose: context.verbose));
    if (exitCode != null) {
      return exitCode;
    }
    Logger('DartFunctionTool').warning(
        '${context.commandName != null ? 'The ${context.commandName}' : 'This'}'
        ' command did not return an exit code.');
    return ExitCode.software.code;
  }
}

class DartFunctionToolContext {
  /// Whether the `-v|--verbose` flag was enabled when running the [Command]
  /// that executed this tool if it was executed via a command-line app.
  ///
  /// This will not be null; it defaults to `false`.
  final bool verbose;

  DartFunctionToolContext({bool verbose}) : verbose = verbose ?? false;
}
