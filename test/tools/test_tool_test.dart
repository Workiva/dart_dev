@TestOn('vm')
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:dart_dev/src/tools/test_tool.dart';

import 'shared_tool_tests.dart';

void main() {
  group('TestTool', () {
    sharedDevToolTests(() => TestTool());

    test('toCommand overrides the argParser', () {
      final argParser = TestTool().toCommand('t').argParser;
      expect(
          argParser.options.keys,
          containsAll([
            'name',
            'plain-name',
            'preset',
            'release',
            'test-args',
            'build-args',
          ]));

      expect(argParser.options['name'].type, OptionType.multiple);
      expect(argParser.options['name'].abbr, 'n');
      expect(argParser.options['name'].splitCommas, isFalse);

      expect(argParser.options['plain-name'].type, OptionType.multiple);
      expect(argParser.options['plain-name'].abbr, 'N');
      expect(argParser.options['plain-name'].splitCommas, isFalse);

      expect(argParser.options['preset'].type, OptionType.multiple);
      expect(argParser.options['preset'].abbr, 'P');
      expect(argParser.options['preset'].splitCommas, isTrue);

      expect(argParser.options['release'].type, OptionType.flag);
      expect(argParser.options['release'].abbr, isNull);

      expect(argParser.options['test-args'].type, OptionType.single);
      expect(argParser.options['build-args'].type, OptionType.single);
    });
  });

  group('buildArgs', () {
    test('(default)', () {
      expect(buildArgs(), orderedEquals(['run', 'test']));
    });

    test('forwards the -n|--name options', () {
      final argParser = TestTool().toCommand('t').argParser;
      final argResults = argParser.parse(['-n', 'foo', '-n', 'bar']);
      expect(buildArgs(argResults: argResults),
          orderedEquals(['run', 'test', '--name', 'foo', '--name', 'bar']));
    });

    test('forwards the -N|--plain-name options', () {
      final argParser = TestTool().toCommand('t').argParser;
      final argResults = argParser.parse(['-N', 'foo', '-N', 'bar']);
      expect(
          buildArgs(argResults: argResults),
          orderedEquals(
              ['run', 'test', '--plain-name', 'foo', '--plain-name', 'bar']));
    });

    test('forwards the -P|--preset options', () {
      final argParser = TestTool().toCommand('t').argParser;
      final argResults = argParser.parse(['-P', 'foo', '-P', 'bar']);
      expect(buildArgs(argResults: argResults),
          orderedEquals(['run', 'test', '--preset', 'foo', '--preset', 'bar']));
    });

    group('with useBuildTest=false', () {
      test('combines configured args with cli args (in that order)', () {
        final argParser = TestTool().toCommand('t').argParser;
        final argResults = argParser.parse(['--test-args', '-N foo']);
        expect(
            buildArgs(
                argResults: argResults, configuredTestArgs: ['-P', 'unit']),
            orderedEquals(['run', 'test', '-P', 'unit', '-N', 'foo']));
      });

      test('ignores build args if given', () {
        final argParser = TestTool().toCommand('t').argParser;
        final argResults =
            argParser.parse(['--build-args', '--delete-conflicting-outputs']);
        expect(
            buildArgs(
                argResults: argResults,
                configuredBuildArgs: ['-o', 'test:build']),
            orderedEquals(['run', 'test']));
      });
    });

    group('with useBuildTest=true', () {
      test('forwards the --release flag', () {
        final argParser = TestTool().toCommand('t').argParser;
        final argResults = argParser.parse(['--release']);
        expect(buildArgs(argResults: argResults, useBuildTest: true),
            orderedEquals(['run', 'build_runner', 'test', '--release']));
      });

      test('combines configured args with cli args (in that order)', () {
        final argParser = TestTool().toCommand('t').argParser;
        final argResults = argParser
            .parse(['--build-args', '--config bar', '--test-args', '-N foo']);
        expect(
            buildArgs(
                argResults: argResults,
                configuredBuildArgs: ['-o', 'test:build'],
                configuredTestArgs: ['-P', 'unit'],
                useBuildTest: true),
            orderedEquals([
              'run',
              'build_runner',
              'test',
              '-o',
              'test:build',
              '--config',
              'bar',
              '--',
              '-P',
              'unit',
              '-N',
              'foo'
            ]));
      });
    });

    test('inserts a verbose flag if not already present', () {
      final argParser = TestTool().toCommand('t').argParser;
      final argResults = argParser
          .parse(['--build-args', '--config bar', '--test-args', '-N foo']);
      expect(
          buildArgs(
              argResults: argResults,
              configuredBuildArgs: ['-o', 'test:build'],
              configuredTestArgs: ['-P', 'unit'],
              useBuildTest: true,
              verbose: true),
          orderedEquals([
            'run',
            'build_runner',
            'test',
            '-o',
            'test:build',
            '--config',
            'bar',
            '-v',
            '--',
            '-P',
            'unit',
            '-N',
            'foo',
          ]));
    });

    test('does not insert a duplicate verbose flag (-v)', () {
      expect(
          buildArgs(
              configuredBuildArgs: ['-v'], useBuildTest: true, verbose: true),
          orderedEquals(['run', 'build_runner', 'test', '-v']));
    });

    test('does not insert a duplicate verbose flag (--verbose)', () {
      expect(
          buildArgs(
              configuredBuildArgs: ['--verbose'],
              useBuildTest: true,
              verbose: true),
          orderedEquals(['run', 'build_runner', 'test', '--verbose']));
    });
  });

  group('buildExecution', () {
    test('throws UsageException if args are given after a separator', () {
      final argResults = ArgParser().parse(['--', 'a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_test');
      expect(
          () => buildExecution(context),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'command name', contains('test_test'))
            ..having((e) => e.message, 'help',
                allOf(contains('--test-args'), contains('--build-args')))));
    });

    test(
        'throws UsageException if --build-args is used but build_test is not '
        'a direct dependency', () {
      final path =
          'test/tools/fixtures/test/has_test_runner_missing_build_test';
      final argParser = TestTool().toCommand('t').argParser;
      final argResults = argParser.parse(['--build-args', 'foo']);
      final context = DevToolExecutionContext(argResults: argResults);
      expect(
          () => buildExecution(context, path: path),
          throwsA(isA<UsageException>()
            ..having((e) => e.message, 'help', contains('--build-args'))
            ..having((e) => e.message, 'help', contains('build_test'))));
    });

    test('returns config exit code and logs if test is not a direct dependency',
        () {
      Logger.root.level = Level.ALL;
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('Cannot run tests') &&
              record.message.contains('"test" in pubspec.yaml') &&
              record.level == Level.SEVERE)));

      final path = 'test/tools/fixtures/test/missing_test_runner';
      final context = DevToolExecutionContext();
      expect(
          buildExecution(context, path: path).exitCode, ExitCode.config.code);
    });

    test(
        'returns config exit code and logs if configured to run tests with '
        'build args but build_test is not a direct dependency', () {
      Logger.root.level = Level.ALL;
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message
                  .contains('"build_test" is not a direct dependency') &&
              record.message.contains('tool/dart_dev/config.dart') &&
              record.message.contains('pubspec.yaml') &&
              record.level == Level.SEVERE)));

      final path =
          'test/tools/fixtures/test/has_test_runner_missing_build_test';
      final context = DevToolExecutionContext();
      expect(
          buildExecution(context,
                  configuredBuildArgs: ['-o', 'test:build'], path: path)
              .exitCode,
          ExitCode.config.code);
    });

    group('returns a TestExecution', () {
      final path =
          'test/tools/fixtures/test/has_test_runner_missing_build_test';

      group('in a project without build_test', () {
        test('', () {
          final context = DevToolExecutionContext();
          final execution = buildExecution(context, path: path);
          expect(execution.exitCode, isNull);
          expect(execution.process.executable, 'pub');
          expect(execution.process.args, orderedEquals(['run', 'test']));
        });

        test('with args', () {
          final argParser = TestTool().toCommand('t').argParser;
          final argResults = argParser.parse(['--test-args', '-n foo']);
          final context = DevToolExecutionContext(argResults: argResults);
          final execution = buildExecution(context,
              configuredTestArgs: ['-P', 'unit'], path: path);
          expect(execution.exitCode, isNull);
          expect(execution.process.executable, 'pub');
          expect(execution.process.args,
              orderedEquals(['run', 'test', '-P', 'unit', '-n', 'foo']));
        });

        test(
            'and logs a warning if --release is used in a non-build project',
            () => overrideAnsiOutput(false, () {
                  Logger.root.level = Level.ALL;
                  expect(
                      Logger.root.onRecord,
                      emitsThrough(predicate<LogRecord>((record) =>
                          record.message.contains(
                              'The --release flag is only applicable') &&
                          record.level == Level.WARNING)));

                  final argParser = TestTool().toCommand('t').argParser;
                  final argResults = argParser.parse(['--release']);
                  final context =
                      DevToolExecutionContext(argResults: argResults);
                  buildExecution(context, path: path);
                }));

        test('and logs the test subprocess', () {
          Logger.root.level = Level.ALL;
          expect(
              Logger.root.onRecord,
              emitsThrough(predicate<LogRecord>((record) =>
                  record.message.contains('pub run test -P unit -n foo') &&
                  record.level == Level.INFO)));

          final argParser = TestTool().toCommand('t').argParser;
          final argResults = argParser.parse(['--test-args', '-n foo']);
          final context = DevToolExecutionContext(argResults: argResults);
          buildExecution(context,
              configuredTestArgs: ['-P', 'unit'], path: path);
        });
      });

      group('in a project with build_test', () {
        final path = 'test/tools/fixtures/test/has_test_runner_and_build_test';

        test('', () {
          final context = DevToolExecutionContext();
          final execution = buildExecution(context, path: path);
          expect(execution.exitCode, isNull);
          expect(execution.process.executable, 'pub');
          expect(execution.process.args,
              orderedEquals(['run', 'build_runner', 'test']));
        });

        test('with args', () {
          final argParser = TestTool().toCommand('t').argParser;
          final argResults = argParser.parse(
              ['--build-args', '-o test:build', '--test-args', '-n foo']);
          final context = DevToolExecutionContext(argResults: argResults);
          final execution = buildExecution(context,
              configuredBuildArgs: ['foo'],
              configuredTestArgs: ['-P', 'unit'],
              path: path);
          expect(execution.exitCode, isNull);
          expect(execution.process.executable, 'pub');
          expect(
              execution.process.args,
              orderedEquals([
                'run',
                'build_runner',
                'test',
                'foo',
                '-o',
                'test:build',
                '--',
                '-P',
                'unit',
                '-n',
                'foo'
              ]));
        });

        test('with verbose=true', () {
          final argParser = TestTool().toCommand('t').argParser;
          final argResults = argParser.parse(
              ['--build-args', '-o test:build', '--test-args', '-n foo']);
          final context =
              DevToolExecutionContext(argResults: argResults, verbose: true);
          final execution = buildExecution(context,
              configuredBuildArgs: ['foo'],
              configuredTestArgs: ['-P', 'unit'],
              path: path);
          expect(execution.exitCode, isNull);
          expect(execution.process.executable, 'pub');
          expect(
              execution.process.args,
              orderedEquals([
                'run',
                'build_runner',
                'test',
                'foo',
                '-o',
                'test:build',
                '-v',
                '--',
                '-P',
                'unit',
                '-n',
                'foo',
              ]));
        });

        test('and logs the test subprocess', () {
          Logger.root.level = Level.ALL;
          expect(
              Logger.root.onRecord,
              emitsThrough(predicate<LogRecord>((record) =>
                  record.message.contains(
                      'pub run build_runner test foo -o test:build -- -P unit -n foo') &&
                  record.level == Level.INFO)));

          final argParser = TestTool().toCommand('t').argParser;
          final argResults = argParser.parse(
              ['--build-args', '-o test:build', '--test-args', '-n foo']);
          final context = DevToolExecutionContext(argResults: argResults);
          buildExecution(context,
              configuredBuildArgs: ['foo'],
              configuredTestArgs: ['-P', 'unit'],
              path: path);
        });
      });
    });
  });
}
