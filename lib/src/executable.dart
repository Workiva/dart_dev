import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/utils/parse_flag_from_args.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'dart_dev_runner.dart';
import 'utils/assert_dir_is_dart_package.dart';
import 'utils/dart_tool_cache.dart';

//import 'utils/ensure_process_exit.dart';
import 'utils/logging.dart';

typedef _ConfigGetter = Map<String, DevTool> Function();

final _runScriptPath = p.join(cacheDirPath, 'run.dart');

final _runScript = File(_runScriptPath);

const _configPath = 'tool/dart_dev/config.dart';

const _oldDevDartPath = 'tool/dev.dart';

final _relativeDevDartPath = p.relative(
  p.absolute(_configPath),
  from: p.absolute(p.dirname(_runScriptPath)),
);

final _log = Logger('DartDev');

Future<void> run(List<String> args) async {
  attachLoggerToStdio(args);

  final configExists = File(_configPath).existsSync();
  final oldDevDartExists = File(_oldDevDartPath).existsSync();

  if (!configExists) {
    _log.fine('No custom `tool/dart_dev/config.dart` file found; '
        'using default config.');
  }
  if (oldDevDartExists) {
    _log.warning(yellow.wrap(
        'dart_dev v3 now expects configuration to be at `$_configPath`,\n'
        'but `$_oldDevDartPath` still exists. View the guide to see how to upgrade:\n'
        'https://github.com/Workiva/dart_dev/blob/master/doc/v3-upgrade-guide.md'));
  }

  generateRunScript();

  await executeRunScriptInIsolate(args);
//  final process = await Process.start(
//      Platform.executable, [_runScriptPath, ...args],
//      mode: ProcessStartMode.inheritStdio);
//  ensureProcessExit(process);
//  exitCode = await process.exitCode;
}

Future<void> executeRunScriptInIsolate(List<String> args) async {
  _log.fine('Spawning isolate');

  // These will allow the isolate to send messages back.
  final onExitPort = ReceivePort();
  final onErrorPort = ReceivePort();

  onErrorPort.listen((message) {
    // If we hit an uncaught error, exitCode may not have been set.
    // Set it here.
    if (exitCode == 0) {
      exitCode = 1;
    }

    // The message has a specific format as indicated by the
    // `Isolate.addErrorListener` doc comment.
    final messageParts = message as List<dynamic>;
    final errorString = messageParts[0] as String;
    final stackTrace = messageParts[1] == null
        ? null
        : StackTrace.fromString(messageParts[1] as String);
    _log.severe('Uncaught error from runner isolate', errorString, stackTrace);
  });

  await Isolate.spawnUri(
    Uri.file(_runScript.absolute.path),
    args,
    null,
    onExit: onExitPort.sendPort,
    onError: onErrorPort.sendPort,
    errorsAreFatal: true,
  );

  // When the isolate exits, it sends a single message to this port.
  // Wait for it.
  //
  // The value of this Future will always be null.
  //
  // Since exitCode is global to the VM, if the isolate sets it, it gets
  // set here as well.
  //
  // So, since executable.runWithConfig always sets exitCode, we don't have to
  // handle worry about it!
  await onExitPort.first;

  // Close the error port so that it doesn't keep the process alive
  // waiting for more errors.
  onErrorPort.close();
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
  final hasCustomToolDevDart = File(_configPath).existsSync();
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
