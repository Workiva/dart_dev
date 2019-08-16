import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/assert_no_args_after_separator.dart';
import '../utils/logging.dart';
import '../utils/package_is_immediate_dependency.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('Test');

class TestTool extends DevTool {
  /// The args to pass to the `pub run build_runner test` process that will be
  /// run by this command when the current project depends on `build_test`.
  ///
  /// Run `pub run build_runner test -h` to see all available args.
  List<String> buildArgs;

  @override
  String description = 'Run dart tests in this package.';

  /// The args to pass to the `pub run test` process (either directly or
  /// through the `pub run build_runner test` process if applicable).
  ///
  /// Run `pub run test -h` to see all available args.
  ///
  /// Note that most of the command-line options for the `pub run test` process
  /// also have `dart_test.yaml` configuration counterparts. Rather than
  /// configuring this field, it is preferred that the project be configured via
  /// `dart_test.yaml` so that the configuration is used even when running tests
  /// through some means other than `ddev`.
  List<String> testArgs;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) {
    context ??= DevToolExecutionContext();
    final execution = createTestExecution(context,
        configuredBuildArgs: buildArgs, configuredTestArgs: testArgs);
    if (execution.exitCode != null) {
      return execution.exitCode;
    }
    return runProcessAndEnsureExit(execution.process);
  }

  @override
  Command<int> toCommand(String name) => DevToolCommand(name, this,
      argParser: ArgParser()
        ..addOption('test-args',
            help: 'Args to pass to the test runner process.\n'
                'Run "pub run test -h -v" to see all available options.')
        ..addOption('build-args',
            help: 'Args to pass to the build runner process.\n'
                'Run "pub run build_runner test -h -v" to see all available '
                'options.\n'
                'Note: these args are only applicable if the current project '
                'depends on "build_test".'));
}

