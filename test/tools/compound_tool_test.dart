@TestOn('vm')
import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/tools/compound_tool.dart';
import 'package:test/test.dart';

import 'shared_tool_tests.dart';

void main() {
  group('CompoundTool', () {
    sharedDevToolTests(() => CompoundTool());

    int currentTool;
    List<int> toolsRan;
    setUp(() {
      currentTool = 0;
      toolsRan = [];
    });

    DevTool tool({ArgParser argParser, Function callback, int exitCode}) {
      final toolNum = currentTool++;
      return DevTool.fromFunction((_) {
        if (callback != null) {
          callback();
        }
        toolsRan.add(toolNum);
        return exitCode ?? 0;
      }, argParser: argParser);
    }

    test('uses the first sub-tool description by default', () {
      final ct = CompoundTool()
        ..addTool(tool())
        ..addTool(tool()..description = 'desc1')
        ..addTool(tool()..description = 'desc2');
      expect(ct.description, 'desc1');
    });

    test('returns the first non-zero exit code', () async {
      final ct = CompoundTool()
        ..addTool(tool())
        ..addTool(tool(exitCode: 1))
        ..addTool(tool(exitCode: 2), alwaysRun: true);
      expect(await ct.run(), 1);
    });

    test('runs tools in order', () async {
      final ct = CompoundTool()..addTool(tool())..addTool(tool());
      expect(await ct.run(), 0);
      expect(toolsRan, orderedEquals([0, 1]));
    });

    test('runs tools based on their run conditions', () async {
      final ct = CompoundTool()
        ..addTool(tool(exitCode: 1))
        ..addTool(tool()) // shouldn't run
        ..addTool(tool(), alwaysRun: true);
      expect(await ct.run(), 1);
      expect(toolsRan, orderedEquals([0, 2]));
    });

    test('runs tools with a shared, compound context', () async {
      final parser = ArgParser()..addFlag('foo');
      final tool1 = DevTool.fromFunction((context) {
        expect(context.argResults['foo'], isTrue);
        return 0;
      }, argParser: parser);
      final tool2 = DevTool.fromFunction((context) {
        expect(context.argResults['foo'], isTrue);
        return 0;
      });

      final ct = CompoundTool()..addTool(tool1)..addTool(tool2);
      await ct
          .run(DevToolExecutionContext(argResults: parser.parse(['--foo'])));
    });
  });

  group('CompoundArgParser', () {
    group('addParser', () {
      test('adds all commands', () {
        final parser = ArgParser()
          ..addCommand('no-parser')
          ..addCommand('has-parser', ArgParser()..addFlag('foo'));
        final cap = CompoundArgParser()..addParser(parser);
        expect(cap.commands.keys, containsAll(['no-parser', 'has-parser']));
        expect(cap.commands['no-parser'].options, isEmpty);
        expect(cap.commands['has-parser'].options.keys, contains('foo'));
      });

      test('adds all options', () {
        final parser = ArgParser()
          ..addFlag('flag')
          ..addMultiOption('multi')
          ..addOption('single');
        final cap = CompoundArgParser()..addParser(parser);
        expect(cap.options.keys, containsAll(['flag', 'multi', 'single']));
      });

      test('throws if commands collide', () {
        final parser1 = ArgParser()..addCommand('foo');
        final parser2 = ArgParser()..addCommand('foo');
        final cap = CompoundArgParser()..addParser(parser1);
        expect(() => cap.addParser(parser2), throwsArgumentError);
      });

      test('throws if options collide', () {
        final parser1 = ArgParser()..addFlag('foo');
        final parser2 = ArgParser()..addOption('foo');
        final cap = CompoundArgParser()..addParser(parser1);
        expect(() => cap.addParser(parser2), throwsArgumentError);
      });
    });

    test('parses all options', () {
      final parser1 = ArgParser()..addFlag('flag');
      final parser2 = ArgParser()..addOption('option');
      final cap = CompoundArgParser()..addParser(parser1)..addParser(parser2);
      final args = ['--flag', '--option=foo', 'bar'];
      final argResults = cap.parse(args);
      expect(argResults['flag'], isTrue);
      expect(argResults['option'], 'foo');
      expect(argResults.rest, ['bar']);
    });

    test('provides a combined usage output', () {
      final parser1 = ArgParser()..addFlag('flag');
      final parser2 = ArgParser()..addOption('option');
      final cap = CompoundArgParser()..addParser(parser1)..addParser(parser2);
      expect(
          cap.usage, allOf(contains(parser1.usage), contains(parser2.usage)));
    });
  });

  group('shouldRunTool', () {
    test('when=always, exit=0', () {
      expect(shouldRunTool(RunWhen.always, 0), isTrue);
    });

    test('when=always, exit=1', () {
      expect(shouldRunTool(RunWhen.always, 1), isTrue);
    });

    test('when=passing, exit=0', () {
      expect(shouldRunTool(RunWhen.passing, 0), isTrue);
    });

    test('when=passing, exit=1', () {
      expect(shouldRunTool(RunWhen.passing, 1), isFalse);
    });
  });
}
