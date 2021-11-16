import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/utils/format_tool_builder.dart';
import 'package:dart_dev/src/utils/parse_flag_from_args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

import '../utils.dart';
import 'dart_dev_runner.dart';
import 'tools/over_react_format_tool.dart';
import 'utils/assert_dir_is_dart_package.dart';
import 'utils/dart_tool_cache.dart';
import 'utils/ensure_process_exit.dart';
import 'utils/logging.dart';

typedef _ConfigGetter = Map<String, DevTool> Function();

const _packageConfigPath = '.dart_tool/package_config.json';
final _packageConfig = File(_packageConfigPath);
final _runExecutablePath = p.join(cacheDirPath, 'run');
final _runExecutable = File(_runExecutablePath);
final _runExecutableDigestPath = p.setExtension(_runExecutablePath, '.digest');
final _runExecutableDigest = File(_runExecutableDigestPath);
final _runScriptPath = p.join(cacheDirPath, 'run.dart');
final _runScript = File(_runScriptPath);
const _configPath = 'tool/dart_dev/config.dart';
final _config = File(_configPath);
const _oldDevDartPath = 'tool/dev.dart';
final _oldDevDart = File(_oldDevDartPath);

final _relativeDevDartPath = p.relative(
  p.absolute(_configPath),
  from: p.absolute(p.dirname(_runScriptPath)),
);

Future<void> run(List<String> args) async {
  attachLoggerToStdio(args);

  if (!_config.existsSync()) {
    log.fine('No custom `tool/dart_dev/config.dart` file found; '
        'using default config.');
  }
  if (_oldDevDart.existsSync()) {
    log.warning(yellow.wrap(
        'dart_dev v3 now expects configuration to be at `$_configPath`,\n'
        'but `$_oldDevDartPath` still exists. View the guide to see how to upgrade:\n'
        'https://github.com/Workiva/dart_dev/blob/master/doc/v3-upgrade-guide.md'));
  }

  if (args.contains('hackFastFormat') && !_oldDevDart.existsSync()) {
    await handleFastFormat(args);
    return;
  }

  final processArgs = generateRunScript();
  final process = await Process.start(
      processArgs.first,
      [
        if (processArgs.length > 1) ...processArgs.sublist(1),
        ...args,
      ],
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

List<String> generateRunScript() {
  // Generate the run script if it doesn't yet exist or regenerate it if the
  // existing script is outdated.
  final runScriptContents = buildDartDevRunScriptContents();
  if (!_runScript.existsSync() ||
      _runScript.readAsStringSync() != runScriptContents) {
    logTimedSync(log, 'Generating run script', () {
      createCacheDir();
      _runScript.writeAsStringSync(buildDartDevRunScriptContents());
    }, level: Level.INFO);
  }

  // Generate a digest of inputs to the run script. We use this to determine
  // whether we need to recompile the executable.
  String encodedDigest;
  logTimedSync(log, 'Computing run script digest', () {
    var configHasRelativeImports = false;
    var configHasSamePackageImports = false;
    if (_config.existsSync()) {
      final contents = _config.readAsStringSync();
      configHasRelativeImports =
          RegExp(r'''^import ['"][^:]+''').hasMatch(contents);
      final currentPackageName =
          Pubspec.parse(File('pubspec.yaml').readAsStringSync()).name;
      configHasSamePackageImports =
          RegExp('''import ['"]package:$currentPackageName''')
              .hasMatch(contents);
    }

    if (configHasSamePackageImports) {
      log.fine(
          'Skipping compilation because $_configPath imports from its own package.');
      // If the config imports from its own source files, we don't have a way of
      // efficiently tracking changes that would require recompilation of this
      // executable, so we skip the compilation altogether.
      if (_runExecutable.existsSync()) {
        _runExecutable.deleteSync();
      }
      if (_runExecutableDigest.existsSync()) {
        _runExecutableDigest.deleteSync();
      }
      return;
    }

    final digest = md5.convert([
      ..._packageConfig.readAsBytesSync(),
      if (_config.existsSync()) ..._config.readAsBytesSync(),
      if (configHasRelativeImports)
        for (final file in Glob('tool/**.dart', recursive: true)
            .listSync()
            .whereType<File>()
            .where((f) => f.path != _configPath))
          ...file.readAsBytesSync(),
    ]);
    encodedDigest = base64.encode(digest.bytes);
  }, level: Level.FINE);

  if (encodedDigest != null &&
      (!_runExecutableDigest.existsSync() ||
          _runExecutableDigest.readAsStringSync() != encodedDigest)) {
    // Digest either didn't exist or is outdated, so we (re-)compile.
    logTimedSync(log, 'Compiling run script', () {
      // Delete the previous exectuable and digest so that if we hit a failure
      // trying to compile, we don't leave the outdated one in place.
      if (_runExecutable.existsSync()) {
        _runExecutable.deleteSync();
      }
      if (_runExecutableDigest.existsSync()) {
        _runExecutableDigest.deleteSync();
      }

      final args = ['compile', 'exe', _runScriptPath, '-o', _runExecutablePath];
      final result = Process.runSync(Platform.executable, args);
      if (result.exitCode == 0) {
        // Compilation succeeded. Write the new digest, as well.
        _runExecutableDigest.writeAsStringSync(encodedDigest);
      } else {
        // Compilation failed. Dump some logs for debugging, but note to the
        // user that dart_dev should still work.
        log.warning(
            'Could not compile run script; dart_dev will continue without precompilation.');
        log.fine('CMD: ${Platform.executable} ${args.join(" ")}');
        log.fine('STDOUT:\n${result.stdout}');
        log.fine('STDERR:\n${result.stderr}');
      }
    });
  }

  if (_runExecutable.existsSync()) {
    return [_runExecutablePath];
  } else {
    return [Platform.executable, 'run', _runScriptPath];
  }
}

String buildDartDevRunScriptContents() {
  final hasCustomToolDevDart = _config.existsSync();
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
