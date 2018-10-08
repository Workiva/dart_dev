// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('vm')
library dart_dev.test.integration.dart_x_only_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String projectPath = 'test_fixtures/dart_x_only';

Future<Result> runDart1Only(Iterable<String> targetArgs) =>
    run('dart1-only', targetArgs);
Future<Result> runDart2Only(Iterable<String> targetArgs) =>
    run('dart2-only', targetArgs);

Future<Result> run(String task, Iterable<String> targetArgs) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);

  var args = ['run', 'dart_dev', task]..addAll(targetArgs);
  TaskProcess process =
      new TaskProcess('pub', args, workingDirectory: projectPath);
  final stdout = await process.stdout.join('\n');
  print(stdout);

  final skippedRegex = new RegExp(r'Skipped \(Dart');
  final skipped = stdout.contains(skippedRegex);

  return new Result(await process.exitCode, skipped);
}

class Result {
  final int exitCode;
  final bool skipped;
  Result(this.exitCode, this.skipped);
}

void main() {
  group('(SDK=Dart1)', () {
    group('dart1-only Task', () {
      test('requires a target', () async {
        final result = await runDart1Only([]);
        expect(result.exitCode, 1);
      });

      test('runs a ddev task', () async {
        final result = await runDart1Only(['analyze']);
        expect(result.skipped, isFalse);
        expect(result.exitCode, 0);
      });

      test('runs a ddev task with args', () async {
        final result =
            await runDart1Only(['--', 'analyze', '--no-fatal-warnings']);
        expect(result.skipped, isFalse);
        expect(result.exitCode, 0);
      });

      test('runs an executable', () async {
        final result = await runDart1Only(['dartdoc']);
        expect(result.skipped, isFalse);
        expect(result.exitCode, 0);
      });

      test('runs an executable with args', () async {
        final result = await runDart1Only(['--', 'pub', 'get', '--offline']);
        expect(result.skipped, isFalse);
        expect(result.exitCode, 0);
      });
    });

    group('dart2-only Task', () {
      test('requires a target', () async {
        final result = await runDart2Only(<String>[]);
        expect(result.exitCode, 1);
      });

      test('is skipped', () async {
        final result = await runDart2Only(['coverage']);
        expect(result.skipped, isTrue);
        expect(result.exitCode, 0);
      });
    });
  }, tags: 'dart1-only');

// TODO
//  group('(SDK=Dart2)', () {
//
//    group('dart1-only Task', () {
//
//    });
//
//    group('dart2-only Task', () {
//
//    });
//
//  }, tags: 'dart2-only');
}
