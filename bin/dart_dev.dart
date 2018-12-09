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

library dart_dev.bin.dart_dev;

import 'dart:io';

import 'package:dart_dev/dart_dev.dart' show dev;
import 'package:dart_dev/util.dart' show TaskProcess;

main(List<String> args) async {
  File devFile = new File('./tool/dev.dart');

  if (devFile.existsSync()) {
    // If dev.dart exists, run that to allow configuration.
    var newArgs = [devFile.path]..addAll(args);
    TaskProcess process = new TaskProcess('dart', newArgs);
    stdout.addStream(process.stdoutRaw);
    stderr.addStream(process.stderrRaw);
    await process.done;
    exitCode = await process.exitCode;
  } else {
    // Otherwise, run with defaults.
    await dev(args);
  }
}
