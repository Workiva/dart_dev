@TestOn('vm')
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/tools/webdev_serve_tool.dart';
import 'package:dart_dev/src/utils/executables.dart' as exe;
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../log_matchers.dart';
import '../utils.dart';
import 'shared_tool_tests.dart';

void main() {
  group('WebdevServeCommand', () {
    sharedDevToolTests(() => WebdevServeTool());

    test('toCommand overrides the argParser', () {
      final argParser = WebdevServeTool().toCommand('t').argParser;
      expect(argParser.options.keys,
          containsAll(['release', 'webdev-args', 'build-args']));

      expect(argParser.options['release'].type, OptionType.flag);
      expect(argParser.options['release'].abbr, 'r');
      expect(argParser.options['release'].negatable, isTrue);

      expect(argParser.options['webdev-args'].type, OptionType.single);
      expect(argParser.options['build-args'].type, OptionType.single);
    });
  });

  group('buildArgs', () {
    test('(default)', () {
      expect(buildArgs(),
          orderedEquals(['pub', 'global', 'run', 'webdev', 'serve']));
    });

    test('forwards the -r|--release flag', () {
      final argParser = WebdevServeTool().toCommand('t').argParser;
      final argResults = argParser.parse(['-r']);
      expect(
          buildArgs(argResults: argResults),
          orderedEquals(
              ['pub', 'global', 'run', 'webdev', 'serve', '--release']));
    });

    test('combines configured args with cli args (in that order)', () {
      final argParser = WebdevServeTool().toCommand('t').argParser;
      final argResults = argParser.parse(
          ['--webdev-args', '-r --debug', '--build-args', '--config foo']);
      expect(
          buildArgs(
              argResults: argResults,
              configuredBuildArgs: ['-o', 'web:build'],
              configuredWebdevArgs: ['web:9000', 'example:9001']),
          orderedEquals([
            'pub',
            'global',
            'run',
            'webdev',
            'serve',
            'web:9000',
            'example:9001',
            '-r',
            '--debug',
            '--',
            '-o',
            'web:build',
            '--config',
            'foo'
          ]));
    });

    test('inserts a verbose flag if not already present', () {
      final argParser = WebdevServeTool().toCommand('t').argParser;
      final argResults = argParser.parse(
          ['--webdev-args', '-r --debug', '--build-args', '--config foo']);
      expect(
          buildArgs(
              argResults: argResults,
              configuredBuildArgs: ['-o', 'web:build'],
              configuredWebdevArgs: ['web:9000', 'example:9001'],
              verbose: true),
          orderedEquals([
            'pub',
            'global',
            'run',
            'webdev',
            'serve',
            'web:9000',
            'example:9001',
            '-r',
            '--debug',
            '-v',
            '--',
            '-o',
            'web:build',
            '--config',
            'foo',
            '-v'
          ]));
    });

    test('does not insert a duplicate verbose flag (-v)', () {
      expect(
          buildArgs(
              configuredBuildArgs: ['-v'],
              configuredWebdevArgs: ['-v'],
              verbose: true),
          orderedEquals(
              ['pub', 'global', 'run', 'webdev', 'serve', '-v', '--', '-v']));
    });

    test('does not insert a duplicate verbose flag (--verbose)', () {
      expect(
          buildArgs(
              configuredBuildArgs: ['--verbose'],
              configuredWebdevArgs: ['--verbose'],
              verbose: true),
          orderedEquals([
            'pub',
            'global',
            'run',
            'webdev',
            'serve',
            '--verbose',
            '--',
            '--verbose'
          ]));
    });
  });

  group('buildExecution', () {
    TempPubCache pubCacheWithWebdev;
    TempPubCache pubCacheWithoutWebdev;

    setUpAll(() {
      pubCacheWithWebdev = TempPubCache();
      globalActivate('webdev', '^2.0.0',
          environment: pubCacheWithWebdev.envOverride);

      pubCacheWithoutWebdev = TempPubCache();
    });

    tearDownAll(() {
      pubCacheWithWebdev.tearDown();
      pubCacheWithoutWebdev.tearDown();
    });

    test('throws UsageException if positional args are given', () {
      final argResults = ArgParser().parse(['a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_serve');
      expect(
          () => buildExecution(context),
          throwsA(isA<UsageException>()
              .having((e) => e.message, 'command name', contains('test_serve'))
              .having((e) => e.message, 'usage', contains('--webdev-args'))
              .having((e) => e.message, 'usage', contains('--build-args'))));
    });

    test('throws UsageException if args are given after a separator', () {
      final argResults = ArgParser().parse(['--', 'a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_serve');
      expect(
          () => buildExecution(context),
          throwsA(isA<UsageException>()
              .having((e) => e.message, 'command name', contains('test_serve'))
              .having((e) => e.message, 'usage', contains('--webdev-args'))
              .having((e) => e.message, 'usage', contains('--build-args'))));
    });

    test('returns config exit code and logs if webdev is not globally activate',
        () {
      overrideAnsiOutput(false, () {
        expect(
            Logger.root.onRecord,
            emitsThrough(severeLogOf(allOf(
                contains('webdev serve could not run'),
                contains('dart pub global activate webdev ^2.0.0')))));

        expect(
            buildExecution(DevToolExecutionContext(),
                    environment: pubCacheWithoutWebdev.envOverride)
                .exitCode,
            ExitCode.config.code);
      });
    });

    group('returns a WebdevServeExecution', () {
      test('(default)', () {
        final execution = buildExecution(DevToolExecutionContext(),
            environment: pubCacheWithWebdev.envOverride);
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, exe.dart);
        expect(execution.process.args,
            orderedEquals(['pub', 'global', 'run', 'webdev', 'serve']));
      });

      test('with args', () {
        final argParser = WebdevServeTool().toCommand('t').argParser;
        final argResults = argParser.parse(
            ['--webdev-args', '-r --debug', '--build-args', '--config foo']);
        final context = DevToolExecutionContext(argResults: argResults);
        final execution = buildExecution(context,
            configuredBuildArgs: ['-o', 'web:build'],
            configuredWebdevArgs: ['web:9000', 'example:9001'],
            environment: pubCacheWithWebdev.envOverride);
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, exe.dart);
        expect(
            execution.process.args,
            orderedEquals([
              'pub',
              'global',
              'run',
              'webdev',
              'serve',
              'web:9000',
              'example:9001',
              '-r',
              '--debug',
              '--',
              '-o',
              'web:build',
              '--config',
              'foo',
            ]));
      });

      test('with verbose=true', () {
        final argParser = WebdevServeTool().toCommand('t').argParser;
        final argResults = argParser.parse(
            ['--webdev-args', '-r --debug', '--build-args', '--config foo']);
        final context =
            DevToolExecutionContext(argResults: argResults, verbose: true);
        final execution = buildExecution(context,
            configuredBuildArgs: ['-o', 'web:build'],
            configuredWebdevArgs: ['web:9000', 'example:9001'],
            environment: pubCacheWithWebdev.envOverride);
        expect(execution.exitCode, isNull);
        expect(execution.process.executable, exe.dart);
        expect(
            execution.process.args,
            orderedEquals([
              'pub',
              'global',
              'run',
              'webdev',
              'serve',
              'web:9000',
              'example:9001',
              '-r',
              '--debug',
              '-v',
              '--',
              '-o',
              'web:build',
              '--config',
              'foo',
              '-v',
            ]));
      });

      test('and logs the test subprocess', () {
        overrideAnsiOutput(false, () {
          expect(
              Logger.root.onRecord,
              emitsThrough(infoLogOf(contains(
                  'dart pub global run webdev serve web --auto restart -- '
                  '--delete-conflicting-outputs -o test:build'))));

          final argParser = WebdevServeTool().toCommand('t').argParser;
          final argResults = argParser.parse([
            '--webdev-args',
            '--auto restart',
            '--build-args',
            '-o test:build'
          ]);
          final context = DevToolExecutionContext(argResults: argResults);
          buildExecution(context,
              configuredBuildArgs: ['--delete-conflicting-outputs'],
              configuredWebdevArgs: ['web'],
              environment: pubCacheWithWebdev.envOverride);
        });
      });
    });
  });
}
