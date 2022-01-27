@TestOn('vm')
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/tools/tuneup_check_tool.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../log_matchers.dart';
import 'shared_tool_tests.dart';

void main() {
  group('TuneupCheckTool', () {
    sharedDevToolTests(() => TuneupCheckTool());

    test('provides an argParser', () {
      final argParser = TuneupCheckTool().argParser;
      expect(argParser.options, contains('ignore-infos'));
      expect(argParser.options['ignore-infos']!.type, OptionType.flag);
    });
  });

  group('buildArgs', () {
    test('(default)', () {
      expect(buildArgs(), orderedEquals(['run', 'tuneup', 'check']));
    });

    test('configured ignoreInfos', () {
      expect(buildArgs(configuredIgnoreInfos: true),
          orderedEquals(['run', 'tuneup', 'check', '--ignore-infos']));
    });

    test('--ignore-infos', () {
      final argResults = TuneupCheckTool().argParser.parse(['--ignore-infos']);
      expect(buildArgs(argResults: argResults),
          orderedEquals(['run', 'tuneup', 'check', '--ignore-infos']));
    });

    test('verbose', () {
      expect(buildArgs(verbose: true),
          orderedEquals(['run', 'tuneup', 'check', '--verbose']));
    });
  });

  group('buildExecution', () {
    test('throws UsageException if positional args are given', () {
      final argResults = ArgParser().parse(['a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_tuneup');
      expect(
          () => buildExecution(context),
          throwsA(isA<UsageException>().having(
              (e) => e.message, 'command name', contains('test_tuneup'))));
    });

    test('exits early and logs if tuneup is not an immediate dependency', () {
      expect(
          Logger.root.onRecord,
          emitsThrough(severeLogOf(allOf(contains('Cannot run "tuneup check"'),
              contains('"tuneup" in pubspec.yaml')))));

      final context = DevToolExecutionContext();
      final execution = buildExecution(context,
          path: 'test/tools/fixtures/tuneup_check/missing_tuneup');
      expect(execution.exitCode, ExitCode.config.code);
    });

    group('returns a TuneupExecution', () {
      final path = 'test/tools/fixtures/tuneup_check/has_tuneup';
      test('(default)', () {
        final execution = buildExecution(DevToolExecutionContext(), path: path);
        expect(execution.exitCode, isNull);
        expect(execution.process!.executable, 'dart');
        expect(
            execution.process!.args, orderedEquals(['run', 'tuneup', 'check']));
        expect(execution.process!.mode, ProcessStartMode.inheritStdio);
      });

      test('with args', () {
        final argResults =
            TuneupCheckTool().argParser.parse(['--ignore-infos']);
        final context =
            DevToolExecutionContext(argResults: argResults, verbose: true);
        final execution = buildExecution(context, path: path);
        expect(execution.exitCode, isNull);
        expect(execution.process!.executable, 'dart');
        expect(
            execution.process!.args,
            orderedEquals(
                ['run', 'tuneup', 'check', '--ignore-infos', '--verbose']));
        expect(execution.process!.mode, ProcessStartMode.inheritStdio);
      });

      test('and logs the subprocess header', () {
        expect(Logger.root.onRecord,
            emitsThrough(infoLogOf(allOf(contains('dart run tuneup check')))));

        buildExecution(DevToolExecutionContext(), path: path);
      });
    });
  });
}
