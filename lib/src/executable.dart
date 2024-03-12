import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/utils/parse_imports.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

import 'dart_dev_runner.dart';
import 'tools/over_react_format_tool.dart';
import 'utils/assert_dir_is_dart_package.dart';
import 'utils/cached_pubspec.dart';
import 'utils/dart_dev_paths.dart';
import 'utils/dart_tool_cache.dart';
import 'utils/ensure_process_exit.dart';
import 'utils/format_tool_builder.dart';
import 'utils/get_dart_version_comment.dart';
import 'utils/logging.dart';
import 'utils/parse_flag_from_args.dart';

typedef _ConfigGetter = Map<String, DevTool> Function();

final _paths = DartDevPaths();

Future<void> run(List<String> args) async {
  attachLoggerToStdio(args);

  final configExists = File(_paths.config).existsSync();
  final oldDevDartExists = File(_paths.legacyConfig).existsSync();

  if (!configExists) {
    log.fine('No custom `${_paths.config}` file found; '
        'using default config.');
  }
  if (oldDevDartExists) {
    log.warning(yellow.wrap(
        'dart_dev v3 now expects configuration to be at `${_paths.config}`,\n'
        'but `${_paths.legacyConfig}` still exists. View the guide to see how to upgrade:\n'
        'https://github.com/Workiva/dart_dev/blob/master/doc/v3-upgrade-guide.md'));
  }

  if (args.contains('hackFastFormat') && !oldDevDartExists) {
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

  DevTool? formatTool;
  final configFile = File(_paths.config);
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

void _deleteRunExecutableAndDigest() =>
    [_paths.runExecutable, _paths.runExecutableDigest].forEach((p) {
      final f = File(p);
      if (f.existsSync()) f.deleteSync();
    });

/// Return null iff it is not possible to account for all
/// recompilation-necessitating factors in the digest.
String? _computeRunScriptDigest() {
  final currentPackageName =
      Pubspec.parse(File('pubspec.yaml').readAsStringSync()).name;
  final configFile = File(_paths.config);
  var configHasRelativeImports = false;
  if (configFile.existsSync()) {
    final configImports = parseImports(configFile.readAsStringSync());
    configHasRelativeImports = configImports.any((i) => !i.contains(':'));
    final configHasSamePackageImports =
        configImports.any((i) => i.startsWith('package:$currentPackageName'));

    if (configHasSamePackageImports) {
      log.fine(
          'Skipping compilation because ${_paths.config} imports from its own package.');

      // If the config imports from its own source files, we don't have a way of
      // efficiently tracking changes that would require recompilation of this
      // executable, so we skip the compilation altogether.
      _deleteRunExecutableAndDigest();
      return null;
    }
  }

  // Include the packageConfig in the digest so that when dependencies change,
  // we recompile.
  final packageConfig = File(_paths.packageConfig);

  final digest = md5.convert([
    if (packageConfig.existsSync()) ...packageConfig.readAsBytesSync(),
    if (configFile.existsSync()) ...configFile.readAsBytesSync(),
    if (configHasRelativeImports)
      for (final file in Glob('tool/**.dart', recursive: true)
          .listSync()
          .whereType<File>()
          .where((f) => p.canonicalize(f.path) != p.canonicalize(_paths.config))
          .sortedBy((f) => f.path))
        ...file.readAsBytesSync(),
  ]);
  return base64.encode(digest.bytes);
}

List<String> generateRunScript() {
  // Generate the run script if it doesn't yet exist or regenerate it if the
  // existing script is outdated.
  final runScriptContents = buildDartDevRunScriptContents();
  final runScript = File(_paths.runScript);
  final runExecutable = File(_paths.runExecutable);
  final runExecutableDigest = File(_paths.runExecutableDigest);
  if (!runScript.existsSync() ||
      runScript.readAsStringSync() != runScriptContents) {
    logTimedSync(log, 'Generating run script', () {
      createCacheDir();
      runScript.writeAsStringSync(runScriptContents);
    }, level: Level.INFO);
  }

  // Generate a digest of inputs to the run script. We use this to determine
  // whether we need to recompile the executable.
  String? encodedDigest;
  logTimedSync(log, 'Computing run script digest',
      () => encodedDigest = _computeRunScriptDigest(),
      level: Level.FINE);

  if (encodedDigest != null &&
      (!runExecutableDigest.existsSync() ||
          runExecutableDigest.readAsStringSync() != encodedDigest)) {
    // Digest is missing or outdated, so we (re-)compile.
    final logMessage = runExecutable.existsSync()
        ? 'Recompiling run script (digest changed)'
        : 'Compiling run script';
    logTimedSync(log, logMessage, () {
      // Delete the previous executable and digest so that if we hit a failure
      // trying to compile, we don't leave the outdated one in place.
      _deleteRunExecutableAndDigest();
      final args = [
        'compile',
        'exe',
        _paths.runScript,
        '-o',
        _paths.runExecutable
      ];
      final result = Process.runSync(Platform.executable, args);
      if (result.exitCode == 0) {
        // Compilation succeeded. Write the new digest, as well.
        runExecutableDigest.writeAsStringSync(encodedDigest!);
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

  return runExecutable.existsSync()
      // Using the absolute path is necessary for Windows to find the executable.
      ? [runExecutable.absolute.path]
      : [Platform.executable, 'run', _paths.runScript];
}

String buildDartDevRunScriptContents() {
  final hasCustomToolDevDart = File(_paths.config).existsSync();
  // If the config has a dart version comment (e.g., if it opts out of null safety),
  // copy it over to the entrypoint so the program is run in that language version.
  var dartVersionComment = hasCustomToolDevDart
      ? getDartVersionComment(File(_paths.config).readAsStringSync())
      : null;

  return '''
${dartVersionComment ?? ''}
import 'dart:io';

import 'package:dart_dev/src/core_config.dart';
import 'package:dart_dev/src/executable.dart' as executable;
${hasCustomToolDevDart ? "import '${_paths.configFromRunScriptForDart}' as custom_dev;" : ""}

void main(List<String> args) async {
  await executable.runWithConfig(args,
    () => ${hasCustomToolDevDart ? 'custom_dev.config' : 'coreConfig'});
}
''';
}

Future<void> runWithConfig(
    // ignore: library_private_types_in_public_api
    List<String> args,
    _ConfigGetter configGetter) async {
  attachLoggerToStdio(args);

  try {
    assertDirIsDartPackage();
  } on DirectoryIsNotPubPackage catch (error) {
    log.severe(error);
    exitCode = ExitCode.usage.code;
    return;
  }

  Map<String, DevTool> config;
  try {
    config = configGetter();
  } catch (error) {
    stderr
      ..writeln('Invalid "${_paths.config}" in ${p.absolute(p.current)}')
      ..writeln()
      ..writeln('It should provide a `Map<String, DevTool> config;` getter,'
          ' but it either does not exist or threw unexpectedly:')
      ..writeln('  $error')
      ..writeln()
      ..writeln('For more info: https://github.com/Workiva/dart_dev');
    exitCode = ExitCode.config.code;
    return;
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
DevTool chooseDefaultFormatTool({String? path}) {
  final pubspec = cachedPubspec(path: path);
  const orf = 'over_react_format';
  final hasOverReactFormat = pubspec.dependencies.containsKey(orf) ||
      pubspec.devDependencies.containsKey(orf) ||
      pubspec.dependencyOverrides.containsKey(orf);

  return hasOverReactFormat
      ? OverReactFormatTool()
      : (FormatTool()..formatter = Formatter.dartStyle);
}
