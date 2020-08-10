import 'dart:async';
import 'dart:io';

import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/utils.dart';

import '../tools/format_tool.dart';

class OverReactFormatTool extends DevTool {
  /// Wrap lines longer than this.
  ///
  /// Default is 80.
  int lineLength;

  @override
  String description =
      'Format dart files in this package with over_react_format.';

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    Iterable<String> paths = context?.argResults?.rest;
    if (paths?.isEmpty ?? true) {
      context.usageException(
          '"hackFastFormat" must specify targets to format.\n'
          'hackFastFormat should only be used to format specific files. '
          'Running the command over an entire project may format files that '
          'would be excluded using the standard "format" command.');
    }
    final args = [
      'run',
      'over_react_format',
      if (lineLength != null) '--line-length=$lineLength'
    ];
    final process = ProcessDeclaration('pub', [...args, ...paths],
        mode: ProcessStartMode.inheritStdio);
    logCommand('pub', paths, args, verbose: context?.verbose);
    return runProcessAndEnsureExit(process);
  }
}
