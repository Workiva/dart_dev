@TestOn('vm')
import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/tools/compound_tool.dart';
import 'package:test/test.dart';

import 'shared_tool_tests.dart';

void main() {
  group('CompoundTool', () {
    sharedDevToolTests(() => CompoundTool());

    late int currentTool;
    late List<int> toolsRan;
    setUp(() {
      currentTool = 0;
      toolsRan = [];
    });

    DevTool tool({ArgParser? argParser, Function? callback, int? exitCode}) {
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
      final ct = CompoundTool()
        ..addTool(tool())
        ..addTool(tool());
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

    test('runs tools with their own ArgResults by default', () async {
      final tool1 = DevTool.fromFunction((context) {
        expect(context.argResults!['foo'], isTrue);
        expect(() => context.argResults!['bar'], throwsArgumentError);
        expect(context.argResults!.rest, isEmpty);
        return 0;
      }, argParser: ArgParser()..addFlag('foo'));
      final tool2 = DevTool.fromFunction((context) {
        expect(context.argResults!['bar'], isTrue);
        expect(() => context.argResults!['foo'], throwsArgumentError);
        expect(context.argResults!.rest, isEmpty);
        return 0;
      }, argParser: ArgParser()..addFlag('bar'));

      final ct = CompoundTool()
        ..addTool(tool1)
        ..addTool(tool2);
      await ct.run(DevToolExecutionContext(
          argResults: ct.argParser.parse(['--foo', '--bar', 'baz'])));
    });

    test('runs tools with a custom ArgMapper, if provided', () async {
      final tool = DevTool.fromFunction((context) {
        expect(context.argResults!['foo'], isTrue);
        expect(context.argResults!.rest, orderedEquals(['bar', 'baz']));
        return 0;
      }, argParser: ArgParser()..addFlag('foo'));

      final ct = CompoundTool()..addTool(tool, argMapper: takeAllArgs);
      await ct.run(DevToolExecutionContext(
          argResults: ct.argParser.parse(['--foo', 'bar', 'baz'])));
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
        expect(cap.commands['no-parser']!.options, isEmpty);
        expect(cap.commands['has-parser']!.options.keys, contains('foo'));
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
      final cap = CompoundArgParser()
        ..addParser(parser1)
        ..addParser(parser2);
      final args = ['--flag', '--option=foo', 'bar'];
      final argResults = cap.parse(args);
      expect(argResults['flag'], isTrue);
      expect(argResults['option'], 'foo');
      expect(argResults.rest, ['bar']);
    });

    test('provides a combined usage output', () {
      final parser1 = ArgParser()..addFlag('flag');
      final parser2 = ArgParser()..addOption('option');
      final cap = CompoundArgParser()
        ..addParser(parser1)
        ..addParser(parser2);
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

  group('contextForTool', () {
    test('with null argResults', () {
      final context = DevToolExecutionContext();
      expect(context, same(contextForTool(context, null)));
    });

    test('maps the argResults', () {
      final fooParser = ArgParser()..addFlag('foo');
      final fooTool = DevTool.fromFunction((_) => 0, argParser: fooParser);

      final barParser = ArgParser()..addFlag('bar');
      final barTool = DevTool.fromFunction((_) => 0, argParser: barParser);

      final compoundTool = CompoundTool()
        ..addTool(fooTool)
        ..addTool(barTool);
      final baseContext = DevToolExecutionContext(
          argResults: compoundTool.argParser.parse(['--foo', '--bar']));

      final spec = DevToolSpec(RunWhen.passing, fooTool);
      final result = contextForTool(baseContext, spec);
      expect(result, isNot(same(baseContext)));
      expect(result.argResults!.options, unorderedEquals(['foo']));
    });
  });

  group('optionArgsOnly', () {
    test('recreates the list of option args without positional args', () {
      final originalParser = ArgParser()
        ..addFlag('flag')
        ..addOption('opt')
        ..addMultiOption('multi');
      final originalResults = originalParser.parse([
        '--flag',
        '--opt',
        'opt',
        '--multi',
        'one',
        '--multi',
        'two',
        'foo',
        'bar',
      ]);
      final args = optionArgsOnly(originalResults);
      expect(
          args,
          unorderedEquals([
            '--flag',
            '--opt=opt',
            '--multi=one',
            '--multi=two',
          ]));
    });

    test('filters by allowedOptions if given', () {
      final originalParser = ArgParser()
        ..addFlag('flag')
        ..addFlag('bad-flag')
        ..addOption('opt')
        ..addOption('bad-opt')
        ..addMultiOption('multi')
        ..addMultiOption('bad-multi');
      final originalResults = originalParser.parse([
        '--flag',
        '--bad-flag',
        '--opt',
        'opt',
        '--bad-opt',
        'bad',
        '--multi',
        'one',
        '--multi',
        'two',
        '--bad-multi',
        'bad',
        'foo',
        'bar',
      ]);
      final args = optionArgsOnly(originalResults,
          allowedOptions: ['flag', 'opt', 'multi']);
      expect(
          args,
          unorderedEquals([
            '--flag',
            '--opt=opt',
            '--multi=one',
            '--multi=two',
          ]));
    });
  });

  group('takeOptionArgs', () {
    test('filters out unsupported options and positional args', () {
      final fooParser = ArgParser()..addFlag('foo');
      final barParser = ArgParser()..addFlag('bar');
      final compoundParser = CompoundArgParser()
        ..addParser(fooParser)
        ..addParser(barParser);
      final results = compoundParser.parse(['--foo', '--bar', 'baz']);
      final mapped = takeOptionArgs(fooParser, results);
      expect(mapped.options, unorderedEquals(['foo']));
      expect(mapped.rest, isEmpty);
    });

    test('with empty parser and results', () {
      final parser = ArgParser();
      final mapped = takeOptionArgs(parser, parser.parse([]));
      expect(mapped.options, isEmpty);
      expect(mapped.rest, isEmpty);
    });
  });

  group('takeAllArgs', () {
    test('filters out unsupported options but includes positional args', () {
      final fooParser = ArgParser()..addFlag('foo');
      final barParser = ArgParser()..addFlag('bar');
      final compoundParser = CompoundArgParser()
        ..addParser(fooParser)
        ..addParser(barParser);
      final results = compoundParser.parse(['--foo', '--bar', 'baz']);
      final mapped = takeAllArgs(fooParser, results);
      expect(mapped.options, unorderedEquals(['foo']));
      expect(mapped.rest, orderedEquals(['baz']));
    });

    test('with empty parser and results', () {
      final parser = ArgParser();
      final mapped = takeAllArgs(parser, parser.parse([]));
      expect(mapped.options, isEmpty);
      expect(mapped.rest, isEmpty);
    });
  });
}
