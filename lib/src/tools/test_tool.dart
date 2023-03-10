import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/arg_results_utils.dart';
import '../utils/executables.dart' as exe;
import '../utils/logging.dart';
import '../utils/package_is_immediate_dependency.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('Test');

/// A dart_dev tool that runs dart tests for the current project.
///
/// Tests will be run via `dart test` unless the current project depends on
/// `build_test`, in which case it will run tests via
/// `dart run build_runner test`.
///
/// To use this tool in your project, include it in the dart_dev config in
/// `tool/dart_dev/config.dart`:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'test': TestTool(),
///     };
///
/// This will make it available via the `dart_dev` command-line app like so:
///     dart run dart_dev test
///
/// This tool can be configured by modifying any of its fields:
///     // tool/dart_dev/config.dart
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'test': TestTool()
///         ..buildArgs = ['--delete-conflicting-outputs']
///         ..testArgs = ['-P', 'unit'],
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     TestTool().run();
class TestTool extends DevTool {
  @override
  final ArgParser argParser = ArgParser()
    ..addSeparator('======== Selecting Tests')
    ..addMultiOption('name',
        abbr: 'n',
        help: 'A substring of the name of the test to run.\n'
            'Regular expression syntax is supported.\n'
            'If passed multiple times, tests must match all substrings.',
        splitCommas: false)
    ..addMultiOption('plain-name',
        abbr: 'N',
        help: 'A plain-text substring of the name of the test to run.\n'
            'If passed multiple times, tests must match all substrings.',
        splitCommas: false)
    ..addSeparator('======== Running Tests')
    ..addMultiOption('preset',
        abbr: 'P', help: 'The configuration preset(s) to use.')
    ..addFlag('release',
        help: 'Build with release mode defaults for builders.\n'
            'This only applies in projects that run tests with build_runner.')
    ..addSeparator('======== Output')
    ..addOption('reporter',
        help: 'The runner used to print test results.',
        allowed: [
          'compact',
          'expanded',
          'json'
        ],
        allowedHelp: {
          'compact': 'A single line, updated continuously.',
          'expanded': 'A separate line for each update.',
          'json': 'A machine-readable format (see https://goo.gl/gBsV1a).'
        })
    ..addSeparator('======== Other Options')
    ..addOption('test-stdout',
        help: 'Write the test process stdout to this file path.')
    ..addOption('test-args',
        help: 'Args to pass to the test runner process.\n'
            'Run "dart test -h" to see all available options.')
    ..addOption('build-args',
        help: 'Args to pass to the build runner process.\n'
            'Run "dart run build_runner test -h" to see all available '
            'options.\n'
            'Note: these args are only applicable if the current project '
            'depends on "build_test".');

  /// The args to pass to the `dart run build_runner test` process that will be
  /// run by this command when the current project depends on `build_test`.
  ///
  /// Run `dart run build_runner test -h` to see all available args.
  List<String>? buildArgs;

  @override
  String? description = 'Run dart tests in this package.';

  /// The args to pass to the `dart test` process (either directly or
  /// through the `dart run build_runner test` process if applicable).
  ///
  /// Run `dart test -h` to see all available args.
  ///
  /// Note that most of the command-line options for the `dart test` process
  /// also have `dart_test.yaml` configuration counterparts. Rather than
  /// configuring this field, it is preferred that the project be configured via
  /// `dart_test.yaml` so that the configuration is used even when running tests
  /// through some means other than `ddev`.
  List<String>? testArgs;

  @override
  FutureOr<int?> run([DevToolExecutionContext? context]) {
    context ??= DevToolExecutionContext();
    final execution = buildExecution(context,
        configuredBuildArgs: buildArgs, configuredTestArgs: testArgs);
    if (execution.exitCode != null) {
      return execution.exitCode;
    }
    return runProcessAndEnsureExit(execution.process!, log: _log);
  }

  @override
  Command<int> toCommand(String name) => TestToolCommand(name, this);
}

class TestToolCommand extends DevToolCommand {
  TestToolCommand(String name, DevTool devTool) : super(name, devTool);

