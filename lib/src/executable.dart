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
import 'utils/dart_tool_cache.dart';
import 'utils/ensure_process_exit.dart';
import 'utils/logging.dart';

typedef _ConfigGetter = Map<String, DevTool> Function();

final _runScriptPath = p.join(cacheDirPath, 'run.dart');

final _runScript = File(_runScriptPath);

const _devDartPath = 'tool/dart_dev/config.dart';

final _relativeDevDartPath = p.relative(
  p.absolute(_devDartPath),
  from: p.absolute(p.dirname(_runScriptPath)),
);

final _log = Logger('DartDev');

Future<void> run(List<String> args) async {
  attachLoggerToStdio(args);

  if (!File(_devDartPath).existsSync()) {
    _log.fine('No custom `tool/dart_dev/config.dart` file found; '
        'using default config.');
  }

  generateRunScript();
  final process = await Process.start(
      Platform.executable, [_runScriptPath, ...args],
      mode: ProcessStartMode.inheritStdio);
  ensureProcessExit(process);
  exitCode = await process.exitCode;
}

void generateRunScript() {
  if (shouldWriteRunScript) {
    logTimedSync(_log, 'Generating run script', () {
      createCacheDir();
      _runScript.writeAsStringSync(buildDartDevRunScriptContents());
    }, level: Level.INFO);
  }
}

bool get shouldWriteRunScript =>
    !_runScript.existsSync() ||
    _runScript.readAsStringSync() != buildDartDevRunScriptContents();

String buildDartDevRunScriptContents() {
  final hasCustomToolDevDart = File(_devDartPath).existsSync();
  return '''
import 'dart:io';

import 'package:dart_dev/src/core_config.dart';
import 'package:dart_dev/src/executable.dart' as executable;
${hasCustomToolDevDart ? "import '$_relativeDevDartPath' as custom_dev;" : ""}

void main(List<String> args) async {
  await executable.runWithConfig(args,
    () => ${hasCustomToolDevDart ? 'custom_dev.config' : 'coreConfig'});
}
''';
}

Future<void> runWithConfig(
    List<String> args, _ConfigGetter configGetter) async {
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
      ..writeln(
          'Invalid "tool/dart_dev/config.dart" in ${p.absolute(p.current)}')
      ..writeln()
      ..writeln('It should provide a `Map<String, DevTool> config;` getter,'
          ' but it either does not exist or threw unexpectedly:')
      ..writeln('  $error')
      ..writeln()
      ..writeln('For more info: http://github.com/Workiva/dart_dev#TODO');
    return ExitCode.config.code;
  }

  try {
    exitCode = await DartDevRunner(config).run(args);
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = ExitCode.usage.code;
  } catch (error, stack) {
    _log.severe('Uncaught Exception:', error, stack);
    if (!parseFlagFromArgs(args, 'verbose', abbr: 'v')) {
      // Always print the stack trace for an uncaught exception.
      stderr.writeln(stack);
    }
    exitCode = ExitCode.unavailable.code;
  }
}
