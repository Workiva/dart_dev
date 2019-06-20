// Copyright 2019 Workiva Inc.
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

/// A proxy for the `compile_sass` executable from w_common.
///
/// Present so that dart_dev consumers do not have to have a direct dependency
/// on w_common in order to run `pub run dart_dev sass`.
///
/// __Do not run directly - run `pub run dart_dev sass` instead.__
library dart_dev.bin.compile_sass_proxy;

import 'dart:io';

import 'package:dart_dev/src/tasks/sass/api.dart'
    show intentionalInternalProxyArg;
import 'package:dart_dev/util.dart' show reporter;
import 'package:w_common/sass.dart' as wc_compile_sass;

main(List<String> args) async {
  if (!args.contains(intentionalInternalProxyArg)) {
    exitCode = 1;
    reporter.error(
        '[UNSUPPORTED]: Do not run `pub run dart_dev compile_sass_proxy` directly.\n\n'
        'Run `pub run dart_dev sass` instead.');
    return;
  }

  args.remove(intentionalInternalProxyArg);
  await wc_compile_sass.main(args);
}
