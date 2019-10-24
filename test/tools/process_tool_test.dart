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
