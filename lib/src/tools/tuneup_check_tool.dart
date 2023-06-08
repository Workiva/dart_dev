import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/arg_results_utils.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/executables.dart' as exe;
import '../utils/logging.dart';
import '../utils/package_is_immediate_dependency.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('TuneupCheck');

/// A dart_dev tool that runs the `tuneup` on the current project.
///
/// To use this tool in your project, include it in the dart_dev config in
/// `tool/dart_dev/config.dart`:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'analyze': TuneupCheckTool(),
///     };
///
/// This will make it available via the `dart_dev` command-line app like so:
///     dart run dart_dev analyze
///
/// This tool can be configured by modifying any of its fields:
///     // tool/dart_dev/config.dart
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'analyze': TuneupCheckTool()
///         ..ignoreInfos = true,
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     TuneupCheckTool().run();
class TuneupCheckTool extends DevTool {
  /// Whether `--ignore-infos` should be passed to `tuneup check`.
  bool? ignoreInfos;

  // ---------------------------------------------------------------------------
  // DevTool Overrides
  // ---------------------------------------------------------------------------

  @override
  final ArgParser argParser = ArgParser()
    ..addFlag('ignore-infos', help: 'Ignore any info level issues.');

  @override
  String? description = 'Run static analysis on dart files in this package '
      'using the tuneup tool.';

  @override
  FutureOr<int> run([DevToolExecutionContext? context]) async {
    final execution = buildExecution(context ?? DevToolExecutionContext(),
        configuredIgnoreInfos: ignoreInfos);
    return execution.exitCode ??
        await runProcessAndEnsureExit(execution.process!, log: _log);
  }
}

/// A declarative representation of an execution of the [TuneupCheckTool].
///
/// This class allows the [TuneupCheckTool] to break its execution up into
/// two steps:
/// 1. Validation of config/inputs and creation of this class.
/// 2. Execution of expensive or hard-to-test logic based on step 1.
///
/// As a result, nearly all of the logic in [TuneupCheckTool] can be tested
/// via the output of step 1 with very simple unit tests.
class TuneupExecution {
  TuneupExecution.exitEarly(this.exitCode) : process = null;
  TuneupExecution.process(this.process) : exitCode = null;

  /// If non-null, the execution is already complete and the
  /// [TuneupCheckTool] should exit with this code.
  ///
  /// If null, there is more work to do.
  final int? exitCode;

  /// A declarative representation of the test process that should be run.
  ///
  /// This process' result should become the final result of the
  /// [TuneupCheckTool].
  final ProcessDeclaration? process;
}

/// Returns a combined list of args for the `tuneup` process.
///
/// If [verbose] is true and the verbose flag (`-v`) is not already included, it
/// will be added.
Iterable<String> buildArgs({
  ArgResults? argResults,
  bool? configuredIgnoreInfos,
  bool verbose = false,
}) {
  var ignoreInfos = (configuredIgnoreInfos ?? false) ||
      (flagValue(argResults, 'ignore-infos') ?? false);
  return [
    'run',
    'tuneup',
    'check',
    if (ignoreInfos) '--ignore-infos',
    if (verbose) '--verbose',
  ];
}

/// Returns a declarative representation of an tuneup process to run based on
/// the given parameters.
///
/// These parameters will be populated from [TuneupCheckTool] when it is
/// executed (either directly or via a command-line app).
///
/// [context] is the execution context that would be provided by
/// [TuneupCheckTool] when converted to a [DevToolCommand]. For tests, this
/// can be manually created to imitate the various CLI inputs.
///
/// If non-null, [path] will override the current working directory for any
/// operations that require it. This is intended for use by tests.
///
/// The [TuneupCheckTool] can be tested almost completely via this function
/// by enumerating all of the possible parameter variations and making
/// assertions on the declarative output.
TuneupExecution buildExecution(
  DevToolExecutionContext context, {
  bool? configuredIgnoreInfos,
  String? path,
}) {
  final argResults = context.argResults;
  if (argResults != null) {
    assertNoPositionalArgsNorArgsAfterSeparator(
        argResults, context.usageException,
        commandName: context.commandName);
  }

  if (!packageIsImmediateDependency('tuneup', path: path)) {
    _log.severe(red.wrap('Cannot run "tuneup check".\n')! +
        yellow.wrap(
            'You must have a dependency on "tuneup" in pubspec.yaml.\n')!);
    return TuneupExecution.exitEarly(ExitCode.config.code);
  }

  final args = buildArgs(
    argResults: argResults,
    configuredIgnoreInfos: configuredIgnoreInfos,
    verbose: context.verbose,
  ).toList();
  logSubprocessHeader(_log, 'dart ${args.join(' ')}');
  return TuneupExecution.process(
      ProcessDeclaration(exe.dart, args, mode: ProcessStartMode.inheritStdio));
}
