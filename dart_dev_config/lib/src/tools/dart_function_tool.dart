import 'dart:async';

import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';

class DartFunctionTool extends DevTool {
  DartFunctionTool(FutureOr<int> Function({bool verbose}) function)
      : _function = function;

  final FutureOr<int> Function({bool verbose}) _function;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    context ??= DevToolExecutionContext();
    if (context.argResults != null) {
      assertNoPositionalArgsNorArgsAfterSeparator(
          context.argResults, context.usageException,
          commandName: context.commandName);
    }
    final exitCode = await _function(verbose: context.verbose);
    if (exitCode != null) {
      return exitCode;
    }
    Logger('DartFunctionTool').warning(
        '${context.commandName != null ? 'The ${context.commandName}' : 'This'}'
        ' command did not return an exit code.');
    return exitCode ?? ExitCode.software.code;
  }
}

// class DartFunctionCommand implements CommandBuilder {
//   /// Constructs an command that will execute [function] when run.
//   ///
//   /// The integer return value (either sync or async) of [function] will be used
//   /// as the exit code for this command.
//   DartFunctionCommand(FutureOr<int> Function() function) : _function = function;

//   /// The default description for this command can be overridden by setting this
//   /// field to a non-null value.
//   ///
//   /// This description is used when printing the help text for this command as
//   /// well as the help text for the top-level `ddev` command runner.
//   @override
//   String description;

//   /// This command is not hidden from the `ddev` command runner by default, but
//   /// can be by setting this to `true`.
//   @override
//   bool hidden;

//   final FutureOr<int> Function() _function;

//   @override
//   Command<int> build(String commandName) => _DartFunctionCommand(
//         commandName,
//         description,
//         _function,
//         hidden,
//       );
// }

// class _DartFunctionCommand extends Command<int> {
//   final String _commandName;
//   final String _description;
//   final FutureOr<int> Function() _function;
//   final bool _hidden;

//   _DartFunctionCommand(
//     this._commandName,
//     this._description,
//     this._function,
//     this._hidden,
//   );

//   @override
//   String get name => _commandName;

//   @override
//   String get description => _description ?? '';

//   @override
//   bool get hidden => _hidden ?? false;

//   @override
//   Future<int> run() async {
//     assertNoPositionalArgsNorArgsAfterSeparator(argResults, '${runner.executableName} $name', usageException);
//     final exitCode = await _function();
//     if (exitCode != null) {
//       return exitCode;
//     }
//     Logger('DartFunctionTool($name)')
//         .warning('The $name command did not return an exit code.');
//     return exitCode ?? ExitCode.software.code;
//   }
// }
