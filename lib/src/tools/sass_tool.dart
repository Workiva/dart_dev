import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/src/tools/dart_function_tool.dart';
import 'package:dart_dev/src/utils/package_is_immediate_dependency.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/arg_results_utils.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/logging.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('Sass');

/// A dart_dev tool that compiles SCSS files in the current project to CSS via
/// the `w_common:compile_sass` executable.
///
/// To use this tool in your project, include it in the dart_dev config in
/// `tool/dev.dart`:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'sass': SassTool(),
///     };
///
/// This will make it available via the `dart_dev` command-line app like so:
///     pub run dart_dev sass
///
/// This tool can be configured by modifying any of its fields:
///     // tool/dev.dart
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'sass': SassTool()
///         ..compileSassArgs = ['--watchDirs', 'sass']
///         ..sourceDir = 'lib/',
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     SassTool().run();
class SassTool extends DevTool {
  /// The args to pass to the `pub run w_common:compile_sass` process run by
  /// this tool.
  ///
  /// Run `pub run w_common:compile_sass -h` to see all available args.
  List<String> compileSassArgs;

  String fileExtension;

  String outputDir;

  SassOutputStyle outputStyle;

  String sourceDir;

  @override
  String description = 'Compile SASS files in this project to CSS.';

  @override
  FutureOr<int> run([DevToolExecutionContext context]) {
    context ??= DevToolExecutionContext();
    final execution = buildExecution(context,
        configuredCompileSassArgs: compileSassArgs,
        outputDir: outputDir,
        outputStyle: outputStyle,
        sourceDir: sourceDir);
    if (execution.exitCode != null) {
      return execution.exitCode;
    }
    logSubprocessHeader(_log,
        '${execution.process.executable} ${execution.process.args.join(' ')}');
    return execution.exitCode ?? runProcessAndEnsureExit(execution.process);
  }

  @override
  Command<int> toCommand(String name) => DevToolCommand(name, this,
      argParser: ArgParser()
        ..addFlag('check',
            abbr: 'c',
            negatable: false,
            help:
                'When set to true, no `.css` outputs will be written to disk, '
                '\nand a non-zero exit code will be returned if '
                '`sass.compile()` \nproduces results that differ from those '
                'found in the committed \n`.css` files. \nIntended only for '
                'use as a CI safeguard.')
        // ..addFlag('release',
        //     negatable: false,
        //     abbr: 'r',
        //     help:
        //         'Whether to compile minified CSS for bundling with a pub '
        //         'package. \nTypically only set during a CI run. \n'
        //         'A check of the unminified output will be performed first.')
        ..addFlag('watch',
            negatable: false,
            help: 'Watch stylesheets and recompile when they change.')
        ..addSeparator('======== Other Options')
        ..addOption('compile-sass-args',
            help:
                'Args to pass to the "pub run w_common:compile_sass" process.\n'
                'Run "pub run w_common:compile_sass -h" to see all available '
                'options.'));

  DartFunctionTool toReleaseSassTool() => DartFunctionTool((_context) async {
        final context = DevToolExecutionContext(verbose: _context.verbose);

        final preReleaseCheckTool = SassTool()
          ..compileSassArgs = [...(compileSassArgs ?? []), '--check']
          ..fileExtension = fileExtension
          ..outputDir = outputDir
          ..outputStyle = outputStyle
          ..sourceDir = sourceDir;
        final preReleaseCheckCode = await preReleaseCheckTool.run(context);
        if (preReleaseCheckCode != 0) {
          return preReleaseCheckCode;
        }

        final releaseSassTool = SassTool()
          ..compileSassArgs = compileSassArgs
          ..fileExtension = fileExtension ?? '.css'
          ..outputDir = outputDir
          ..outputStyle = SassOutputStyle.compressed
          ..sourceDir = sourceDir;
        return releaseSassTool.run(context);
      });
}

enum SassOutputStyle {
  compressed,
  expanded,
}

/// A declarative representation of an execution of the [SassTool].
///
/// This class allows the [SassTool] to break its execution up into two steps:
/// 1. Validation of confg/inputs and creation of this class.
/// 2. Execution of expensive or hard-to-test logic based on step 1.
///
/// As a result, nearly all of the logic in [SassTool] can be tested via the
/// output of step 1 (an instance of this class) with very simple unit tests.
class CompileSassExecution {
  CompileSassExecution.exitEarly(this.exitCode) : process = null;
  CompileSassExecution.process(this.process) : exitCode = null;

