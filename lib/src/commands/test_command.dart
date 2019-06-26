import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/command_utils.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import '../utils/ensure_process_exit.dart';
import '../utils/has_any_positional_args_before_separator.dart';
import '../utils/take_args_between_separators.dart';

final _log = Logger('TestTool');

class TestCommand extends Command<int> {
  final TestConfig config;

  TestCommand([TestConfig config]) : config = config ?? TestConfig();

  @override
  String get name => config.commandName ?? TestConfig.defaultCommandName;

  @override
  String get description => config.description ?? TestConfig.defaultDescription;

  @override
  bool get hidden => config.hidden ?? false;

  @override
  String get invocation {
    final buffer = StringBuffer()
      ..write(
          '${super.invocation.replaceFirst('[arguments]', '[dart_dev arguments]')} ');
    if (packageIsImmediateDependency('build_test')) {
      buffer.write('[-- [build_runner arguments]]');
    }
    buffer.write('[-- [test arguments]]');
    return buffer.toString();
  }

  @override
  String get usageFooter {
    final hasBuildTest = packageIsImmediateDependency('build_test');
    final buffer = StringBuffer();
    if (hasBuildTest) {
      buffer
        ..writeln()
        ..writeln('Run "pub run build_runner test -h" to see the available '
            'build_runner arguments.');
    }
    buffer
      ..writeln()
      ..writeln('Run "pub run test -h" to see the available test arguments.');
    if (hasBuildTest) {
      buffer
        ..writeln()
        ..writeln('You can use any of them with "dart_dev $name" by passing '
            'the build_runner args after the first "--" separator and the test '
            'args after a second "--" separator.');
    } else {
      buffer.writeln('You can use any of them with "dart_dev $name" by passing '
          'them after a "--" separator.');
    }
    return buffer.toString();
  }

  @override
  Future<int> run() async {
    if (!packageIsImmediateDependency('test')) {
      _log.severe(red.wrap('Could not run tests.\n') +
          yellow
              .wrap('You must have a dependency on `test` in `pubspec.yaml`.'));
      return ExitCode.config.code;
    }
    assertNoPositionalArgsBeforeSeparator(name, argResults, usageException);
    final args = buildTestArgs(config, argResults);
    _log.info('Running: pub ${args.join(' ')}\n');
    final process =
        await Process.start('pub', args, mode: ProcessStartMode.inheritStdio);
    ensureProcessExit(process, log: _log);
    return process.exitCode;
  }

  static void assertNoPositionalArgsBeforeSeparator(
    String name,
    ArgResults argResults,
    void usageException(String message),
  ) {
    if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
      usageException('The "$name" command does not support positional args '
          'before the "--" separator.\n'
          'Args for the test runner or build runner should be passed in after '
          'a "--" separator.');
    }
  }

  static Iterable<String> buildTestArgs(
      TestConfig config, ArgResults argResults) {
    final hasBuildTest = packageIsImmediateDependency('build_test');

    final args = <String>[
      // `pub run test` or `pub run build_runner test`
      'run',
      if (hasBuildTest)
        'build_runner',
      'test',

      // Add the args targeting the build_runner command.
      if (hasBuildTest)
        ...config.buildRunnerArgs ?? [],
      if (hasBuildTest)
        ...takeArgsBetweenSeparators(argResults.rest),

      // Add the args targeting the test command.
      '--',
      ...config.testArgs ?? [],
      if (hasBuildTest)
        ...takeArgsBetweenSeparators(argResults.rest, skip: 1)
      else
        ...takeArgsBetweenSeparators(argResults.rest)
    ];
    if (args.last == '--') {
      args.removeLast();
    }
    return args;
  }
}

class TestConfig {
  TestConfig({
    this.buildRunnerArgs,
    this.commandName,
    this.description,
    this.hidden,
    this.testArgs,
  });

  final List<String> buildRunnerArgs;
  final String commandName;
  final String description;
  final bool hidden;
  final List<String> testArgs;

  static const String defaultCommandName = 'test';
  static const String defaultDescription = 'Run Dart tests in this package.';

  TestConfig merge(TestConfig other) => TestConfig(
        buildRunnerArgs: other?.buildRunnerArgs ?? buildRunnerArgs,
        commandName: other?.commandName ?? commandName,
        description: other?.description ?? description,
        hidden: other?.hidden ?? hidden,
        testArgs: other?.testArgs ?? testArgs,
      );
}
