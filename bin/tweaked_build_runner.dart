// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Very simplified version of the build_runner main that also does logging of the
/// build summary.
import 'dart:async';
import 'dart:io';

import 'package:build_runner/src/build_script_generate/bootstrap.dart';
import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

String logFile;
const String logFileArgument = '--logFile=';

bool isLogArgument(String arg) => arg.startsWith(logFileArgument);
Future<void> main(List<String> args) async {
  logFile = args
      .firstWhere(isLogArgument, orElse: () => null)
      .substring(logFileArgument.length);
  // We're generating the argument directly into the file, but that means that each run will
  // rebuild the build script??
  args = [
    for (var arg in args)
      if (!isLogArgument(arg)) arg
  ];
  var logListener = Logger.root.onRecord.listen(stdIOLogListener());

  while ((exitCode = await generateAndRun(args,
          generateBuildScript: generateMyBuildScript)) ==
      ExitCode.tempFail.code) {}
  await logListener.cancel();
}

// Tweak the build script to also log to the file named passed in the --logFileName argument.
Future<String> generateMyBuildScript() async {
  var basic = await generateBuildScript();
  var lines = basic.split('\n');
  lines.insert(7, "import 'dart:io';");
  lines.insert(7, "import 'package:logging/logging.dart';");
  var startOfMain =
      lines.indexOf(lines.firstWhere((l) => l.contains('void main')));
  lines.insert(startOfMain + 1,
      '  var log = File("${logFile ?? 'temporaryLogFile.txt'}");');
  lines.insert(startOfMain + 2,
      '  Logger.root.onRecord.listen((r) {log.writeAsString("\$r", mode: FileMode.append);});');
  return lines.join('\n');
}