  @override
  String get usage =>
      super.usage.replaceFirst('[arguments]', '[files or directories...]');
}

/// A declarative representation of an execution of the [TestTool].
///
/// This class allows the [TestTool] to break its execution up into two steps:
/// 1. Validation of config/inputs and creation of this class.
/// 2. Execution of expensive or hard-to-test logic based on step 1.
///
/// As a result, nearly all of the logic in [TestTool] can be tested via the
/// output of step 1 with very simple unit tests.
class TestExecution {
  TestExecution.exitEarly(this.exitCode) : process = null;
  TestExecution.process(this.process) : exitCode = null;

  /// If non-null, the execution is already complete and the [TestTool] should
  /// exit with this code.
  ///
  /// If null, there is more work to do.
  final int? exitCode;

  /// A declarative representation of the test process that should be run.
  ///
  /// This process' result should become the final result of the [TestTool].
  final ProcessDeclaration? process;
}

/// Builds and returns the full list of args for the test process that
/// [TestTool] will start.
///
/// If [useBuildRunner] is true, the returned args will run tests via
/// `dart run build_runner test`. Additional args targeting the build process
/// will immediately follow and args targeting the test process will follow an
/// arg separator (`--`).
///
/// If [useBuildRunner] is false, the returned args will run tests via
/// `dart test` and additional args targeting the test process will follow
/// immediately. Build args will be ignored.
///
/// When building the build args portion of the list, the [configuredBuildArgs]
/// will be included first (if non-null) followed by the value of the
/// `--build-args` option if it and [argResults] are non-null.
///
/// When building the test args portion of the list, the [configuredTestArgs]
/// will be included first (if non-null), followed by the value of the
/// `--test-args` option if it and [argResults] are non-null, followed by any
/// remaining positional args passed directly to the [TestTool] command.
///
/// If [verbose] is true, both the build args and the test args portions of the
/// returned list will include the `-v` verbose flag.
List<String> buildArgs({
  ArgResults? argResults,
  List<String>? configuredBuildArgs,
  List<String>? configuredTestArgs,
  bool useBuildRunner = false,
  bool verbose = false,
}) {
  final buildArgs = <String>[
    // Combine all args that should be passed through to the build_runner
    // process in this order:
    // 1. Statically configured args from [WebdevServeTool.buildArgs]
    ...?configuredBuildArgs,
    // 2. Pass through the --release flag if provided.
    if (flagValue(argResults, 'release') ?? false) '--release',
    // 3. Build filters to narrow the build to only the target tests.
    //    (If no test dirs/files are passed in as args, then no build filters
    //     will be created.)
    ...buildFiltersForTestArgs(argResults?.rest),
    // 4. Args passed to --build-args
    ...?splitSingleOptionValue(argResults, 'build-args'),
  ];

  final testArgs = <String>[
    // Combine all args that should be passed through to the webdev serve
    // process in this order:
    // 1. Statically configured args from [TestTool.testArgs]
    ...?configuredTestArgs,
    // 2. The --reporter option.
    if (argResults?.wasParsed('reporter') ?? false)
      '--reporter=${singleOptionValue(argResults, 'reporter')!}',
    // 3. The -n|--name, -N|--plain-name, and -P|--preset options
    ...?multiOptionValue(argResults, 'name')?.map((v) => '--name=$v'),
    ...?multiOptionValue(argResults, 'plain-name')
        ?.map((v) => '--plain-name=$v'),
    ...?multiOptionValue(argResults, 'preset')?.map((v) => '--preset=$v'),
    // 4. Args passed to --test-args
    ...?splitSingleOptionValue(argResults, 'test-args'),
    // 5. Rest args passed to this command
    ...?argResults?.rest,
  ];

  if (verbose) {
    if (!buildArgs.contains('-v') && !buildArgs.contains('--verbose')) {
      buildArgs.add('-v');
    }
  }

  return [
    // `dart test` or `dart run build_runner test`
    if (useBuildRunner) 'run',
    if (useBuildRunner) 'build_runner',
    'test',

    // Add the args targeting the build_runner command.
    if (useBuildRunner) ...buildArgs,
    if (useBuildRunner && testArgs.isNotEmpty) '--',

    // Add the args targeting the test command.
    ...testArgs,
  ];
}

