import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../src/utils/verbose_enabled.dart';

abstract class DevTool {
  /// This tool's description (which is included in the help/usage output) can
  /// be overridden by setting this field to a non-null value.
  String description;

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
  FutureOr<int> run([DevToolExecutionContext context]);

  /// Converts this tool to a [Command] that can be added directly to a
  /// [CommandRunner], therefore making it executable from the command-line.
  ///
  /// The default implementation of this method returns a [Command] that calls
  /// [run] when it is executed.
  ///
  /// This method may be overridden by subclasses if the default behavior needs
  /// to be modified further.
  ///
  /// To provide a custom [ArgParser]:
  ///     @override
  ///     Command<int> toCommand(String name) =>
  ///         DevToolCommand(name, this, argParser: ArgParser()
  ///           ..addFlag('foo')
  ///           ..addOption('bar'));
  ///
  /// To further customize the returned [Command], create a new class that
  /// extends [DevToolCommand] and override this method to return it:
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
      void Function(String message) usageException,
      bool verbose})
      : _usageException = usageException,
        verbose = verbose ?? false;

  /// The results from parsing the arguments passed to a [Command] if this tool
  /// was executed via a command-line app.
  ///
  /// This may be null.
  final ArgResults argResults;

  /// The name of the [Command] that executed this tool if it was executed via a
  /// command-line app.
  ///
  /// This may be null.
  final String commandName;

  /// Whether the `-v|--verbose` flag was enabled when running the [Command]
  /// that executed this tool if it was executed via a command-line app.
  ///
  /// This will not be null; it defaults to `false`.
  final bool verbose;

  final void Function(String message) _usageException;

  /// Calling this will throw a [UsageException] with [message] that should be
  /// caught by [CommandRunner] and used to set the exit code accordingly and
  /// print out usage information.
  void usageException(String message) {
    if (_usageException != null) {
      _usageException(message);
    }
    throw UsageException(message, '');
  }
}

class DevToolCommand extends Command<int> {
  DevToolCommand(this.name, this.devTool, {ArgParser argParser})
      : _argParser = argParser;

  @override
  ArgParser get argParser => _argParser ?? super.argParser;
  final ArgParser _argParser;

  @override
  String get description => devTool.description ?? '';

  final DevTool devTool;

  @override
  bool get hidden => devTool.hidden ?? '';

  @override
  final String name;

  @override
  Future<int> run() async => devTool.run(DevToolExecutionContext(
      argResults: argResults,
      commandName: name,
      usageException: usageException,
      verbose: verboseEnabled(this)));
}
