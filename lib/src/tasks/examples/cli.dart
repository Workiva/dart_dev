library dart_dev.src.tasks.examples.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/io.dart' show reporter;

import 'package:dart_dev/src/tasks/examples/api.dart';
import 'package:dart_dev/src/tasks/examples/config.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class ExamplesCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addOption('hostname',
        defaultsTo: defaultHostname, help: 'The host name to listen on.')
    ..addOption('port',
        defaultsTo: defaultPort.toString(),
        help: 'The base port to listen on.');

  final String command = 'examples';

  Future<CliResult> run(ArgResults parsedArgs) async {
    String hostname =
        TaskCli.valueOf('hostname', parsedArgs, config.examples.hostname);
    var port = TaskCli.valueOf('port', parsedArgs, config.examples.port);
    if (port is String) {
      port = int.parse(port);
    }

    ExamplesTask task = serveExamples(hostname: hostname, port: port);
    reporter.logGroup(task.pubServeCommand, outputStream: task.pubServeOutput);
    await task.done;
    reporter.logGroup(task.dartiumCommand, outputStream: task.dartiumOutput);
    return task.successful ? new CliResult.success() : new CliResult.fail();
  }
}
