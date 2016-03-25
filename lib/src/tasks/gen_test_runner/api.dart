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

Future<GenTestRunnerTask> genTestRunner(TestRunnerConfig currentConfig) async {
  var taskTitle = 'gen-test-runner';
  var args = ['-d ${currentConfig.directory}', '-e ${currentConfig.env}'];
  currentConfig.genHtml ? args.add('--genHtml') : args.add('--no-genHtml');

  GenTestRunnerTask task =
      new GenTestRunnerTask('$taskTitle ${args.join(' ')}');

  var currentDirectory = currentConfig.directory;
  if (!currentDirectory.endsWith('/')) {
    currentDirectory += '/';
  }

  File generatedRunner =
      new File('${currentDirectory}/${currentConfig.filename}.dart');
  IOSink writer = generatedRunner.openWrite(mode: FileMode.WRITE);

  Directory testDirectory = new Directory(currentDirectory);
  List<File> testFiles = [];
  List<FileSystemEntity> allFiles =
      testDirectory.listSync(recursive: true, followLinks: false);
  allFiles.forEach((FileSystemEntity entity) {
    var isTestRunner = entity.path.endsWith('${currentConfig.filename}.dart');
    if (entity is File) {
      if (entity.path.endsWith('_test.dart') && !isTestRunner) {
        testFiles.add(entity);
        task.testFiles.add(entity.path);
      } else if (!isTestRunner && entity.path.endsWith('.dart')) {
        task.excludedFiles.add(entity.path);
      }
    }
  });

  if (currentConfig.env == Environment.browser) {
    if (currentConfig.genHtml) {
      await testHtmlFileGenerator(
          currentDirectory, currentConfig.filename, currentConfig.htmlHeaders);
    }
    writer.writeln('@TestOn(\'browser\')');
  } else {
    writer.writeln('@TestOn(\'vm\')');
  }
  writer.writeln(
      'library ${currentDirectory.replaceAll('/','.')}${currentConfig.filename};');
  writer.writeln();

  testFiles.forEach((File file) {
    var testPath = file.path.replaceFirst(currentDirectory, '');
    writer.writeln(
        'import \'${'./'+testPath}\' as ${testPath.replaceAll('/','_').substring(0, testPath.length - 5)};');
  });

  writer.writeln('import \'package:test/test.dart\';');

  if (currentConfig.dartHeaders.isNotEmpty) {
    currentConfig.dartHeaders.forEach((String header) {
      writer.writeln(header);
    });
  }

  writer.writeln('');
  writer.writeln('void main() {');

  if (currentConfig.preTestCommands.isNotEmpty) {
    currentConfig.preTestCommands.forEach((String command) {
      writer.writeln('  $command');
    });
  }

  testFiles.forEach((File file) {
    var testPath = file.path.replaceFirst(currentDirectory, '');
    writer.writeln(
        '  ${testPath.replaceAll('/','_').substring(0, testPath.length - 5)}.main();');
  });

  writer.writeln('}');
  await writer.close();

  task.runnerFile = '${currentDirectory}${currentConfig.filename}.dart';

  task.successful = true;

  return task;
}

Future testHtmlFileGenerator(
    String directory, String filename, List<String> htmlHeaders) async {
  File generatedRunner = new File('$directory/$filename.html');
  IOSink writer = generatedRunner.openWrite(mode: FileMode.WRITE);
  writer.writeln('<!DOCTYPE html>');
  writer.writeln('<html>');
  writer.writeln('  <head>');
  writer.writeln('    <title>$filename</title>');
  htmlHeaders.forEach((header) {
    writer.writeln('    $header');
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