/// A declarative representation of an execution of the [TestTool].
///
/// This class allows the [TestTool] to break its execution up into two steps:
/// 1. Validation of confg/inputs and creation of this class.
/// 2. Execution of expensive or hard-to-test logic based on step 1.
///
/// As a result, nearly all of the logic in [TestTool] can be tested via the
/// output of step 1 with very simple unit tests.
class TestExecution {
  TestExecution.exitEarly(this.exitCode) : process = null;
  TestExecution.process(this.process) : exitCode = null;

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

TestExecution createTestExecution(
  DevToolExecutionContext context, {
  List<String> configuredBuildArgs,
  List<String> configuredTestArgs,
}) {
  if (context.argResults != null) {
    assertNoArgsAfterSeparator(context.argResults, context.usageException,
        commandName: context.commandName,
        usageFooter:
            'Arguments can be passed to the test runner process via the '
            '--test-args option.\n'
            'If this project runs tests via build_runner, arguments can be '
            'passed to that process via the --build-args option.');
  }

  final hasBuildTest = packageIsImmediateDependency('build_test');
  if (!hasBuildTest &&
      context.argResults != null &&
      context.argResults['build-args'] != null) {
    context.usageException('Can only use --build-args in a project that has a '
        'direct dependency on "build_test" in the pubspec.yaml.');
  }
  if (!assertTestRunnerAvailable()) {
    return TestExecution.exitEarly(ExitCode.config.code);
  }
  if (!hasBuildTest &&
      configuredBuildArgs != null &&
      configuredBuildArgs.isNotEmpty) {
    _log.severe('This project is configured to run tests with buildArgs, but '
        '"build_test" is not a direct dependency in this project.\n'
        'Either remove these buildArgs in tool/dev.dart or add "build_test" to '
        'the pubspec.yaml.');
    return TestExecution.exitEarly(ExitCode.config.code);
  }
  final args = buildTestArgs(
      argResults: context.argResults,
      configuredBuildArgs: configuredBuildArgs,
      configuredTestArgs: configuredTestArgs,
      useBuildTest: hasBuildTest,
      verbose: context.verbose);
  logSubprocessHeader(_log, 'pub ${args.join(' ')}'.trim());
  return TestExecution.process(
      ProcessDeclaration('pub', args, mode: ProcessStartMode.inheritStdio));
}

/// A dart_dev command that runs tests for the current project.
///
/// This command will run tests via `pub run test` unless the current project
/// depends on `build_test`, in which case it will run tests via
/// `pub run build_runner test`.
///
/// The default target for this command is `test` (e.g. `ddev test`), but
/// this is configurable in each project's `tool/dev.dart`.
///
/// This test command can be configured by modifying any of the available fields
/// on an instance of this class, e.g.:
///     // tool/dev.dart
///     import 'package:dart_dev/tools/test_tool.dart';
///
///     final config = {
///       'test': TestCommand()
///         ..buildRunnerArgs = ['--delete-conflicting-outputs']
///         ..testArgs = ['--verbose-trace']
///     }
// class TestCommand extends CommandBuilder {
//   /// The args to pass to the `pub run build_runner test` process that will be
//   /// run by this command when the current project depends on `build_test`.
//   ///
//   /// Run `pub run build_runner test -h` to see all available args.
//   List<String> buildRunnerArgs;

//   /// The default description for this test command can be overridden by setting
//   /// this field to a non-null value.
//   ///
//   /// This description is used when printing the help text for this command as
//   /// well as the help text for the top-level `ddev` command runner.
//   @override
//   String description;

//   /// This command is not hidden from the `ddev` command runner by default, but
//   /// can be by setting this to `true`.
//   @override
//   bool hidden;

//   /// The args to pass to the `pub run test` process (either directly or
//   /// through the `pub run build_runner test` process if applicable).
//   ///
//   /// Run `pub run test -h` to see all available args.
//   ///
//   /// Note that most of the command-line options for the `pub run test` process
//   /// also have `dart_test.yaml` configuration counterparts. Rather than
//   /// configuring this field, it is preferred that the project be configured via
//   /// `dart_test.yaml` so that the configuration is used even when running tests
//   /// through some means other than `ddev`.
//   List<String> testArgs;

//   @override
//   Command<int> build(String commandName) => _TestCommand(
//         commandName,
//         buildRunnerArgs ?? <String>[],
//         description,
//         hidden,
//         testArgs ?? <String>[],
//       );
// }

/// Returns `true` if executables from `test` can be run in the current project
/// (i.e. it is a direct dependency), and `false` otherwise.
///
/// Also logs a SEVERE log if `test` is not available explaining why its
/// executable cannot be run and how to fix the issue.
bool assertTestRunnerAvailable({String path}) {
  if (!packageIsImmediateDependency('test', path: path)) {
    _log.severe(red.wrap('Cannot run tests.\n') +
        yellow.wrap('You must have a dependency on "test" in pubspec.yaml.\n'));
    return false;
  }
  return true;
}

/// Builds and returns the args needed to run the test process.
///
/// If [useBuildTest] is true, the returned args will run tests via
/// `pub run build_runner test`. Otherwise, the returned args will run tests via
/// `pub run test`.
List<String> buildTestArgs({
  ArgResults argResults,
  List<String> configuredBuildArgs,
  List<String> configuredTestArgs,
  bool useBuildTest,
  bool verbose,
}) {
  useBuildTest ??= false;

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
  final testArgs = <String>[
    // Combine all args that should be passed through to the webdev serve
    // process in this order:
    // 1. Statically configured args from [WebdevServeTool.webdevArgs]
    if (configuredTestArgs != null)
      ...configuredTestArgs,
    // 2. Args passed to --test-args
    if (argResults != null && argResults['test-args'] != null)
      ...argResults['test-args'].split(' '),
    // 3. Rest args passed to this command
    if (argResults != null)
      ...argResults.rest,
  ];

  if (verbose == true) {
    if (!buildArgs.contains('-v') && !buildArgs.contains('--verbose')) {
      buildArgs.add('-v');
    }
    if (!testArgs.contains('-v') && !testArgs.contains('--verbose')) {
      testArgs.add('-v');
    }
  }

  return [
    // `pub run test` or `pub run build_runner test`
    'run',
    if (useBuildTest)
      'build_runner',
    'test',

    // Add the args targeting the build_runner command.
    if (useBuildTest)
      ...buildArgs,
    if (useBuildTest && testArgs.isNotEmpty)
      '--',

    // Add the args targeting the test command.
    ...testArgs,
  ];
}
