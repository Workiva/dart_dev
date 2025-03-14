import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';

import '../dart_dev_tool.dart';
import '../utils/arg_results_utils.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/dart_semver_version.dart';
import '../utils/executables.dart' as exe;
import '../utils/global_package_is_active_and_compatible.dart';
import '../utils/logging.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('WebdevServe');

/// A dart_dev tool that runs a local web development server for the current
/// project using the `webdev` package.
///
/// To use this tool in your project, include it in the dart_dev config in
/// `tool/dart_dev/config.dart`:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'serve': WebdevServeTool(),
///     };
///
/// This will make it available via the `dart_dev` command-line app like so:
///     dart run dart_dev serve
///
/// This tool can be configured by modifying any of its fields:
///     // tool/dart_dev/config.dart
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'serve': WebdevServeTool()
///         ..buildArgs = ['--delete-conflicting-outputs']
///         ..webdevArgs = ['--debug', 'example:8080', 'web:8081']
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     WebdevServeTool().run();
class WebdevServeTool extends DevTool {
  /// The args to pass to the `build_runner` process via the `webdev serve`
  /// process that will be run by this tool.
  ///
  /// Run `dart run build_runner build -h` to see all available args.
  List<String>? buildArgs;

  /// The args to pass to the `webdev serve` process that will be run by this
  /// tool.
  ///
  /// Run `dart pub global run webdev serve -h` to see all available args.
  List<String>? webdevArgs;

  // ---------------------------------------------------------------------------
  // DevTool Overrides
  // ---------------------------------------------------------------------------

  @override
  final ArgParser argParser = ArgParser()
    ..addFlag('release',
        abbr: 'r', help: 'Build with release mode defaults for builders.')
    ..addSeparator('======== Other Options')
    ..addOption('webdev-args',
        help: 'Args to pass to the webdev serve process.\n'
            'Run "dart pub global run webdev serve -h -v" to see all available '
            'options.')
    ..addOption('build-args',
        help: 'Args to pass to the build runner process.\n'
            'Run "dart run build_runner build -h -v" to see all available '
            'options.');

  @override
  String? description = 'Run a local web development server and a file system '
      'watcher that rebuilds on changes.';

  @override
  FutureOr<int?> run([DevToolExecutionContext? context]) async {
    context ??= DevToolExecutionContext();
    final execution = buildExecution(context,
        configuredBuildArgs: buildArgs, configuredWebdevArgs: webdevArgs);
    return execution.exitCode ??
        await runProcessAndEnsureExit(execution.process!, log: _log);
  }
}

/// A declarative representation of an execution of the [WebdevServeTool].
///
/// This class allows the [WebdevServeTool] to break its execution up into two
/// steps:
/// 1. Validation of config/inputs and creation of this class.
/// 2. Execution of expensive or hard-to-test logic based on step 1.
///
/// As a result, nearly all of the logic in [WebdevServeTool] can be tested via
/// the output of step 1 with very simple unit tests.
class WebdevServeExecution {
  WebdevServeExecution.exitEarly(this.exitCode) : process = null;
  WebdevServeExecution.process(this.process) : exitCode = null;

  /// If non-null, the execution is already complete and the [WebdevServeTool]
  /// should exit with this code.
  ///
  /// If null, there is more work to do.
  final int? exitCode;

  /// A declarative representation of the webdev process that should be run.
  ///
  /// This process' result should become the final result of the
  /// [WebdevServeTool].
  final ProcessDeclaration? process;
}

