@TestOn('vm')
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/utils/formatter_inputs.dart';
import 'package:glob/glob.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:dart_dev/src/tools/format_tool.dart';

import 'shared_tool_tests.dart';

void main() {
  group('FormatCommand', () {
    sharedDevToolTests(() => FormatTool());

    test('toCommand overrides the argParser', () {
      final argParser = FormatTool().toCommand('t').argParser;
      expect(argParser.options.keys,
          containsAll(['overwrite', 'dry-run', 'assert', 'formatter-args']));

      expect(argParser.options['overwrite'].type, OptionType.flag);
      expect(argParser.options['overwrite'].abbr, 'w');
      expect(argParser.options['overwrite'].negatable, isFalse);

      expect(argParser.options['dry-run'].type, OptionType.flag);
      expect(argParser.options['dry-run'].abbr, 'n');
      expect(argParser.options['dry-run'].negatable, isFalse);

      expect(argParser.options['assert'].type, OptionType.flag);
      expect(argParser.options['assert'].abbr, 'a');
      expect(argParser.options['assert'].negatable, isFalse);

      expect(argParser.options['formatter-args'].type, OptionType.single);
    });
  });

  group('buildArgs', () {
    test('no mode', () {
      expect(buildArgs(['a', 'b'], null), orderedEquals(['a', 'b']));
    });

    test('mode=overwrite', () {
      expect(buildArgs(['a', 'b'], FormatMode.overwrite),
          orderedEquals(['a', 'b', '-w']));
    });

    test('mode=dry-run', () {
      expect(buildArgs(['a', 'b'], FormatMode.dryRun),
          orderedEquals(['a', 'b', '-n']));
    });

    test('mode=assert', () {
      expect(buildArgs(['a', 'b'], FormatMode.assertNoChanges),
          orderedEquals(['a', 'b', '-n', '--set-exit-if-changed']));
    });

    test('combines configured args with cli args (in that order)', () {
      final argParser = FormatTool().toCommand('t').argParser;
      final argResults = argParser.parse(['--formatter-args', '--indent 2']);
      expect(
          buildArgs(['a', 'b'], FormatMode.overwrite,
              argResults: argResults,
              configuredFormatterArgs: ['--fix', '--follow-links']),
          orderedEquals([
            'a',
            'b',
            '-w',
            '--fix',
            '--follow-links',
            '--indent',
            '2',
          ]));
    });
  });

  group('buildExecution', () {
    test('throws UsageException if positional args are given', () {
      final argResults = ArgParser().parse(['a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_format');
      expect(
          () => buildExecution(context),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'command name', contains('test_format'))
            ..having((e) => e.message, 'usage', contains('--formatter-args'))));
    });

    test('throws UsageException if args are given after a separator', () {
      final argResults = ArgParser().parse(['--', 'a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_format');
      expect(
          () => buildExecution(context),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'command name', contains('test_format'))
            ..having((e) => e.message, 'usage', contains('--formatter-args'))));
    });

    test(
        'returns config exit code and logs if configured formatter is '
        'dart_style but the package is not a direct dependency', () {
      Logger.root.level = Level.ALL;
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('Cannot run "dart_style:format"') &&
              record.message
                  .contains('add "dart_style" to your pubspec.yaml') &&
              record.message.contains('use "dartfmt" instead') &&
              record.level == Level.SEVERE)));

      final context = DevToolExecutionContext();
      final execution = buildExecution(context,
          formatter: Formatter.dartStyle,
          path: 'test/tools/fixtures/format/missing_dart_style');
      expect(execution.exitCode, ExitCode.config.code);
    });

    group('returns a FormatExecution', () {
      test('', () {
        final context = DevToolExecutionContext();
        final execution = buildExecution(context);
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, 'dartfmt');
        expect(execution.process.args, orderedEquals(['.']));
        expect(execution.process.mode, ProcessStartMode.inheritStdio);
      });

      test('that uses defaultMode if no mode flag is given', () {
        final context = DevToolExecutionContext();
        final execution =
            buildExecution(context, defaultMode: FormatMode.dryRun);
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, 'dartfmt');
        expect(execution.process.args, orderedEquals(['-n', '.']));
        expect(execution.process.mode, ProcessStartMode.inheritStdio);
      });

      test('with dartfmt', () {
        final context = DevToolExecutionContext();
        final execution = buildExecution(context, formatter: Formatter.dartfmt);
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, 'dartfmt');
        expect(execution.process.args, orderedEquals(['.']));
        expect(execution.process.mode, ProcessStartMode.inheritStdio);
      });

      test('with dart_style:format', () {
        final context = DevToolExecutionContext();
        final execution = buildExecution(context,
            formatter: Formatter.dartStyle,
            path: 'test/tools/fixtures/format/has_dart_style');
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, 'pub');
        expect(execution.process.args,
            orderedEquals(['run', 'dart_style:format', '.']));
        expect(execution.process.mode, ProcessStartMode.inheritStdio);
      });

      test('with args', () {
        final argParser = FormatTool().toCommand('t').argParser;
        final argResults =
            argParser.parse(['-w', '--formatter-args', '--indent 2']);
        final context = DevToolExecutionContext(argResults: argResults);
        final execution = buildExecution(context,
            configuredFormatterArgs: ['--fix', '--follow-links'],
            formatter: Formatter.dartfmt);
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, 'dartfmt');
        expect(
            execution.process.args,
            orderedEquals(
                ['-w', '--fix', '--follow-links', '--indent', '2', '.']));
        expect(execution.process.mode, ProcessStartMode.inheritStdio);
      });

      test('and logs the test subprocess', () {
        Logger.root.level = Level.ALL;
        expect(
            Logger.root.onRecord,
            emitsThrough(predicate<LogRecord>((record) =>
                record.message.contains('dartfmt .') &&
                record.level == Level.INFO)));

        buildExecution(DevToolExecutionContext());
      });
    });
  });

  group('getFormatterInputs', () {
    final root = 'test/tools/fixtures/format/globs';
    final dirs = [
      'benchmark',
      'bin',
      'example',
      'lib',
      'test',
      'tool',
      'web',
    ];

    test('no excludes', () {
      expect(getFormatterInputs(root: root).filesToFormat,
          unorderedEquals({'$root'}));
    });

    test('custom excludes', () {
      final formatInputs =
          getFormatterInputs(exclude: [Glob('*_exclude.dart')], root: root);

      expect(
          formatInputs.filesToFormat,
          unorderedEquals({
            'file.dart',
            for (final dir in dirs) '$dir/sub/file.dart',
          }));

      expect(
          formatInputs.excludedFiles, unorderedEquals({'should_exclude.dart'}));
    });

    test('empty inputs due to excludes config', () async {
      expect(
          getFormatterInputs(exclude: [Glob('**')], root: root).filesToFormat,
          isEmpty);
    });
    test('ignores all hidden directories', () {
      expect(getFormatterInputs(root: root).hiddenDirectories,
          unorderedEquals({'.dart_tool_test', 'example/.pub_test'}));
    });

    test('ignores directory and file links', () {
      expect(getFormatterInputs(root: root).links,
          unorderedEquals({'sub', 'example/file.dart'}));
    });
  });

  group('buildProcess', () {
    test('dartfmt', () {
      final process = buildProcess(Formatter.dartfmt);
      expect(process.executable, 'dartfmt');
      expect(process.args, isEmpty);
    });

    test('dart_style', () {
      final process = buildProcess(Formatter.dartStyle);
      expect(process.executable, 'pub');
      expect(process.args, orderedEquals(['run', 'dart_style:format']));
    });

    test('default', () {
      final process = buildProcess(Formatter.dartfmt);
      expect(process.executable, 'dartfmt');
      expect(process.args, isEmpty);
    });
  });

  group('logFormatCommand', () {
    test('<=5 inputs and verbose=false', () async {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('dartfmt -x -y a b') &&
              record.level == Level.INFO)));

      logCommand('dartfmt', ['a', 'b'], ['-x', '-y']);
    });

    test('>5 inputs and verbose=true', () async {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('dartfmt -x -y <6 paths>') &&
              record.level == Level.INFO)));

      logCommand('dartfmt', ['a', 'b', 'c', 'd', 'e', 'f'], ['-x', '-y']);
    });

    test('>5 inputs and verbose=false', () async {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('dartfmt -x -y a b c d e f') &&
              record.level == Level.INFO)));

      logCommand('dartfmt', ['a', 'b', 'c', 'd', 'e', 'f'], ['-x', '-y'],
          verbose: true);
    });
  });

  group('validateAndParseMode', () {
    ArgParser argParser;
    Function usageException;

    setUp(() {
      argParser = FormatTool().toCommand('test_format').argParser;
      usageException =
          DevToolExecutionContext(commandName: 'test_format').usageException;
    });

    test('--assert and --dry-run and --overwrite throws UsageException', () {
      final argResults =
          argParser.parse(['--assert', '--dry-run', '--overwrite']);
      expect(
          () => validateAndParseMode(argResults, usageException),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'command name', 'test_format')
            ..having((e) => e.message, 'usage footer',
                contains('--assert and --dry-run and --overwrite'))));
    });

    test('--assert and --dry-run throws UsageException', () {
      final argResults = argParser.parse(['--assert', '--dry-run']);
      expect(
          () => validateAndParseMode(argResults, usageException),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'command name', 'test_format')
            ..having((e) => e.message, 'usage footer',
                contains('--assert and --dry-run'))));
    });

    test('--assert and --overwrite throws UsageException', () {
      final argResults = argParser.parse(['--assert', '--overwrite']);
      expect(
          () => validateAndParseMode(argResults, usageException),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'command name', 'test_format')
            ..having((e) => e.message, 'usage footer',
                contains('--assert and --overwrite'))));
    });

    test('--dry-run and --overwrite throws UsageException', () {
      final argResults = argParser.parse(['--dry-run', '--overwrite']);
      expect(
          () => validateAndParseMode(argResults, usageException),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'command name', 'test_format')
            ..having((e) => e.message, 'usage footer',
                contains('--dry-run and --overwrite'))));
    });

    test('--assert', () {
      final argResults = argParser.parse(['--assert']);
      expect(validateAndParseMode(argResults, usageException),
          FormatMode.assertNoChanges);
    });

    test('--dry-run', () {
      final argResults = argParser.parse(['--dry-run']);
      expect(
          validateAndParseMode(argResults, usageException), FormatMode.dryRun);
    });

    test('--overwrite', () {
      final argResults = argParser.parse(['--overwrite']);
      expect(validateAndParseMode(argResults, usageException),
          FormatMode.overwrite);
    });

    test('no mode flag', () {
      final argResults = argParser.parse([]);
      expect(validateAndParseMode(argResults, usageException), isNull);
    });
  });
}
