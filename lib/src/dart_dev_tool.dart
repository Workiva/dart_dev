import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';

import 'tools/function_tool.dart';
import 'utils/verbose_enabled.dart';

abstract class DevTool {
  DevTool();

  factory DevTool.fromFunction(
          FutureOr<int?> Function(DevToolExecutionContext context) function,
          {ArgParser? argParser}) =>
      FunctionTool(function, argParser: argParser);

  factory DevTool.fromProcess(String executable, List<String> args,
          {ProcessStartMode? mode, String? workingDirectory}) =>
      ProcessTool(executable, args,
          mode: mode, workingDirectory: workingDirectory);

  /// The argument parser for this tool, if needed.
  ///
  /// When this tool is run from the command-line, this will be used to parse
  /// the arguments. The results will be available via the
  /// [DevToolExecutionContext] provided when calling [run].
  ArgParser? get argParser => null;

  /// This tool's description (which is included in the help/usage output) can
  /// be overridden by setting this field to a non-null value.
  String? description;

  /// This field determines whether or not this tool is hidden from the
  /// help/usage output when running as a part of a command-line app.
  ///
  /// By default, tools are not hidden.
  bool hidden = false;

  /// Runs this tool and returns (either synchronously or asynchronously) an
  /// int which will be treated as the exit code (i.e. non-zero means failure).
  ///
  /// [context] is optional. If calling this directly from a dart script, you
  /// will most likely want to omit this. [DevTool]s that are converted to a
  /// [DevToolCommand] via [toCommand] for use in a command-line application
  /// will provide a fully-populated [DevToolExecutionContext] here.
  ///
  /// This is the one API member that subclasses need to implement.
  FutureOr<int> run([DevToolExecutionContext? context]);

  /// Converts this tool to a [Command] that can be added directly to a
  /// [CommandRunner], therefore making it executable from the command-line.
  ///
  /// The default implementation of this method returns a [Command] that calls
  /// [run] when it is executed.
  ///
  /// This method can be overridden by subclasses to return a custom
  /// implementation/extension of [DevToolCommand].
  ///     class CustomTool extends DevTool {
  ///       @override
  ///       Command<int> toCommand(String name) => CustomCommand(name, this);
  ///     }
  ///
  ///     class CustomCommand extends DevToolCommand {
  ///       CustomCommand(String name, DevTool devTool) : super(name, devTool);
  ///
  ///       @override
  ///       String get usageFooter => 'Custom usage footer...';
  ///     }
  Command<int> toCommand(String name) => DevToolCommand(name, this);
}

/// A representation of the command-line execution context in which a [DevTool]
/// is being run.
///
/// An instance of this class should be created by [DevToolCommand] when calling
/// [DevTool.run] so that the tool can utilize the parsed arg results, whether
/// or not global verbose mode is enabled, and the [usageException] utility
/// function from [Command].
class DevToolExecutionContext {
  DevToolExecutionContext(
      {this.argResults,
      this.commandName,
      void Function(String message)? usageException,
      this.verbose = false})
      : _usageException = usageException;

  final void Function(String message)? _usageException;

  /// The results from parsing the arguments passed to a [Command] if this tool
  /// was executed via a command-line app.
  ///
  /// This may be null.
  final ArgResults? argResults;

  /// The name of the [Command] that executed this tool if it was executed via a
  /// command-line app.
  ///
  /// This may be null.
  final String? commandName;

  /// Whether the `-v|--verbose` flag was enabled when running the [Command]
  /// that executed this tool if it was executed via a command-line app.
  ///
  /// This will not be null; it defaults to `false`.
  final bool verbose;

  /// Return a copy of this instance with optional updates; any field that does
  /// not have an updated value will remain the same.
  DevToolExecutionContext update({
    ArgResults? argResults,
    String? commandName,
    void Function(String message)? usageException,
    bool? verbose,
  }) =>
      DevToolExecutionContext(
        argResults: argResults ?? this.argResults,
        commandName: commandName ?? this.commandName,
        usageException: usageException ?? this.usageException,
        verbose: verbose ?? this.verbose,
      );

  /// Calling this will throw a [UsageException] with [message] that should be
  /// caught by [CommandRunner] and used to set the exit code accordingly and
  /// print out usage information.
  void usageException(String message) {
    if (_usageException != null) {
      _usageException!(message);
    }
    throw UsageException(message, '');
  }
}

class DevToolCommand extends Command<int> {
  DevToolCommand(this.name, this.devTool);

  @override
  ArgParser get argParser => devTool.argParser ?? super.argParser;

  @override
  String get description => devTool.description ?? '';

  final DevTool devTool;

  @override
  bool get hidden => devTool.hidden;

  @override
  final String name;

  @override
  FutureOr<int> run() async => (await devTool.run(
        DevToolExecutionContext(
          argResults: argResults,
          commandName: name,
          usageException: usageException,
          verbose: verboseEnabled(this),
        ),
      ));
}
