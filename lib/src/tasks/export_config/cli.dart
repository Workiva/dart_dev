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

import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/util.dart' show reporter;

class ExportConfigCli extends TaskCli {
  @override
  ArgParser argParser = new ArgParser();

  @override
  final String command = 'export-config';

  @override
  Future<CliResult> run(ArgResults parsedArgs, {bool color: true}) async {
    reporter.log(serializeConfig());

    return new CliResult.success();
  }
}
