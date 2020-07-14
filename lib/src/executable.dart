import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/utils/config_visitor.dart';
import 'package:dart_dev/src/utils/parse_flag_from_args.dart';
import 'package:glob/glob.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'dart_dev_runner.dart';
import 'utils/assert_dir_is_dart_package.dart';
import 'utils/dart_tool_cache.dart';
import 'utils/ensure_process_exit.dart';
import 'utils/logging.dart';
import 'utils/orf_tool.dart';

typedef _ConfigGetter = Map<String, DevTool> Function();

final _runScriptPath = p.join(cacheDirPath, 'run.dart');

final _runScript = File(_runScriptPath);

const _configPath = 'tool/dart_dev/config.dart';

const _oldDevDartPath = 'tool/dev.dart';

final _relativeDevDartPath = p.relative(
  p.absolute(_configPath),
  from: p.absolute(p.dirname(_runScriptPath)),
);

Future<void> run(List<String> args) async {
  attachLoggerToStdio(args);
  final configExists = File(_configPath).existsSync();
  final oldDevDartExists = File(_oldDevDartPath).existsSync();

  if (!configExists) {
    log.fine('No custom `tool/dart_dev/config.dart` file found; '
        'using default config.');
  }
  if (oldDevDartExists) {
    log.warning(yellow.wrap(
        'dart_dev v3 now expects configuration to be at `$_configPath`,\n'
        'but `$_oldDevDartPath` still exists. View the guide to see how to upgrade:\n'
        'https://github.com/Workiva/dart_dev/blob/master/doc/v3-upgrade-guide.md'));
  }

  if (args.contains('hackFastFormat') && !oldDevDartExists) {
    await handleFastFormat(args);
    exitCode = 0;
    return;
  }

  generateRunScript();
  final process = await Process.start(
      Platform.executable, [_runScriptPath, ...args],
      mode: ProcessStartMode.inheritStdio);
  ensureProcessExit(process);
  exitCode = await process.exitCode;
}

Future<void> handleFastFormat(List<String> args) async {
  final hasCustomToolDevDart = File(_configPath).existsSync();

  assertDirIsDartPackage();

  if (hasCustomToolDevDart) {
    final configVisitor = ConfigVisitor();
    parseString(content: File(_configPath).readAsStringSync()).unit.accept(configVisitor);

    if (configVisitor.usesOverReactFormat) {
      final formatTool = OverReactFormatTool();

      if (configVisitor.lineLength != null) {
        formatTool.lineLength = configVisitor.lineLength;
      }

      final config = {
        ...coreConfig,
        'hackFastFormat': formatTool
      };

      exitCode = await DartDevRunner(config).run(args);
      return;
    }
  }

  final filteredArgs = args.where((arg) => arg != 'hackFastFormat');
  final completeArgs = filteredArgs.toList();
  completeArgs.insert(0, 'format');

  try {
    exitCode = await DartDevRunner(coreConfig).run(completeArgs);
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = ExitCode.usage.code;
  } catch (error, stack) {
    log.severe('Uncaught Exception:', error, stack);
    if (!parseFlagFromArgs(completeArgs, 'verbose', abbr: 'v')) {
      // Always print the stack trace for an uncaught exception.
      stderr.writeln(stack);
    }
    exitCode = ExitCode.unavailable.code;
  }
}

void generateRunScript() {
  if (shouldWriteRunScript) {
    logTimedSync(log, 'Generating run script', () {
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
    log.severe(error);
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
    log.severe('Uncaught Exception:', error, stack);
    if (!parseFlagFromArgs(args, 'verbose', abbr: 'v')) {
      // Always print the stack trace for an uncaught exception.
      stderr.writeln(stack);
    }
    exitCode = ExitCode.unavailable.code;
  }
}
