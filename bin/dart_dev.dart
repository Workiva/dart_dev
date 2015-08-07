library dart_dev.bin.dart_dev;

import 'dart:io';

import 'package:dart_dev/dart_dev.dart' show dev;
import 'package:dart_dev/process.dart' show TaskProcess;

main(List<String> args) async {
  File devFile = new File('./tool/dev.dart');

  if (devFile.existsSync()) {
    // If dev.dart exists, run that to allow configuration.
    var newArgs = [devFile.path]..addAll(args);
    TaskProcess process = new TaskProcess('dart', newArgs);
    process.stdout.listen(stdout.writeln);
    process.stderr.listen(stderr.writeln);
    await process.done;
  } else {
    // Otherwise, run with defaults.
    await dev(args);
  }
}
