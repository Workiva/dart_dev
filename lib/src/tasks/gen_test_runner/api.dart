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

library dart_dev.src.tasks.gen_test_runner.api;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/src/tasks/gen_test_runner/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

Future<GenTestRunnerTask> genTestRunner(
    {String directory,
    Environment environment,
    String filename,
    bool genHtml,
    bool react,
    List<String> scriptTags}) async {
  var executable = 'gen-test-runner';
  var args = ['-d $directory', '-e $environment'];
  react ? args.add('--react') : args.add('--no-react');
  genHtml ? args.add('--genHtml') : args.add('--no-genHtml');

  GenTestRunnerTask task =
      new GenTestRunnerTask('$executable ${args.join(' ')}');

  File generatedRunner = new File('$directory/$filename.dart');
  IOSink writer = generatedRunner.openWrite(mode: FileMode.WRITE);

  Directory testDirectory = new Directory(directory);
  List<File> testFiles = [];
  List<FileSystemEntity> allFiles =
      testDirectory.listSync(recursive: true, followLinks: false);
  allFiles.forEach((FileSystemEntity entity) {
    if (entity is File) {
      if (entity.path.contains(new RegExp(r'_test\.dart$'))) {
        testFiles.add(entity);
        task.testFiles.add(entity.path);
      } else if (!entity.path.endsWith('$filename.dart') &&
          entity.path.contains(new RegExp(r'\.dart$'))) {
        task.excludedFiles.add(entity.path);
      }
    }
  });

  if (environment == Environment.browser) {
    if (genHtml) {
      await testHtmlFileGenerator(directory, filename, scriptTags);
    }
    writer.writeln('@TestOn(\'browser\')');
  } else {
    writer.writeln('@TestOn(\'vm\')');
  }
  writer.writeln();
  writer.writeln('/************ GENERATED FILE ************');
  writer.writeln();
  writer.writeln('This file was generated with the command:');
  String generationCommand = '$executable ';
  args.forEach((String element) {
    generationCommand += '$element ';
  });

  writer.writeln(generationCommand);
  writer.writeln();
  writer.writeln('************* GENERATED FILE ************/');
  writer.writeln();

  testFiles.forEach((File file) {
    Match filenameMatch = new RegExp(r'([^/]+).dart$').firstMatch(file.path);
    String filename = filenameMatch.group(1);
    writer.writeln(
        'import \'${file.path.replaceFirst(directory, '.')}\' as $filename;');
  });

  writer.writeln('import \'package:test/test.dart\';');
  if (react) {
    writer
        .writeln('import \'package:react/react_client.dart\' as reactClient;');
  }
  writer.writeln('');
  writer.writeln('void main() {');
  if (react) {
    writer.writeln('  reactClient.setClientConfiguration();');
  }

  testFiles.forEach((File file) {
    Match filenameMatch = new RegExp(r'([^/]+).dart$').firstMatch(file.path);
    writer.writeln('  ${filenameMatch.group(1)}.main();');
  });

  writer.writeln('}');
  await writer.close();

  task.runnerFile = '$directory/$filename.dart';

  task.successful = true;

  return task;
}

Future testHtmlFileGenerator(
    String directory, String filename, List<String> scriptTags) async {
  File generatedRunner = new File('$directory/$filename.html');
  IOSink writer = generatedRunner.openWrite(mode: FileMode.WRITE);
  writer.writeln('<!DOCTYPE html>');
  writer.writeln('<html>');
  writer.writeln('  <head>');
  writer.writeln('    <title>$filename</title>');
  scriptTags.forEach((tag) {
    writer.writeln('    <script src="$tag"></script>');
  });
  writer.writeln('    <link rel="x-dart-test"  href="$filename.dart">');
  writer.writeln('    <script src="packages/test/dart.js"></script>');
  writer.writeln('  </head>');
  writer.writeln('  <body></body>');
  writer.writeln('</html>');
  await writer.close();
}

class GenTestRunnerTask extends Task {
  final Future done = new Future.value();
  List<String> excludedFiles = [];
  final String generateCommand;
  List<String> testFiles = [];
  String runnerFile;

  GenTestRunnerTask(String this.generateCommand);
}
