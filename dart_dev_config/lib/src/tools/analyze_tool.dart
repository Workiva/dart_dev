import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/logging.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('Analyze');

/// A dart_dev tool that runs the `dartanalyzer` on the current project.
///
/// To use this tool in your project, include it in the dart_dev config in
/// `tool/dev.dart`:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'analyze': AnalyzeTool(),
///     };
///
/// This will make it available via the `dart_dev` command-line app like so:
///     pub run dart_dev analyze
///
/// This tool can be configured by modifying any of its fields:
///     // tool/dev.dart
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'analyze': AnalyzeTool()
///         ..dartanalyzerArgs = ['--fatal-infos']
///         ..include = [Glob('.'), Glob('other/**.dart')],
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     AnalyzeTool().run();
class AnalyzeTool extends DevTool {
  /// The args to pass to the `dartanalyzer` process run by this tool.
  ///
  /// Run `dartanalyzer -h -v` to see all available args.
  List<String> analyzerArgs;

  @override
  String description = 'Run static analysis on dart files in this package.';

  /// The globs to include as entry points to run static analysis on.
  ///
  /// The default is `.` (e.g. `dartanalyzer .`) which runs analysis on all
  /// public entry points in `lib/` and all dart files in other known
  /// directories (`benchmark/`, `bin/`, `example/`, `test/`, `tool/`, `web/`),
  /// as well as any dart files in the project root.
  List<Glob> include;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) =>
      runProcessAndEnsureExit(buildProcess(context ?? DevToolExecutionContext(),
          configuredAnalyzerArgs: analyzerArgs, include: include));

  @override
  Command<int> toCommand(String name) => DevToolCommand(name, this,
      argParser: ArgParser()
        ..addOption('analyzer-args',
            help: 'Args to pass to the "dartanalyzer" process.\n'
                'Run "dartanalyzer -h -v" to see all available options.'));
}

/// Returns a combined list of args for the `dartanalyzer` process.
///
/// If [configuredAnalyzerArgs] is non-null, they will be included first.
///
/// If [argResults] is non-null and the `--analyzer-args` option is non-null,
/// they will be included second.
///
/// If [verbose] is true and the verbose flag (`-v`) is not already included, it
/// will be added.
Iterable<String> buildArgs({
  ArgResults argResults,
  List<String> configuredAnalyzerArgs,
  bool verbose,
}) {
  verbose ??= false;
  final args = <String>[
    // Combine all args that should be passed through to the dartanalyzer in
    // this order:
    // 1. Statically configured args from [AnalyzeTool.analyzerArgs]
    if (configuredAnalyzerArgs != null)
      ...configuredAnalyzerArgs,
    // 2. Args passed to --analyzer-args
    if (argResults != null && argResults['analyzer-args'] != null)
      ...argResults['analyzer-args'].split(' '),
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
Iterable<String> buildEntrypoints({List<Glob> include, String root}) {
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
/// The [AnalyzeTool] can be tested almost completely via this function by
/// enumerating all of the possible parameter variations and making assertions
/// on the declarative output.
ProcessDeclaration buildProcess(
  DevToolExecutionContext context, {
  List<String> configuredAnalyzerArgs,
  List<Glob> include,
  String path,
}) {
  if (context.argResults != null) {
    assertNoPositionalArgsNorArgsAfterSeparator(
        context.argResults, context.usageException,
        commandName: context.commandName,
        usageFooter:
            'Arguments can be passed to the "dartanalyzer" process via '
            'the --analyzer-args option.');
  }
  final args = buildArgs(
      argResults: context.argResults,
      configuredAnalyzerArgs: configuredAnalyzerArgs,
      verbose: context.verbose);
  final entrypoints = buildEntrypoints(include: include, root: path);
  logCommand(args, entrypoints, verbose: context.verbose);
  return ProcessDeclaration('dartanalyzer', [...args, ...entrypoints],
      mode: ProcessStartMode.inheritStdio);
}

/// Logs the `dartanalyzer` command that will be run by [AnalyzeTool] so that
/// consumers can run it directly for debugging purposes.
///
/// Unless [verbose] is true, the list of entrypoints will be abbreviated to
/// avoid an unnecessarily long log.
void logCommand(
  Iterable<String> args,
  Iterable<String> entrypoints, {
  bool verbose,
}) {
  verbose ??= false;
  final exeAndArgs = 'dartanalyzer ${args.join(' ')}'.trim();
  if (entrypoints.length <= 5 || verbose) {
    logSubprocessHeader(_log, '$exeAndArgs ${entrypoints.join(' ')}');
  } else {
    logSubprocessHeader(_log, '$exeAndArgs <${entrypoints.length} paths>');
  }
}

/// TODO: This may be a useful util, but is currently unused and will remain
///       private until a need arises (or alternatively we delete it).
///
/// Returns a list of Globs that match all of the standard Dart project
/// analysis entry points:
/// - public dart files in lib/ (i.e. not in lib/src/)
/// - all dart files in benchmark/, bin/, example/, test/, tool/, and web/
///
/// Normally, using the default include glob of `.` is sufficient for most
/// projects. However, if customization is needed, this method may help.
List<Glob> buildAnalyzerIncludeGlobs({
  bool includeBenchmark,
  bool includeBin,
  bool includeExample,
  bool includeLib,
  bool includeRoot,
  bool includeTest,
  bool includeTool,
  bool includeWeb,
}) =>
    [
      // All public entry points (dart files in lib/ except those in lib/src/).
      if (includeLib != false) ...[
        Glob('lib/*.dart'),
        Glob('lib/?/**.dart'),
        Glob('lib/??/**.dart'),
        Glob('lib/[^s][^r][^c]*/**.dart'),
      ],

      // All dart files in the rest of the standard dart project directories.
      if (includeBenchmark != false)
        Glob('benchmark/**.dart'),
      if (includeBin != false)
        Glob('bin/**.dart'),
      if (includeExample != false)
        Glob('example/**.dart'),
      if (includeTest != false)
        Glob('test/**.dart'),
      if (includeTool != false)
        Glob('tool/**.dart'),
      if (includeWeb != false)
        Glob('web/**.dart'),

      // All top-level dart files.
      if (includeRoot != false)
        Glob('*.dart'),
    ];
