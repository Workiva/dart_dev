@TestOn('vm')
import 'dart:async';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:dart_dev/src/commands/analyze_command.dart';

void main() {
  group('assertNoPositionalArgsBeforeSeparator', () {
    final commandName = 'test';
    bool usageExceptionCalled;
    void usageException(String msg) {
      usageExceptionCalled = true;
      expect(msg, contains('The "$commandName" command'));
    }

    setUp(() {
      usageExceptionCalled = false;
    });

    test('calls usageException callback if assertion fails', () {
      final argResults = ArgParser().parse(['positional', 'args']);
      AnalyzeCommand.assertNoPositionalArgsBeforeSeparator(
          commandName, argResults, usageException);
      expect(usageExceptionCalled, isTrue);
    });

    test('does not call usageException callback if assertion passes', () {
      final argResults = ArgParser().parse([]);
      AnalyzeCommand.assertNoPositionalArgsBeforeSeparator(
          commandName, argResults, usageException);
      expect(usageExceptionCalled, isFalse);
    });
  });

  group('buildDartanalyzerArgs()', () {
    test('conacatenates the configured args with the rest args', () {
      final config = AnalyzeConfig(dartanalyzerArgs: ['config', 'foo']);
      final argResults = ArgParser().parse(['rest', 'bar']);
      expect(AnalyzeCommand.buildDartanalyzerArgs(config, argResults),
          orderedEquals(['config', 'foo', 'rest', 'bar']));
    });

    test('defaults the configured args to an empty list if missing', () {
      final config = AnalyzeConfig();
      final argResults = ArgParser().parse(['rest', 'bar']);
      expect(AnalyzeCommand.buildDartanalyzerArgs(config, argResults),
          orderedEquals(['rest', 'bar']));
    });

    test('no args', () {
      final config = AnalyzeConfig();
      final argResults = ArgParser().parse([]);
      expect(AnalyzeCommand.buildDartanalyzerArgs(config, argResults), []);
    });
  });

  group('buildEntrypoints', () {
    final root = 'test/tools/fixtures/analyze_tool';
    test('defaults to `.`', () {
      final config = AnalyzeConfig();
      expect(AnalyzeCommand.buildEntrypoints(config, root: root), ['.']);
    });

    test('from one glob', () {
      final config = AnalyzeConfig(include: [Glob('*.dart')]);
      expect(AnalyzeCommand.buildEntrypoints(config, root: root),
          ['$root/file.dart']);
    });

    test('from multiple globs', () {
      final config = AnalyzeConfig(include: [Glob('*.dart'), Glob('*.txt')]);
      expect(AnalyzeCommand.buildEntrypoints(config, root: root),
          unorderedEquals(['$root/file.dart', '$root/file.txt']));
    });
  });

  group('logDartanalyzerCommand', () {
    StreamSubscription sub;

    setUp(() {
      Logger.root.level = Level.ALL;
    });

    tearDown(() async {
      await sub?.cancel();
    });

    test('with <=5 entrypoints', () {
      sub = Logger.root.onRecord.listen(expectAsync1((r) {
        expect(r.message, contains('dartanalyzer -t a b c d e'));
      }));
      AnalyzeCommand.logDartanalyzerCommand(['-t'], ['a', 'b', 'c', 'd', 'e']);
    });

    test('with >5 entrypoints', () {
      sub = Logger.root.onRecord.listen(expectAsync1((r) {
        expect(r.message, contains('dartanalyzer -t <6 paths>'));
      }));
      AnalyzeCommand.logDartanalyzerCommand(
          ['-t'], ['a', 'b', 'c', 'd', 'e', 'f']);
    });

    test('with >5 entrypoints in verbose mode', () {
      sub = Logger.root.onRecord.listen(expectAsync1((r) {
        expect(r.message, contains('dartanalyzer -t a b c d e f'));
      }));
      AnalyzeCommand.logDartanalyzerCommand(
          ['-t'], ['a', 'b', 'c', 'd', 'e', 'f'],
          verbose: true);
    });
  });

  test('slow', () async {
    expect(
        await Future.delayed(Duration(seconds: 5)).then((_) => true), isTrue);
  });
}