/// Builds and returns the full list of args for the webdev serve process that
/// [WebdevServeTool] will start.
///
/// Since the `webdev` tool wraps a `build_runner` process, the returned list of
/// args will be two portions with an arg separator between them, e.g.:
///     dart pub global run webdev serve <webdev args> -- <build args>
///
/// When building the webdev args portion of the list, the
/// [configuredWebdevArgs] will be included first (if non-null) followed by the
/// value of the `--webdev-args` option if it and [argResults] are non-null.
///
/// When building the build args portion of the list, the [configuredBuildArgs]
/// will be included first (if non-null), followed by the value of the
/// `--build-args` option if it and [argResults] are non-null
///
/// If [verbose] is true, both the webdev args and the build args portions of
/// the returned list will include the `-v` verbose flag.
List<String> buildArgs(
    {ArgResults? argResults,
    List<String>? configuredBuildArgs,
    List<String>? configuredWebdevArgs,
    bool verbose = false}) {
  final webdevArgs = <String>[
    // Combine all args that should be passed through to the webdev serve
    // process in this order:
    // 1. Statically configured args from [WebdevServeTool.webdevArgs]
    ...?configuredWebdevArgs,
    // 2. The -r|--release flag
    if (argResults != null && argResults['release']) '--release',
    // 3. Args passed to --webdev-args
    ...?splitSingleOptionValue(argResults, 'webdev-args'),
  ];
  final buildArgs = <String>[
    // Combine all args that should be passed through to the build_runner
    // process in this order:
    // 1. Statically configured args from [WebdevServeTool.buildArgs]
    ...?configuredBuildArgs,
    // 2. Args passed to --build-args
    ...?splitSingleOptionValue(argResults, 'build-args'),
  ];

  if (verbose) {
    if (!buildArgs.contains('-v') && !buildArgs.contains('--verbose')) {
      buildArgs.add('-v');
    }
    if (!webdevArgs.contains('-v') && !webdevArgs.contains('--verbose')) {
      webdevArgs.add('-v');
    }
  }

  return [
    'pub',
    'global',
    'run',
    'webdev',
    'serve',
    ...webdevArgs,
    if (buildArgs.isNotEmpty) '--',
    ...buildArgs,
  ];
}

/// Returns a declarative representation of a webdev process to run based on the
/// given parameters.
///
/// These parameters will be populated from [WebdevServeTool] when it is
/// executed (either directly or via a command-line app).
///
/// [context] is the execution context that would be provided by
/// [WebdevServeTool] when converted to a [DevToolCommand]. For tests, this can
/// be manually created to imitate the various CLI inputs.
///
/// [configuredWebdevArgs] will be populated from [WebdevServeTool.webdevArgs].
///
/// [configuredBuildArgs] will be populated from [WebdevServeTool.buildArgs].
///
/// If non-null, [path] will override the current working directory for any
/// operations that require it. This is intended for use by tests.
///
/// The [WebdevServeTool] can be tested almost completely via this function by
/// enumerating all of the possible parameter variations and making assertions
/// on the declarative output.
WebdevServeExecution buildExecution(
  DevToolExecutionContext context, {
  List<String>? configuredBuildArgs,
  List<String>? configuredWebdevArgs,
  Map<String, String>? environment,
}) {
  final argResults = context.argResults;
  if (argResults != null) {
    assertNoPositionalArgsNorArgsAfterSeparator(
        argResults, context.usageException,
        commandName: context.commandName,
        usageFooter: 'Arguments can be passed to the webdev process via the '
            '--webdev-args option.\n'
            'Arguments can be passed to the build process via the --build-args '
            'option.');
  }

  final webdevVersion = dartSemverVersion.major == 2 ? '^2.0.0' : '^3.0.0';

  if (!globalPackageIsActiveAndCompatible(
      'webdev', VersionConstraint.parse(webdevVersion),
      environment: environment)) {
    _log.severe(red.wrap(
            '${styleBold.wrap('webdev serve')} could not run for this project.\n')! +
        yellow.wrap('You must have `webdev` globally activated:\n'
            '  dart pub global activate webdev ${webdevVersion}')!);
    return WebdevServeExecution.exitEarly(ExitCode.config.code);
  }

  final args = buildArgs(
      argResults: argResults,
      configuredBuildArgs: configuredBuildArgs,
      configuredWebdevArgs: configuredWebdevArgs,
      verbose: context.verbose);
  logSubprocessHeader(_log, 'dart ${args.join(' ')}'.trim());
  return WebdevServeExecution.process(
      ProcessDeclaration(exe.dart, args, mode: ProcessStartMode.inheritStdio));
}
