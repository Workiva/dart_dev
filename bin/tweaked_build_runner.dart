// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_runner/src/build_script_generate/bootstrap.dart';
import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) async {
  StreamSubscription<LogRecord> logListener;

  Logger.root.level = Level.ALL;
  var f = File('alsoLogHere.txt');
  var listener1 = stdIOLogListener(verbose: true);
  logListener = Logger.root.onRecord.listen((r) {
    listener1(r);
    f.writeAsStringSync('$r\n', mode: FileMode.append, flush: true);
  });

  while ((exitCode = await generateAndRun(args,
          generateBuildScript: generateMyBuildScript)) ==
      ExitCode.tempFail.code) {}
  await logListener.cancel();
}

Future<String> generateMyBuildScript() async {
  var basic = await generateBuildScript();
  var lines = basic.split('\n');
  lines.insert(7, "import 'package:logging/logging.dart';");
  var startOfMain =
      lines.indexOf(lines.firstWhere((l) => l.contains('void main')));
  lines.insert(startOfMain + 1,
      '  Logger.root.onRecord.listen((r) => print("Ha! \$r\\n"));');
  return lines.join('\n');
}
