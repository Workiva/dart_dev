@TestOn('vm')
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/tools/analyze_tool.dart';

import '../log_matchers.dart';
import 'shared_tool_tests.dart';

void main() {
  final globRoot = 'test/tools/fixtures/analyze/globs/';

  group('AnalyzeTool', () {
    sharedDevToolTests(() => AnalyzeTool());

    test('provides an argParser', () {
      final argParser = AnalyzeTool().argParser;
      expect(argParser.options, contains('analyzer-args'));
      expect(argParser.options['analyzer-args'].type, OptionType.single);
    });
  });

  group('buildArgs', () {
    test('defaults to an empty list', () {
      expect(buildArgs(), isEmpty);
    });

    test('combines configured args and cli args (in that order)', () {
      final argParser = AnalyzeTool().toCommand('t').argParser;
      final argResults = argParser.parse(['--analyzer-args', 'c d']);
      expect(
          buildArgs(argResults: argResults, configuredAnalyzerArgs: ['a', 'b']),
          orderedEquals(['a', 'b', 'c', 'd']));
    });

    test('inserts a verbose flag if not already present', () {
      final argParser = AnalyzeTool().toCommand('t').argParser;
      final argResults = argParser.parse(['--analyzer-args', 'c d']);
      expect(
          buildArgs(
              argResults: argResults,
              configuredAnalyzerArgs: ['a', 'b'],
              verbose: true),
          orderedEquals(['a', 'b', 'c', 'd', '-v']));
    });

    test('does not insert a duplicate verbose flag (-v)', () {
      expect(buildArgs(configuredAnalyzerArgs: ['-v'], verbose: true),
          orderedEquals(['-v']));
    });

    test('does not insert a duplicate verbose flag (--verbose)', () {
      expect(buildArgs(configuredAnalyzerArgs: ['--verbose'], verbose: true),
          orderedEquals(['--verbose']));
    });
  });

  group('buildEntrypoints', () {
    test('defaults to `.`', () {
      expect(buildEntrypoints(root: globRoot), ['.']);
      expect(buildEntrypoints(include: [], root: globRoot), ['.']);
    });

    test('from one glob', () {
      expect(buildEntrypoints(include: [Glob('*.dart')], root: globRoot),
          ['${globRoot}file.dart']);
    });

    test('from multiple globs', () {
      expect(
          buildEntrypoints(
              include: [Glob('*.dart'), Glob('*.txt')], root: globRoot),
          unorderedEquals(['${globRoot}file.dart', '${globRoot}file.txt']));
    });
  });

  group('buildProcess', () {
    test('throws UsageException if positional args are given', () {
      final argResults = ArgParser().parse(['a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_analyze');
      expect(
          () => buildProcess(context),
          throwsA(isA<UsageException>()
              .having(
                  (e) => e.message, 'command name', contains('test_analyze'))
              .having((e) => e.message, 'usage footer',
                  contains('--analyzer-args'))));
    });

    test('throws UsageException if args are given after a separator', () {
      final argResults = ArgParser().parse(['--', 'a']);
      final context = DevToolExecutionContext(
          argResults: argResults, commandName: 'test_analyze');
      expect(
          () => buildProcess(context),
          throwsA(isA<UsageException>()
              .having(
                  (e) => e.message, 'command name', contains('test_analyze'))
              .having((e) => e.message, 'usage footer',
                  contains('--analyzer-args'))));
    });

    test('returns a ProcessDeclaration (default)', () {
      final context = DevToolExecutionContext();
      final process = buildProcess(context);
      expect(process.executable, 'dartanalyzer');
      expect(process.args, orderedEquals(['.']));
    });

    test('returns a ProcessDeclaration (with args)', () {
      final argParser = AnalyzeTool().toCommand('t').argParser;
      final argResults =
          argParser.parse(['--analyzer-args', '--dart-sdk /sdk']);
      final context = DevToolExecutionContext(argResults: argResults);
      final process = buildProcess(context,
          configuredAnalyzerArgs: ['--fatal-infos', '--fatal-warnings'],
          include: [Glob('*.dart'), Glob('*.txt')],
          path: globRoot);
      expect(process.executable, 'dartanalyzer');
      expect(
          process.args,
          orderedEquals([
            '--fatal-infos',
            '--fatal-warnings',
            '--dart-sdk',
            '/sdk',
            '${globRoot}file.dart',
            '${globRoot}file.txt',
          ]));
    });

    test('returns a ProcessDeclaration (verbose)', () {
      final argParser = AnalyzeTool().toCommand('t').argParser;
      final argResults =
          argParser.parse(['--analyzer-args', '--dart-sdk /sdk']);
      final context =
          DevToolExecutionContext(argResults: argResults, verbose: true);
      final process = buildProcess(context,
          configuredAnalyzerArgs: ['--fatal-infos', '--fatal-warnings'],
          include: [Glob('*.dart'), Glob('*.txt')],
          path: globRoot);
      expect(process.executable, 'dartanalyzer');
      expect(
          process.args,
          orderedEquals([
            '--fatal-infos',
            '--fatal-warnings',
            '--dart-sdk',
            '/sdk',
            '-v',
            '${globRoot}file.dart',
            '${globRoot}file.txt',
          ]));
    });
  });

  group('logCommand', () {
    test('with <=5 entrypoints', () {
      expect(Logger.root.onRecord,
          emitsThrough(infoLogOf(contains('dartanalyzer -t a b c d e'))));
      logCommand(['-t'], ['a', 'b', 'c', 'd', 'e']);
    });

    test('with >5 entrypoints', () {
      expect(Logger.root.onRecord,
          emitsThrough(infoLogOf(contains('dartanalyzer -t <6 paths>'))));
      logCommand(['-t'], ['a', 'b', 'c', 'd', 'e', 'f']);
    });

    test('with >5 entrypoints in verbose mode', () {
      expect(Logger.root.onRecord,
          emitsThrough(infoLogOf(contains('dartanalyzer -t a b c d e f'))));
      logCommand(['-t'], ['a', 'b', 'c', 'd', 'e', 'f'], verbose: true);
    });
  });
}
