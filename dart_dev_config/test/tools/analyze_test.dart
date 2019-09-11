@TestOn('vm')
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:dart_dev_config/src/dart_dev_tool.dart';
import 'package:dart_dev_config/src/tools/analyze_tool.dart';

import 'shared_tool_tests.dart';

void main() {
  final globRoot = 'test/tools/fixtures/analyze/globs/';

  group('AnalyzeTool', () {
    sharedDevToolTests(() => AnalyzeTool());

    test('toCommand overrides the argParser', () {
      final argParser = AnalyzeTool().toCommand('t').argParser;
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
    setUp(() {
      Logger.root.level = Level.ALL;
    });

    test('with <=5 entrypoints', () {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('dartanalyzer -t a b c d e') &&
              record.level == Level.INFO)));
      logCommand(['-t'], ['a', 'b', 'c', 'd', 'e']);
    });

    test('with >5 entrypoints', () {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('dartanalyzer -t <6 paths>') &&
              record.level == Level.INFO)));
      logCommand(['-t'], ['a', 'b', 'c', 'd', 'e', 'f']);
    });

    test('with >5 entrypoints in verbose mode', () {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('dartanalyzer -t a b c d e f') &&
              record.level == Level.INFO)));
      logCommand(['-t'], ['a', 'b', 'c', 'd', 'e', 'f'], verbose: true);
    });
  });

  group('buildAnalyzerIncludeGlobs', () {
    // Known dart project directories (except for lib/).
    final knownDartDirs = [
      'benchmark',
      'bin',
      'example',
      'test',
      'tool',
      'web',
    ];

    test('includes all known dart file locations by default', () {
      final include = buildAnalyzerIncludeGlobs();
      final expectedMatches = [
        // File in the root of the project
        'file.dart',
        // Public entry points in lib/
        'lib/public.dart',
        'lib/nested/public.dart',
        // Dart file in any of the known Dart dirs and at any nesting level
        for (final dir in knownDartDirs) ...[
          '$dir/file.dart',
          '$dir/nested/file.dart'
        ],
      ];
      for (final path in expectedMatches) {
        expect(include.any((glob) => glob.matches(path)), isTrue,
            reason:
                'Expected $path to match one of the default include globs.');
      }
    });

    test('excludes private lib files', () {
      final include = buildAnalyzerIncludeGlobs();
      for (final glob in include) {
        expect(glob.matches('lib/src/private.dart'), isFalse,
            reason:
                'Expected private lib file to not match, but was matched by $glob');
      }
    });

    test('can opt out of each of the known dart file locations', () {
      final include = buildAnalyzerIncludeGlobs(
        includeBenchmark: false,
        includeBin: false,
        includeExample: false,
        includeLib: false,
        includeRoot: false,
        includeTest: false,
        includeTool: false,
        includeWeb: false,
      );
      final expectedNonMatches = [
        // File in the root of the project
        'file.dart',
        // Public entry points in lib/
        'lib/public.dart',
        'lib/nested/public.dart',
        // Dart file in any of the known Dart dirs and at any nesting level
        for (final dir in knownDartDirs) ...[
          '$dir/file.dart',
          '$dir/nested/file.dart'
        ],
      ];
      for (final path in expectedNonMatches) {
        for (final glob in include) {
          expect(glob.matches(path), isFalse,
              reason: '$path was unexpectedly matched by $glob');
        }
      }
    });
  });
}
