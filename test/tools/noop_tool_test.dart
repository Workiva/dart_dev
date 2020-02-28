import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:dart_dev/src/tools/noop_tool.dart';

import '../log_matchers.dart';

void main() {
  group('NoopTool', () {
    test('(default)', () {
      String buildArgInput = 'warning';
      expect(Logger.root.onRecord,
          emitsThrough(severeLogOf(contains(buildArgInput))));

      var tool = NoopTool()..buildArg = buildArgInput;

      tool.run(null);
    });
  });
}
