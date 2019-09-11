import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/logging.dart';
import '../utils/package_is_globally_activated.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('WebdevServe');

class WebdevServeTool extends DevTool {
  /// The args to pass to the `build_runner` process via the `webdev serve`
  /// process that will be run by this tool.
  ///
  /// Run `pub run build_runner build -h` to see all available args.
  List<String> buildArgs;

  @override
  String description = 'Run a local web development server and a file system '
      'watcher that rebuilds on changes.';

  /// The args to pass to the `webdev serve` process that will be run by this
  /// tool.
  ///
  /// Run `pub global run webdev serve -h` to see all available args.
  List<String> webdevArgs;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) {
    context ??= DevToolExecutionContext();
    final execution = createWebdevServeExecution(context,
        configuredBuildArgs: buildArgs, configuredWebdevArgs: webdevArgs);
    if (execution.exitCode != null) {
      return execution.exitCode;
    }
    return runProcessAndEnsureExit(execution.process);
  }

  @override
  Command<int> toCommand(String name) => DevToolCommand(name, this,
      argParser: ArgParser()
        ..addOption('webdev-args',
            help: 'Args to pass to the test runner process.\n'
                'Run "pub global run webdev serve -h -v" to see all available '
                'options.')
        ..addOption('build-args',
            help: 'Args to pass to the build runner process.\n'
                'Run "pub run build_runner build -h -v" to see all available '
                'options.'));
}

/// A declarative representation of an execution of the [WebdevServeTool].
///
/// This class allows the [WebdevServeTool] to break its execution up into two
/// steps:
/// 1. Validation of confg/inputs and creation of this class.
/// 2. Execution of expensive or hard-to-test logic based on step 1.
///
/// As a result, nearly all of the logic in [WebdevServeTool] can be tested via
/// the output of step 1 with very simple unit tests.
class WebdevServeExecution {
  WebdevServeExecution.exitEarly(this.exitCode) : process = null;
  WebdevServeExecution.process(this.process) : exitCode = null;

  /// If non-null, the execution is already complete and the [FormatTool] should
  /// exit with this code.
  ///
  /// If null, there is more work to do.
  final int exitCode;

  /// A declarative representation of the formatter process that should be run.
  ///
  /// This process' result should become the final result of the [FormatTool].
  final ProcessDeclaration process;
}

WebdevServeExecution createWebdevServeExecution(
  DevToolExecutionContext context, {
  List<String> configuredBuildArgs,
  List<String> configuredWebdevArgs,
}) {
  if (context.argResults != null) {
    assertNoPositionalArgsNorArgsAfterSeparator(
        context.argResults, context.usageException,
        commandName: context.commandName,
        usageFooter: 'Arguments can be passed to the webdev process via the '
            '--webdev-args option.\n'
            'Arguments can be passed to the build process via the --build-args '
            'option.');
  }
  if (!assertWebdevAvailable()) {
    return WebdevServeExecution.exitEarly(ExitCode.config.code);
  }
  final args = buildWebdevServeArgs(
      argResults: context.argResults,
      configuredBuildArgs: configuredBuildArgs,
      configuredWebdevArgs: configuredWebdevArgs,
      verbose: context.verbose);
  logSubprocessHeader(_log, 'pub ${args.join(' ')}'.trim());
  return WebdevServeExecution.process(
      ProcessDeclaration('pub', args, mode: ProcessStartMode.inheritStdio));
}

/// A dart_dev command that runs a local web development server for the current
/// project using the `webdev` package.
///
/// The default target for this command is `serve` (e.g. `ddev serve`), but
/// this is configurable in each project's `tool/dev.dart`.
///
/// This serve command can be configured by modifying any of the available
/// fields on an instance of this class, e.g.:
///     // tool/dev.dart
///     import 'package:dart_dev/tools/webdev_serve_tool.dart';
///
///     final config = {
///       'serve': WebdevServeCommand()
///         ..buildRunnerArgs = ['--delete-conflicting-outputs']
///         ..webdevServeArgs = ['--auto=restart']
///     }
// class WebdevServeCommand extends CommandBuilder {
//   /// The args to pass to the `build_runner` process via the `webdev serve`
//   /// process that will be run by this command.
//   ///
//   /// Run `pub run build_runner build -h` to see all available args.
//   List<String> buildRunnerArgs;

//   /// The default description for this serve command can be overridden by
//   /// setting this field to a non-null value.
//   ///
//   /// This description is used when printing the help text for this command as
//   /// well as the help text for the top-level `ddev` command runner.
//   @override
//   String description;

