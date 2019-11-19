import 'dart:convert';

@TestOn('vm')
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../log_matchers.dart';
import 'shared_tool_tests.dart';

void main() {
  group('ProcessTool', () {
    sharedDevToolTests(() => DevTool.fromProcess('true', []));

    test('forwards the returned exit code', () async {
      final tool = DevTool.fromProcess('false', []);
      expect(await tool.run(), isNonZero);
    });

    test('can run from a custom working directory', () async {
      final tool = DevTool.fromProcess('pwd', [], workingDirectory: 'lib')
          as ProcessTool;
      expect(await tool.run(), isZero);
      final stdout =
          (await tool.process.stdout.transform(utf8.decoder).join('')).trim();
      expect(stdout, endsWith('/dart_dev/lib'));
    });

    test('throws UsageException when args are present', () {
      final tool = DevTool.fromProcess('true', []);
      expect(
          () => tool.run(
              DevToolExecutionContext(argResults: ArgParser().parse(['foo']))),
          throwsA(isA<UsageException>()));
    });

    test('logs the subprocess', () {
      expect(Logger.root.onRecord,
          emitsThrough(infoLogOf(contains('true foo bar'))));
      DevTool.fromProcess('true', ['foo', 'bar']).run();
    });
  });
}
