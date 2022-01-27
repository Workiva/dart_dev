import 'dart:convert';

@TestOn('vm')
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
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
          (await tool.process!.stdout.transform(utf8.decoder).join('')).trim();
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

  group('BackgroundProcessTool', () {
    sharedDevToolTests(() => BackgroundProcessTool('true', []).starter);
    sharedDevToolTests(() => BackgroundProcessTool('true', []).stopper);

    test('starter runs the process without waiting for it to complete',
        () async {
      var processHasExited = false;
      final tool = BackgroundProcessTool('sleep', ['5']);
      expect(await tool.starter.run(), isZero);
      unawaited(tool.process!.exitCode.then((_) => processHasExited = true));
      await Future<void>.delayed(Duration.zero);
      expect(processHasExited, isFalse);
      await tool.stopper.run();
    });

    test('stopper stops the process immediately', () async {
      var processHasExited = false;
      final tool = BackgroundProcessTool('sleep', ['5']);
      final stopwatch = Stopwatch()..start();
      expect(await tool.starter.run(), isZero);
      unawaited(tool.process!.exitCode.then((_) => processHasExited = true));
      await Future<void>.delayed(Duration(seconds: 1));
      expect(processHasExited, isFalse);
      expect(await tool.stopper.run(), isZero);
      expect(processHasExited, isTrue);
      expect((stopwatch..stop()).elapsed.inSeconds, lessThan(3));
    });

    test('starter forwards the returned exit code', () async {
      final tool = BackgroundProcessTool('false', [],
          delayAfterStart: Duration(milliseconds: 500));
      expect(await tool.starter.run(), isNonZero);
    });

    test('stopper always returns a zero exit code', () async {
      final tool = BackgroundProcessTool('false', []);
      await tool.starter.run();
      await Future<void>.delayed(Duration(milliseconds: 500));
      expect(await tool.stopper.run(), isZero);
    });

    test('can run from a custom working directory', () async {
      final tool = BackgroundProcessTool('pwd', [],
          workingDirectory: 'lib', delayAfterStart: Duration(seconds: 1));
      expect(await tool.starter.run(), isZero);
      final stdout =
          (await tool.process!.stdout.transform(utf8.decoder).join('')).trim();
      expect(stdout, endsWith('/dart_dev/lib'));
    });

    test('throws UsageException when args are present', () {
      final tool = BackgroundProcessTool('true', []);
      expect(
          () => tool.starter.run(
              DevToolExecutionContext(argResults: ArgParser().parse(['foo']))),
          throwsA(isA<UsageException>()));
    });

    test('logs the subprocess', () {
      expect(Logger.root.onRecord,
          emitsThrough(infoLogOf(contains('true foo bar'))));
      BackgroundProcessTool('true', ['foo', 'bar']).starter.run();
    });
  });
}
