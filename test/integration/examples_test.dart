@TestOn('vm')
library dart_dev.test.integration.examples_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectWithExamples = 'test/fixtures/examples/examples_dir';
const String projectWithoutExamples = 'test/fixtures/examples/no_examples_dir';

Future<bool> serveExamplesFor(String projectPath) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  TaskProcess process = new TaskProcess('pub', ['run', 'dart_dev', 'examples'],
      workingDirectory: projectPath);

  bool served = false;

  Pattern pubServePattern = new RegExp(r'pub serve .* example');
  process.stdout.listen((line) {
    if (line.contains(pubServePattern)) {
      served = true;
      process.kill();
    }
  });

  await process.done;
  return served;
}

void main() {
  group('Examples Task', () {
    test('should warn if no examples directory found', () async {
      expect(await serveExamplesFor(projectWithoutExamples), isFalse);
    });

    test('should serve if examples directory found', () async {
      expect(await serveExamplesFor(projectWithExamples), isTrue);
    });
  });
}
