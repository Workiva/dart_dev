import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/arg_results_utils.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/dart_semver_version.dart';
import '../utils/executables.dart' as exe;
import '../utils/logging.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('Analyze');

/// A dart_dev tool that runs the `dartanalyzer` or `dart analyze` on the current project.
/// If the `useDartAnalyze` flag is not specified it will default to `dartanalyzer`.
///
/// To use this tool in your project, include it in the dart_dev config in
/// `tool/dart_dev/config.dart`:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'analyze': AnalyzeTool() ..useDartAnalyze = true,
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
///       'analyze': AnalyzeTool()
///         ..analyzerArgs = ['--fatal-infos']
///         ..include = [Glob('.'), Glob('other/**.dart')],
///         ..useDartAnalyze = true
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     AnalyzeTool().run();
class AnalyzeTool extends DevTool {
  /// The args to pass to the `dartanalyzer`  or `dart analyze` process run by this tool.
  ///
  /// Run `dartanalyzer -h -v` or `dart analyze -h -v` to see all available args.
  List<String>? analyzerArgs;

  /// The globs to include as entry points to run static analysis on.
  ///
  /// The default is `.` (e.g. `dartanalyzer .`) which runs analysis on all Dart
  /// files in the current working directory.
  List<Glob>? include;

  /// The default tool for analysis will be `dartanalyzer` unless opted in here
  /// to utilize `dart analyze`.
  bool? useDartAnalyze;

  // ---------------------------------------------------------------------------
  // DevTool Overrides
  // ---------------------------------------------------------------------------

  @override
  final ArgParser argParser = ArgParser()
    ..addOption('analyzer-args',
        help: 'Args to pass to the "dartanalyzer" or "dart analyze" process.\n'
            'Run "dartanalyzer -h -v" or `dart analyze -h -v" to see all available options.');

  @override
  String? description = 'Run static analysis on dart files in this package.';

  @override
  FutureOr<int?> run([DevToolExecutionContext? context]) {
    return runProcessAndEnsureExit(
        buildProcess(
          context ?? DevToolExecutionContext(),
          configuredAnalyzerArgs: analyzerArgs,
          include: include,
          useDartAnalyze:
              !dartVersionHasDartanalyzer ? true : useDartAnalyze ?? false,
        ),
        log: _log);
  }
}

/// Returns a combined list of args for the `dartanalyzer`
/// or `dart analyze` process.
///
/// If [configuredAnalyzerArgs] is non-null, they will be included first.
///
/// If [argResults] is non-null and the `--analyzer-args` option is non-null,
/// they will be included second.
///
/// If [verbose] is true and the verbose flag (`-v`) is not already included, it
/// will be added.
Iterable<String> buildArgs(
    {ArgResults? argResults,
    List<String>? configuredAnalyzerArgs,
    bool useDartAnalyze = false,
    bool verbose = false}) {
  final args = <String>[
    // Combine all args that should be passed through to the analyzer in
    // this order:
    // 1. The analyze command if using dart analyze
    if (useDartAnalyze) 'analyze',
    // 2. Statically configured args from [AnalyzeTool.analyzerArgs]
    ...?configuredAnalyzerArgs,
    // 3. Args passed to --analyzer-args
    ...?splitSingleOptionValue(argResults, 'analyzer-args'),
  ];
  if (verbose && !args.contains('-v') && !args.contains('--verbose')) {
    args.add('-v');
  }
  return args;
}

/// Returns the entrypoint paths obtained by expanding the given [include] globs
/// and returning a default of `['.']` if none were found.
///
/// By default these globs are assumed to be relative to the current working
/// directory, but that can be overridden via [root] for testing purposes.
Iterable<String> buildEntrypoints({List<Glob>? include, String? root}) {
  include ??= <Glob>[];
  final entrypoints = <String>{
    for (final glob in include)
      ...glob
          .listSync(root: root)
          .where((entity) => entity is File || entity is Directory)
          .map((entity) => entity.path),
  };
  if (entrypoints.isEmpty) {
    entrypoints.add('.');
  }
  return entrypoints;
}

/// Returns a declarative representation of an analyzer process to run based on
/// the given parameters.
///
/// These parameters will be populated from [AnalyzeTool] when it is executed
/// (either directly or via a command-line app).
///
/// [context] is the execution context that would be provided by [AnalyzeTool]
/// when converted to a [DevToolCommand]. For tests, this can be manually
/// created to imitate the various CLI inputs.
///
/// [configuredAnalyzerArgs] will be populated from [AnalyzeTool.analyzerArgs].
///
/// [include] will be populated from [AnalyzeTool.include].
///
/// If non-null, [path] will override the current working directory for any
/// operations that require it. This is intended for use by tests.
///
/// If true, [useDartAnalyze] will utilize `dart analyze` for analysis.
/// If null, it will default to utilze `dartanalyzer`.
///
/// The [AnalyzeTool] can be tested almost completely via this function by
/// enumerating all of the possible parameter variations and making assertions
/// on the declarative output.
ProcessDeclaration buildProcess(
  DevToolExecutionContext context, {
  List<String>? configuredAnalyzerArgs,
  List<Glob>? include,
  String? path,
  bool useDartAnalyze = false,
}) {
  final argResults = context.argResults;
  if (argResults != null) {
    final analyzerUsed = useDartAnalyze ? 'dart analyze' : 'dartanalyzer';
    assertNoPositionalArgsNorArgsAfterSeparator(
        argResults, context.usageException,
        commandName: context.commandName,
        usageFooter:
            'Arguments can be passed to the "$analyzerUsed" process via '
            'the --analyzer-args option.');
  }
  var executable = useDartAnalyze ? exe.dart : exe.dartanalyzer;
  final args = buildArgs(
      argResults: context.argResults,
      configuredAnalyzerArgs: configuredAnalyzerArgs,
      verbose: context.verbose,
      useDartAnalyze: useDartAnalyze);
  final entrypoints = buildEntrypoints(include: include, root: path);
  logCommand(args, entrypoints,
      verbose: context.verbose, useDartAnalyzer: useDartAnalyze);
  return ProcessDeclaration(executable, [...args, ...entrypoints],
      mode: ProcessStartMode.inheritStdio);
}

/// Logs the `dartanalyzer` or `dart analyze` command that will be run by [AnalyzeTool] so that
/// consumers can run it directly for debugging purposes.
///
/// Unless [verbose] is true, the list of entrypoints will be abbreviated to
/// avoid an unnecessarily long log.
void logCommand(
  Iterable<String> args,
  Iterable<String> entrypoints, {
  bool useDartAnalyzer = false,
  bool verbose = false,
}) {
  final exeAndArgs =
      '${useDartAnalyzer ? "dart" : "dartanalyzer"} ${args.join(' ')}'.trim();

  if (entrypoints.length <= 5 || verbose) {
    logSubprocessHeader(_log, '$exeAndArgs ${entrypoints.join(' ')}');
  } else {
    logSubprocessHeader(_log, '$exeAndArgs <${entrypoints.length} paths>');
  }
}
