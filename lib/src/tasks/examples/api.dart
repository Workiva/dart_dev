library dart_dev.src.tasks.examples.api;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/examples/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

bool hasExamples() {
  Directory exampleDir = new Directory('example');
  return exampleDir.existsSync();
}

ExamplesTask serveExamples(
    {String hostname: defaultHostname, int port: defaultPort}) {
  if (!hasExamples()) throw new Exception(
      'This project does not have any examples.');

  var dartiumExecutable = 'dartium';
  var dartiumArgs = ['http://$hostname:$port'];

  var pubServeExecutable = 'pub';
  var pubServeArgs = [
    'serve',
    '--hostname=$hostname',
    '--port=$port',
    'example'
  ];

  TaskProcess pubServeProcess =
      new TaskProcess(pubServeExecutable, pubServeArgs);
  TaskProcess dartiumProcess = new TaskProcess(dartiumExecutable, dartiumArgs);

  ExamplesTask task = new ExamplesTask(
      '$dartiumExecutable ${dartiumArgs.join(' ')}',
      '$pubServeExecutable ${pubServeArgs.join(' ')}',
      Future.wait([dartiumProcess.done, pubServeProcess.done]));

  pubServeProcess.stdout.listen(task._pubServeOutput.add);
  pubServeProcess.stderr.listen(task._pubServeOutput.addError);
  pubServeProcess.exitCode.then((code) {
    task.successful = code <= 0;
  });

  dartiumProcess.stdout.listen(task._dartiumOutput.add);
  dartiumProcess.stderr.listen(task._dartiumOutput.addError);

  return task;
}

class ExamplesTask extends Task {
  final Future done;
  final String dartiumCommand;
  final String pubServeCommand;

  StreamController<String> _dartiumOutput = new StreamController();
  StreamController<String> _pubServeOutput = new StreamController();

  ExamplesTask(String this.dartiumCommand, String this.pubServeCommand,
      Future this.done) {
    done.then((_) {
      _dartiumOutput.close();
      _pubServeOutput.close();
    });
  }

  Stream<String> get dartiumOutput => _dartiumOutput.stream;
  Stream<String> get pubServeOutput => _pubServeOutput.stream;
}