//   /// This command is not hidden from the `ddev` command runner by default, but
//   /// can be by setting this to `true`.
//   @override
//   bool hidden;

//   /// The args to pass to the `webdev serve` process that will be run by this
//   /// command.
//   ///
//   /// Run `pub global run webdev serve -h` to see all available args.
//   List<String> webdevServeArgs;

//   @override
//   Command<int> build(String commandName) => _WebdevServeCommand(
//         commandName,
//         buildRunnerArgs ?? <String>[],
//         description,
//         hidden,
//         webdevServeArgs ?? <String>[],
//       );
// }

// class _WebdevServeCommand extends Command<int> {
//   final List<String> _buildRunnerArgs;
//   final String _commandName;
//   final String _description;
//   final bool _hidden;
//   final List<String> _webdevServeArgs;

//   _WebdevServeCommand(
//     this._commandName,
//     this._buildRunnerArgs,
//     this._description,
//     this._hidden,
//     this._webdevServeArgs,
//   );

//   @override
//   String get name => _commandName ?? 'webdev_serve';

//   @override
//   String get description =>
//       _description ??
//       'Run a local web development server and a file system watcher that rebuilds on changes.';

//   @override
//   bool get hidden => _hidden ?? false;

//   @override
//   String get invocation =>
//       '${super.invocation.replaceFirst('[arguments]', '[dart_dev arguments]')} '
//       '[-- [webdev serve arguments]]';

//   @override
//   String get usageFooter => '\n'
//       'Run "webdev serve -h" to see the available webdev arguments.\n'
//       'You can use any of them with "dart_dev $name" by passing them after a '
//       '"--" separator.';

//   @override
//   Future<int> run() async {
//     assertNoPositionalArgs(name, argResults, usageException,
//         beforeSeparator: true);
//     if (!assertWebdevAvailable()) {
//       return ExitCode.config.code;
//     }
//     final args = buildWebdevServeArgs(
//         _webdevServeArgs, _buildRunnerArgs, argResults.rest);
//     _log.info('Running: pub ${args.join(' ')}\n');
//     final process =
//         await Process.start('pub', args, mode: ProcessStartMode.inheritStdio);
//     ensureProcessExit(process, log: _log);
//     return process.exitCode;
//   }
// }

/// Returns `true` if executables from `webdev` can be run in the current
/// project (i.e. it is globally activated), and `false` otherwise.
///
/// Also logs a SEVERE log if `webdev` is not available explaining why its
/// executable cannot be run and how to fix the issue.
bool assertWebdevAvailable() {
  if (!packageIsGloballyActivated('webdev')) {
    _log.severe(red.wrap('Cannot run "webdev serve".\n') +
        yellow.wrap('You must have "webdev" globally activated:\n'
            '  pub global activate webdev'));
    return false;
  }
  return true;
}

/// Builds and returns the args for the `webdev serve` process that will be run
/// by [WebdevServeCommand].
List<String> buildWebdevServeArgs(
    {ArgResults argResults,
    List<String> configuredBuildArgs,
    List<String> configuredWebdevArgs,
    bool verbose}) {
  final buildArgs = <String>[
    // Combine all args that should be passed through to the build_runner
    // process in this order:
    // 1. Statically configured args from [WebdevServeTool.buildArgs]
    if (configuredBuildArgs != null)
      ...configuredBuildArgs,
    // 2. Args passed to --build-args
    if (argResults != null && argResults['build-args'] != null)
      ...argResults['build-args'].split(' '),
  ];
  final webdevArgs = <String>[
    // Combine all args that should be passed through to the webdev serve
    // process in this order:
    // 1. Statically configured args from [WebdevServeTool.webdevArgs]
    if (configuredWebdevArgs != null)
      ...configuredWebdevArgs,
    // 2. Args passed to --test-args
    if (argResults != null && argResults['webdev-args'] != null)
      ...argResults['webdev-args'].split(' '),
  ];

  if (verbose == true) {
    if (!buildArgs.contains('-v') && !buildArgs.contains('--verbose')) {
      buildArgs.add('-v');
    }
    if (!webdevArgs.contains('-v') && !webdevArgs.contains('--verbose')) {
      webdevArgs.add('-v');
    }
  }

  return [
    'global',
    'run',
    'webdev',
    'serve',
    ...webdevArgs,
    if (buildArgs.isNotEmpty) '--',
    ...buildArgs,
  ];
}