  /// If non-null, the execution is already complete and the [SassTool] should
  /// exit with this code.
  ///
  /// If null, there is more work to do.
  final int exitCode;

  /// A declarative representation of the `pub run w_common:compile_sass`
  /// process that should be run.
  ///
  /// This process' result should become the final result of the [SassTool].
  final ProcessDeclaration process;

  // /// A declarative representation of the `pub run w_common:compile_sass`
  // /// process that is identical to [process] except that it will run in
  // /// `--check` mode and i
  // final ProcessDeclaration releaseCheckProcess;
}

/// Returns a combined list of args for the `pub run w_common:compile_sass`
/// process.
///
/// If [configuredCompileSassArgs] is non-null, they will be included first.
///
/// If [argResults] is non-null and the `--compile-sass-args` option is
/// non-null, they will be included second.
Iterable<String> buildArgs({
  ArgResults argResults,
  List<String> configuredCompileSassArgs,
  String outputDir,
  SassOutputStyle outputStyle,
  String sourceDir,
}) =>
    [
      'run',
      'w_common:compile_sass',
      // Combine all args that should be passed through to the compile_sass
      // executable in this order:
      // 1. Args configured on the [SassTool] instance.
      if (sourceDir != null)
        '--sourceDir=$sourceDir',
      if (outputDir != null)
        '--outputDir=$outputDir',
      // Compressed is the default, but this tool adds support for a "release"
      // mode so we actually want to default to expanded.
      if (outputStyle == null || outputStyle == SassOutputStyle.expanded)
        '--outputStyle=expanded',
      // if (outputStyle == SassOutputStyle.expanded) '--outputStyle=expanded',
      // 2. The --check and --watch proxy flags, if provided.
      if (getFlagValue(argResults, 'check'))
        '--check',
      if (getFlagValue(argResults, 'watch'))
        '--watch',
      // 3. Statically configured args from [SassTool.compileSassArgs]
      ...configuredCompileSassArgs ?? <String>[],
      // 4. Args passed to --compile-sass-args
      ...splitSingleOptionValue(argResults, 'compile-sass-args'),
    ];

/// Returns a declarative representation of an compile_sass process to run
/// based on the given parameters.
///
/// These parameters will be populated from [SassTool] when it is executed
/// (either directly or via a command-line app).
///
/// [context] is the execution context that would be provided by [SassTool]
/// when converted to a [DevToolCommand]. For tests, this can be manually
/// created to imitate the various CLI inputs.
///
/// [configuredCompileSassArgs] will be populated from
/// [SassTool.compileSassArgs].
///
/// If non-null, [path] will override the current working directory for any
/// operations that require it. This is intended for use by tests.
///
/// The [SassTool] can be tested almost completely via this function by
/// enumerating all of the possible parameter variations and making assertions
/// on the declarative output.
CompileSassExecution buildExecution(
  DevToolExecutionContext context, {
  List<String> configuredCompileSassArgs,
  String outputDir,
  SassOutputStyle outputStyle,
  String sourceDir,
  String path,
}) {
  // var releaseMode = false;
  if (context.argResults != null) {
    // releaseMode = context.argResults['release'] ?? false;
    assertNoPositionalArgsNorArgsAfterSeparator(
        context.argResults, context.usageException,
        commandName: context.commandName,
        usageFooter:
            'Arguments can be passed to the "pub run w_common:compile_sass" '
            'process via the --compile-sass-args option.');
  }
  if (!packageIsImmediateDependency('w_common', path: path)) {
    _log.severe(red.wrap('Cannot run "w_common:compile_sass".\n') +
        yellow.wrap(
            'You must have a dependency on `w_common` in `pubspec.yaml`.\n') +
        '# pubspec.yaml\n'
            'dev_dependencies:\n'
            '  w_common: ^1.20.0');
    return CompileSassExecution.exitEarly(ExitCode.config.code);
  }

  final args = buildArgs(
      argResults: context.argResults,
      configuredCompileSassArgs: configuredCompileSassArgs,
      outputDir: outputDir,
      outputStyle: outputStyle,
      sourceDir: sourceDir);
  return CompileSassExecution.process(
      ProcessDeclaration('pub', args, mode: ProcessStartMode.inheritStdio));
}
