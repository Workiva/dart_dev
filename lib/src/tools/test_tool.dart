import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/tool_utils.dart';
import 'package:logging/logging.dart';

import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/utils/has_any_positional_args_before_separator.dart';

final _log = Logger('TestTool');

class TestTool implements DartDevTool {
  @override
  final TestCommand command;

  TestTool(TestConfig config) : command = TestCommand(config);
}

class TestCommand extends Command<int> {
  final TestConfig config;

  TestCommand([TestConfig config]) : config = config ?? TestConfig();

  @override
  String get name => config.commandName ?? 'test';

  @override
  String get description => 'Run Dart tests in this package.';

  @override
  String get invocation {
    final buffer = StringBuffer()
      ..write(
          '${super.invocation.replaceFirst('[arguments]', '[dart_dev arguments]')} ');
    if (hasImmediateDependency('build_test')) {
      buffer.write('[-- [build_runner arguments]]');
    }
    buffer.write('[-- [test arguments]]');
    return buffer.toString();
  }

  @override
  String get usageFooter {
    final hasBuildTest = hasImmediateDependency('build_test');
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
    assertNoPositionalArgsBeforeSeparator(name, argResults, usageException);

    final args = [];
    _log.info('Running: pub ${args.join(' ')}');
    final process = await Process.start('pub', [...args],
        mode: ProcessStartMode.inheritStdio);
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
}

class TestConfig extends DartDevToolConfig {
  TestConfig({
    this.buildRunnerArgs,
    String commandName,
    this.testArgs,
  }) : super(commandName);

  final List<String> buildRunnerArgs;
  final List<String> testArgs;

  TestConfig merge(TestConfig other) => TestConfig(
        buildRunnerArgs: other?.buildRunnerArgs ?? buildRunnerArgs,
        commandName: other?.commandName ?? commandName,
        testArgs: other?.testArgs ?? testArgs,
      );
}
