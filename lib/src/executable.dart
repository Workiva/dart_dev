import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/utils/parse_flag_from_args.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'dart_dev_runner.dart';
import 'utils/assert_dir_is_dart_package.dart';
import 'utils/custom_entrypoint.dart';
import 'utils/logging.dart';

typedef _ConfigGetter = Map<String, DevTool> Function();

const _customDevDartPath = 'tool/dev.dart';

final _log = Logger('DartDev');

Future<int> run(List<String> args) async {
  attachLoggerToStdio(args);

  if (!File(_customDevDartPath).existsSync()) {
    final toolDir = p.join(p.absolute(p.current), 'tool');
    stderr
      ..writeln('Could not find a file named "dev.dart" in "$toolDir".')
      ..writeln('More info: https://github.com/Workiva/dart_dev#TODO');
    return ExitCode.config.code;
  }
  return runViaCustomEntrypoint(args);
}

Future<int> runWithConfig(List<String> args, _ConfigGetter configGetter) async {
  attachLoggerToStdio(args);

  try {
    assertDirIsDartPackage();
  } on DirectoryIsNotPubPackage catch (error) {
    _log.severe(error);
    return ExitCode.usage.code;
  }

  Map<String, DevTool> config;
  try {
    config = configGetter();
  } catch (error) {
    stderr
      ..writeln('Invalid "tool/dev.dart" in ${p.absolute(p.current)}')
      ..writeln()
      ..writeln('It should provide a `Map<String, DevTool> config;` getter,'
          ' but it either does not exist or threw unexpectedly:')
      ..writeln('  $error')
      ..writeln()
      ..writeln('For more info: http://github.com/Workiva/dart_dev#TODO');
    return ExitCode.config.code;
  }

  try {
    exit(await DartDevRunner(config).run(args));
  } on UsageException catch (error) {
    stderr.writeln(error);
    return ExitCode.usage.code;
  } catch (error, stack) {
    _log.severe('Uncaught Exception:', error, stack);
    if (!parseFlagFromArgs(args, 'verbose', abbr: 'v')) {
      // Always print the stack trace for an uncaught exception.
      stderr.writeln(stack);
    }
    return ExitCode.unavailable.code;
  }

  return ExitCode.success.code;
}
