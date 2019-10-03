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

library dart_dev.src.tasks.format.api;

import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_dev/src/tasks/sass/cli.dart';
import 'package:meta/meta.dart';
import 'package:w_common/sass.dart' as wc;
import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/task.dart';

const String intentionalInternalProxyArg = '--iprx=true';

SassTask sass({
  @required String sourceDir,
  @required String outputDir,
  @required List<String> watchDirs,
  bool release: false,
  bool preReleaseCheck: false,
  ArgResults parsedArgs,
}) {
  var executable = 'pub';
  var args = <String>[
    'run',
    'dart_dev:compile_sass_proxy',
    intentionalInternalProxyArg,
  ];

  final reservedArgs = <String, dynamic>{
    '--${wc.sourceDirArg}': sourceDir,
    '--${wc.outputDirArg}': outputDir,
    '--${wc.watchDirsArg}': watchDirs,
    '--${wc.outputStyleArg}': release ? 'compressed' : 'expanded',
    // Make sure the file name matches the un-minified checked in source when the release option is set.
    '--${wc.compressedOutputStyleFileExtensionArg}': release
        ? parsedArgs[wc.expandedOutputStyleFileExtensionArg]
        : parsedArgs[wc.compressedOutputStyleFileExtensionArg],
  };

  reservedArgs.forEach((argName, argValue) {
    if (argValue != null) {
      if (argName == '--${wc.outputDirArg}' &&
          argValue == reservedArgs['--${wc.sourceDirArg}']) return;
      if (argName == '--${wc.compressedOutputStyleFileExtensionArg}' &&
          argValue == '--${wc.compressedOutputStyleFileExtensionDefaultValue}')
        return;
      if (argName == '--${wc.expandedOutputStyleFileExtensionArg}' &&
          argValue == '--${wc.expandedOutputStyleFileExtensionDefaultValue}')
        return;

      args.add('$argName=$argValue');
    }
  });

  for (var arg in parsedArgs.arguments
      .where((_arg) => !reservedArgs.keys.any((key) => _arg.startsWith(key)))) {
    if (arg == '--$releaseArgName' || arg == '-$releaseArgAbbr') continue;

    args.add(arg);
  }

  for (var arg in parsedArgs.rest
      .where((_arg) => !reservedArgs.keys.any((key) => _arg.startsWith(key)))) {
    args.add(arg);
  }

  if (preReleaseCheck) {
    args
      ..removeWhere((arg) => arg.contains('--${wc.outputStyleArg}'))
      ..add('--${wc.outputStyleArg}=expanded')
      ..add('--check');
  }

  final process = new TaskProcess(executable, args);
  final task = new SassTask(
      '$executable ${args.join(' ')}', process.done.then((_) => null));
  process.stdout.listen(task._sassOutput.add);
  process.stderr.listen(task._sassOutput.addError);
  process.exitCode.then((code) {
    task.successful = code <= 0;
  });

  return task;
}

class SassTask extends Task {
  @override
  final Future<Null> done;
  final String sassCommand;

  StreamController<String> _sassOutput = new StreamController();

  SassTask(String this.sassCommand, this.done);

  Stream<String> get sassOutput => _sassOutput.stream;
}
