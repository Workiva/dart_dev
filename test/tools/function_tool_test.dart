@TestOn('vm')
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../log_matchers.dart';
import 'shared_tool_tests.dart';

void main() {
  group('FunctionTool', () {
    sharedDevToolTests(() => DevTool.fromFunction((_) => 0));

    test('forwards the returned exit code', () async {
      final tool = DevTool.fromFunction((_) => 1);
      expect(await tool.run(), 1);
    });

    test('throws UsageException when no ArgParser given but args are present',
        () {
      final tool = DevTool.fromFunction((_) => 0);
      expect(
          () => tool.run(
              DevToolExecutionContext(argResults: ArgParser().parse(['foo']))),
          throwsA(isA<UsageException>()));
    });

    test('accepts a custom ArgParser', () async {
      final parser = ArgParser()..addFlag('flag');
      final tool = DevTool.fromFunction((context) {
        expect(context.argResults!['flag'], isTrue);
        return 0;
      }, argParser: parser);
      await tool
          .run(DevToolExecutionContext(argResults: parser.parse(['--flag'])));
    });

    test('allows a custom ArgParser and args after a separator', () async {
      final tool = DevTool.fromFunction((_) => 0, argParser: ArgParser());
      await tool.run(DevToolExecutionContext(
          argResults: ArgParser().parse(['--', 'foo'])));
    });

    test('logs a warning if no exit code is returned', () {
      expect(Logger.root.onRecord,
          emitsThrough(warningLogOf(contains('did not return an exit code'))));
      DevTool.fromFunction((_) => null).run();
    });
  });
}
