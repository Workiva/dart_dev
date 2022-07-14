import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:args/command_runner.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/tools/import_cleaner_tool.dart';
import 'package:dart_dev/src/utils/format_tool_builder.dart';
import 'package:dart_dev/src/utils/get_dart_version_comment.dart';
import 'package:dart_dev/src/utils/parse_flag_from_args.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'dart_dev_runner.dart';
import 'tools/over_react_format_tool.dart';
import 'utils/assert_dir_is_dart_package.dart';
import 'utils/dart_tool_cache.dart';
import 'utils/ensure_process_exit.dart';
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

    return;
  }

  if (args.contains('sort_imports')) {
    await handleSortImports(args);
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
  assertDirIsDartPackage();

  DevTool formatTool;
  final configFile = File(_configPath);
  if (configFile.existsSync()) {
    final toolBuilder = FormatToolBuilder();
    parseString(content: configFile.readAsStringSync())
        .unit
        .accept(toolBuilder);
    formatTool = toolBuilder
        .formatDevTool; // could be null if no custom `format` entry found

    if (formatTool == null && toolBuilder.failedToDetectAKnownFormatter) {
      exitCode = ExitCode.config.code;
      log.severe('Failed to reconstruct the format tool\'s configuration.\n\n'
          'This is likely because dart_dev expects either the FormatTool class or the\n'
          'OverReactFormatTool class.');
      return;
    }
  }

  formatTool ??= chooseDefaultFormatTool();

  try {
    exitCode = await DartDevRunner({'hackFastFormat': formatTool}).run(args);
  } catch (error, stack) {
    log.severe('Uncaught Exception:', error, stack);
    if (!parseFlagFromArgs(args, 'verbose', abbr: 'v')) {
      // Always print the stack trace for an uncaught exception.
      stderr.writeln(stack);
    }
    exitCode = ExitCode.unavailable.code;
  }
}

Future<void> handleSortImports(List<String> args) async {
  assertDirIsDartPackage();

  try {
    exitCode =
        await DartDevRunner({'sort_imports': ImportCleanerTool()}).run(args);
  } catch (error, stack) {
    log.severe('Uncaught Exception:', error, stack);
    if (!parseFlagFromArgs(args, 'verbose', abbr: 'v')) {
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

/// Whether dart_dev itself has opted into null-safety.
const _isDartDevNullSafe = false;

String buildDartDevRunScriptContents() {
  final hasCustomToolDevDart = File(_configPath).existsSync();
  // If the config has a dart version comment (e.g., if it opts out of null safety),
  // copy it over to the entrypoint so the program is run in that language version.
  var dartVersionComment = hasCustomToolDevDart
      ? getDartVersionComment(File(_configPath).readAsStringSync())
      : null;
  // If dart_dev itself is not null-safe, opt the entrypoint out of null-safety
  // so the entrypoint doesn't fail to run in packages that have opted into null-safety.
  if (!_isDartDevNullSafe && dartVersionComment == null) {
    dartVersionComment = '// @dart=2.9';
  }

  return '''
${dartVersionComment ?? ''}
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

/// Returns [OverReactFormatTool] if `over_react_format` is a direct dependency,
/// and the default [FormatTool] otherwise.
DevTool chooseDefaultFormatTool({String path}) {
  final pubspec = cachedPubspec(path: path);
  const orf = 'over_react_format';
  final hasOverReactFormat = pubspec.dependencies.containsKey(orf) ||
      pubspec.devDependencies.containsKey(orf) ||
      pubspec.dependencyOverrides.containsKey(orf);

  return hasOverReactFormat
      ? OverReactFormatTool()
      : (FormatTool()..formatter = Formatter.dartStyle);
}