/// Returns a declarative representation of a test process to run based on the
/// given parameters.
///
/// These parameters will be populated from [TestTool] when it is executed
/// (either directly or via a command-line app).
///
/// [context] is the execution context that would be provided by [TestTool] when
/// converted to a [DevToolCommand]. For tests, this can be manually created to
/// to imitate the various CLI inputs.
///
/// [configuredBuildArgs] will be populated from [TestTool.buildArgs].
///
/// [configuredTestArgs] will be populated from [TestTool.testArgs].
///
/// If non-null, [path] will override the current working directory for any
/// operations that require it. This is intended for use by tests.
///
/// The [TestTool] can be tested almost completely via this function by
/// enumerating all of the possible parameter variations and making assertions
/// on the declarative output.
TestExecution buildExecution(
  DevToolExecutionContext context, {
  List<String>? configuredBuildArgs,
  List<String>? configuredTestArgs,
  String? path,
}) {
  final argResults = context.argResults;
  final hasBuildRunner =
      packageIsImmediateDependency('build_runner', path: path);
  final hasBuildTest = packageIsImmediateDependency('build_test', path: path);
  final useBuildRunner = hasBuildRunner && hasBuildTest;
  if (!useBuildRunner &&
      argResults != null &&
      argResults['build-args'] != null) {
    context.usageException('Can only use --build-args in a project that has a '
        'direct dependency on both "build_runner" and "build_test" in the '
        'pubspec.yaml.');
  }

  if (!useBuildRunner && (flagValue(argResults, 'release') ?? false)) {
    _log.warning(yellow.wrap('The --release flag is only applicable in '
        'projects that run tests with build_runner, and this project does not.\n'
        'It will have no effect.'));
  }

  if (!packageIsImmediateDependency('test', path: path)) {
    _log.severe(red.wrap('Cannot run tests.\n')! +
        yellow
            .wrap('You must have a dependency on "test" in pubspec.yaml.\n')!);
    return TestExecution.exitEarly(ExitCode.config.code);
  }

  if (!useBuildRunner &&
      configuredBuildArgs != null &&
      configuredBuildArgs.isNotEmpty) {
    _log.severe('This project is configured to run tests with buildArgs, but '
        'is missing a direct dependency on "build_runner" or "build_test".\n'
        'Either remove these buildArgs in tool/dart_dev/config.dart or ensure '
        'both "build_runner" and "build_test" are dependencies in the '
        'pubspec.yaml.');
    return TestExecution.exitEarly(ExitCode.config.code);
  }

  final args = buildArgs(
      argResults: argResults,
      configuredBuildArgs: configuredBuildArgs,
      configuredTestArgs: configuredTestArgs,
      useBuildRunner: useBuildRunner,
      verbose: context.verbose);
  logSubprocessHeader(_log, 'dart ${args.join(' ')}'.trim());
  return TestExecution.process(
      ProcessDeclaration(exe.dart, args, mode: ProcessStartMode.inheritStdio));
}

// NOTE: This currently depends on https://github.com/dart-lang/build/pull/2445
// Additionally, consumers need to depend on build_web_compilers AND build_vm_compilers
// We should add some guard-rails (don't use filters if either of those deps are
// missing, and ensure adequate version of build_runner).
Iterable<String> buildFiltersForTestArgs(List<String>? testArgs) {
  final testInputs = (testArgs ?? []).where((arg) => arg.startsWith('test'));
  final filters = <String>[];
  for (final input in testInputs) {
    if (input.endsWith('.dart')) {
      filters
        ..add('$input.*_test.dart.js*')
        ..add(dartExtToHtml(input));
    } else {
      filters.add('$input**');
    }
  }
  return [for (final filter in filters) '--build-filter=$filter'];
}

String dartExtToHtml(String input) =>
    '${input.substring(0, input.length - 'dart'.length)}html';
