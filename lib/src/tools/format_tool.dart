import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../utils.dart';
import '../dart_dev_tool.dart';
import '../utils/arg_results_utils.dart';
import '../utils/assert_no_positional_args_nor_args_after_separator.dart';
import '../utils/logging.dart';
import '../utils/organize_directives/organize_directives_in_paths.dart';
import '../utils/package_is_immediate_dependency.dart';
import '../utils/process_declaration.dart';
import '../utils/run_process_and_ensure_exit.dart';

final _log = Logger('Format');

/// A dart_dev tool that runs the dart formatter on the current project.
///
/// To use this tool in your project, include it in the dart_dev config in
/// `tool/dart_dev/config.dart`:
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'format': FormatTool(),
///     };
///
/// This will make it available via the `dart_dev` command-line app like so:
///     dart run dart_dev format
///
/// This tool can be configured by modifying any of its fields:
///     // tool/dart_dev/config.dart
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'format': FormatTool()
///         ..defaultMode = FormatMode.check
///         ..exclude = [Glob('lib/src/generated/**.dart')]
///         ..formatter = Formatter.dartStyle,
///     };
///
/// It is also possible to run this tool directly in a dart script:
///     FormatTool().run();
class FormatTool extends DevTool {
  /// The default mode in which to run the formatter.
  ///
  /// This is still overridable via the command line:
  ///     ddev format -n  # dry-run
  ///     ddev format -w  # ovewrite
  FormatMode defaultMode = FormatMode.overwrite;

  /// The globs to exclude from the inputs to the dart formatter.
  ///
  /// By default, nothing is excluded.
  List<Glob> exclude;

  /// The formatter to run, one of:
  /// - `dartfmt` (provided by the SDK)
  /// - `dart run dart_style:format` (provided by the `dart_style` package)
  /// - `dart format` (added in Dart SDK 2.10.0)
  Formatter formatter = Formatter.dartfmt;

  /// The args to pass to the formatter process run by this command.
  ///
  /// Run `dartfmt -h -v` or `dart format -h -v` to see all available args.
  List<String> formatterArgs;

  /// If the formatter should also organize imports and exports.
  ///
  /// By default, this is disabled.
  bool organizeDirectives = false;

  // ---------------------------------------------------------------------------
  // DevTool Overrides
  // ---------------------------------------------------------------------------

  @override
  final ArgParser argParser = ArgParser()
    ..addSeparator('======== Formatter Mode')
    ..addFlag('overwrite',
        abbr: 'w',
        negatable: false,
        help: 'Overwrite input files with formatted output.')
    ..addFlag('dry-run',
        abbr: 'n',
        negatable: false,
        help: 'Show which files would be modified but make no changes.')
    ..addFlag('check',
        abbr: 'c',
        negatable: false,
        help: 'Check if changes need to be made and set the exit code '
            'accordingly.\nImplies "--dry-run" and "--set-exit-if-changed".')
    ..addSeparator('======== Other Options')
    ..addOption('formatter-args',
        help: 'Args to pass to the "dartfmt" or "dart format" process.\n'
            'Run "dartfmt -h -v" or "dart format -h -v" to see all available options.');

  @override
  String description = 'Format dart files in this package.';

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    context ??= DevToolExecutionContext();
    final formatExecution = buildExecution(
      context,
      configuredFormatterArgs: formatterArgs,
      defaultMode: defaultMode,
      exclude: exclude,
      formatter: formatter,
      organizeDirectives: organizeDirectives,
    );
    if (formatExecution.exitCode != null) {
      return formatExecution.exitCode;
    }
    var exitCode = await runProcessAndEnsureExit(
      formatExecution.formatProcess,
      log: _log,
    );
    if (exitCode != 0) {
      return exitCode;
    }
    if (formatExecution.directiveOrganization != null) {
      exitCode = organizeDirectivesInPaths(
        formatExecution.directiveOrganization.inputs,
        check: formatExecution.directiveOrganization.check,
        verbose: context.verbose,
      );
    }
    return exitCode;
  }

  /// Builds and returns the object that contains:
  /// - The file paths
  /// - The paths that were excluded by an exclude glob
  /// - The paths that were skipped because they are links
  /// - The hidden directories(start with a '.') that were skipped
  ///
  /// The file paths will include all .dart files in [path] (and its subdirectories),
  /// except any paths that match the expanded [exclude] globs.
  ///
  /// By default these globs are assumed to be relative to the current working
  /// directory, but that can be overridden via [root] for testing purposes.
  ///
  /// If collapseDirectories is true, directories that contain no exclusions will wind up in the [FormatterInputs],
  /// rather than each file in that tree.  You may get unexpected results if this and followLinks are both true.
  static FormatterInputs getInputs({
    List<Glob> exclude,
    bool expandCwd,
    bool followLinks,
    String root,
    bool collapseDirectories,
  }) {
    expandCwd ??= false;
    followLinks ??= false;
    collapseDirectories ??= false;

    final includedFiles = <String>{};
    final excludedFiles = <String>{};
    final skippedLinks = <String>{};
    final hiddenDirectories = <String>{};

    exclude ??= <Glob>[];

    if (exclude.isEmpty && !expandCwd) {
      return FormatterInputs({'.'});
    }

    final dir = Directory(root ?? '.');

    // Use Glob.listSync to get all directories which might include a matching file.
    var directoriesWithExcludes = Set<String>();

    if (collapseDirectories) {
      for (var g in exclude) {
        List<FileSystemEntity> matchingPaths;
        try {
          matchingPaths = g.listSync(followLinks: followLinks);
        } on FileSystemException catch (_) {
          _log.finer("Glob '$g' did not match any paths.\n");
        }
        if (matchingPaths != null) {
          for (var path in matchingPaths) {
            if (path is Directory) {
              directoriesWithExcludes.add(path.path);
            } else {
              directoriesWithExcludes.add(path.parent.path);
            }
          }
        }
      }

      // This is all the directories that contain a match within them.
      _log.finer("Directories with excludes:\n");
      for (var dir in directoriesWithExcludes) {
        _log.finer("  $dir\n");
      }
      _log.finer(
          "${directoriesWithExcludes.length} directories contain excludes\n");
    }

    String currentDirectory = p.relative(dir.path, from: dir.path);
    bool skipFilesInDirectory = false;
    for (final entry
        in dir.listSync(recursive: true, followLinks: followLinks)) {
      final relative = p.relative(entry.path, from: dir.path);
      _log.finest('== Processing relative $relative ==\n');

      if (p.isWithin(currentDirectory, relative)) {
        if (skipFilesInDirectory) {
          _log.finest('skipping child $entry\n');
          continue;
        }
      } else {
        // the file/dir in not inside, cancel skipping.
        skipFilesInDirectory = false;
      }

      if (entry is Link) {
        _log.finer('skipping link $relative\n');
        skippedLinks.add(relative);
        continue;
      }

      if (entry is File && !entry.path.endsWith('.dart')) {
        _log.finest('skipping non-dart file $relative\n');
        continue;
      }

      // If the path is in a subdirectory starting with ".", ignore it.
      final parts = p.split(relative);
      int hiddenIndex;
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].startsWith(".")) {
          hiddenIndex = i;
          break;
        }
      }

      if (hiddenIndex != null) {
        final hiddenDirectory = p.joinAll(parts.take(hiddenIndex + 1));
        hiddenDirectories.add(hiddenDirectory);
        _log.finest('skipping file $relative in hidden dir $hiddenDirectory\n');
        if (collapseDirectories) {
          currentDirectory = hiddenDirectory;
          skipFilesInDirectory = true;
        }
        continue;
      }

      if (exclude.any((glob) => glob.matches(relative))) {
        _log.finer('excluding $relative\n');
        excludedFiles.add(relative);
      } else {
        if (collapseDirectories && entry is Directory) {
          _log.finest('directory: $entry\n');
          currentDirectory = relative;
          // It seems we can rely on the order of files coming from Directory.listSync.
          // If the entry does not contain an excluded file,
          // we skip adding any of its children files or directories.
          if (directoriesWithExcludes.any(
            (directoryWithExclude) =>
                p.isWithin(entry.path, directoryWithExclude) ||
                p.equals(entry.path, directoryWithExclude),
          )) {
            _log.finer('$relative has excludes\n');
          } else {
            skipFilesInDirectory = true;
            _log.finer("$relative does not have excludes, skipping children\n");
            includedFiles.add(relative);
          }
        }

        if (entry is File && !skipFilesInDirectory) {
          _log.finest("adding $relative\n");
          includedFiles.add(relative);
        }
      }
    }

    _log.finer("excluded ${excludedFiles.length} files\n");

    return FormatterInputs(includedFiles,
        excludedFiles: excludedFiles,
        skippedLinks: skippedLinks,
        hiddenDirectories: hiddenDirectories);
  }
}

class FormatterInputs {
  FormatterInputs(this.includedFiles,
      {this.excludedFiles, this.hiddenDirectories, this.skippedLinks});

  final Set<String> excludedFiles;

  final Set<String> hiddenDirectories;

  final Set<String> includedFiles;

  final Set<String> skippedLinks;
}

/// A declarative representation of an execution of the [FormatTool].
///
/// This class allows the [FormatTool] to break its execution up into two steps:
/// 1. Validation of config/inputs and creation of this class.
/// 2. Execution of expensive or hard-to-test logic based on step 1.
///
/// As a result, nearly all of the logic in [FormatTool] can be tested via the
/// output of step 1 (an instance of this class) with very simple unit tests.
class FormatExecution {
  FormatExecution.exitEarly(this.exitCode)
      : formatProcess = null,
        directiveOrganization = null;
  FormatExecution.process(this.formatProcess, [this.directiveOrganization])
      : exitCode = null;

  /// If non-null, the execution is already complete and the [FormatTool] should
  /// exit with this code.
  ///
  /// If null, there is more work to do.
  final int exitCode;

  /// A declarative representation of the formatter process that should be run.
  ///
  /// If this process results in a non-zero exit code, [FormatTool] should return it.
  final ProcessDeclaration formatProcess;

  /// A declarative representation of the directive organization work to be done
  /// (if enabled) after running the formatter.
  final DirectiveOrganization directiveOrganization;
}

/// A declarative representation of the directive organization work.
class DirectiveOrganization {
  DirectiveOrganization(this.inputs, {this.check});

  final bool check;
  final Set<String> inputs;
}

/// Modes supported by the dart formatter.
enum FormatMode {
  // dartfmt -n --set-exit-if-changed
  check,
  // dartfmt -n
  dryRun,
  // dartfmt -w
  overwrite,
}

/// Available dart formatters.
enum Formatter {
  // The formatter provided via the Dart SDK.
  dartfmt,
  // The formatter provided via the `dart_style` package.
  dartStyle,
  // The formatter provided via the Dart 2.10 SDK
  dartFormat,
}

/// Builds and returns the full list of args for the formatter process that
/// [FormatTool] will start.
///
/// [executableArgs] will be included first and are only needed when using the
/// `dart_style:format` executable (e.g. `dart run dart_style:format`).
///
/// Next, [mode] will be mapped to the appropriate formatter arg(s), e.g. `-w`,
/// and included.
///
/// If non-null, [configuredFormatterArgs] will be included next.
///
/// If [argResults] is non-null and the `--formatter-args` option is non-null,
/// they will be included next.
///
/// Finally, if [verbose] is true and the verbose flag (`-v`) is not already
/// included, it will be added.
Iterable<String> buildArgs(
  Iterable<String> executableArgs,
  FormatMode mode, {
  ArgResults argResults,
  List<String> configuredFormatterArgs,
}) {
  final args = <String>[
    ...executableArgs,

    // Combine all args that should be passed through to the dartfmt in this
    // order:
    // 1. Mode flag(s), if configured
    if (mode == FormatMode.check) ...[
      '-n',
      '--set-exit-if-changed',
    ],
    if (mode == FormatMode.overwrite) '-w',
    if (mode == FormatMode.dryRun) '-n',

    // 2. Statically configured args from [FormatTool.formatterArgs]
    ...?configuredFormatterArgs,
    // 3. Args passed to --formatter-args
    ...?splitSingleOptionValue(argResults, 'formatter-args'),
  ];
  return args;
}

/// Builds and returns the full list of args for the formatter process that
/// [FormatTool] will start.
///
/// [executableArgs] will be included first and will include the
/// `format` executable (e.g. `dart format`).
///
/// Next, [mode] will be mapped to the appropriate formatter arg(s), e.g. `-o`,
/// and included.
///
/// If non-null, [configuredFormatterArgs] will be included next.
///
/// If [argResults] is non-null and the `--formatter-args` option is non-null,
/// they will be included next.
///
/// Finally, if [verbose] is true and the verbose flag (`-v`) is not already
/// included, it will be added.
Iterable<String> buildArgsForDartFormat(
    Iterable<String> executableArgs, FormatMode mode,
    {ArgResults argResults, List<String> configuredFormatterArgs}) {
  final args = <String>[
    ...executableArgs,

    // Combine all args that should be passed through to the dart format in this
    // order:
    // 1. Mode flag(s), if configured
    if (mode == FormatMode.check) ...['-o', 'none', '--set-exit-if-changed'],
    if (mode == FormatMode.dryRun) ...['-o', 'none'],

    // 2. Statically configured args from [FormatTool.formatterArgs]
    ...?configuredFormatterArgs,
    // 3. Args passed to --formatter-args
    ...?splitSingleOptionValue(argResults, 'formatter-args'),
  ];
  return args;
}

/// Returns a declarative representation of a formatter process to run based on
/// the given parameters.
///
/// These parameters will be populated from [FormatTool] when it is executed
/// (either directly or via a command-line app).
///
/// [context] is the execution context that would be provided by [FormatTool]
/// when converted to a [DevToolCommand]. For tests, this can be manually
/// created to imitate the various CLI inputs.
///
/// [configuredFormatterArgs] will be populated from [FormatTool.formatterArgs].
///
/// [defaultMode] will be populated from [FormatTool.defaultMode].
///
/// [exclude] will be populated from [FormatTool.exclude].
///
/// [formatter] will be populated from [FormatTool.formatter].
///
/// [include] will be populated from [FormatTool.include].
///
/// [organizeDirectives] will be populated from [FormatTool.organizeDirectives].
///
/// If non-null, [path] will override the current working directory for any
/// operations that require it. This is intended for use by tests.
///
/// The [FormatTool] can be tested almost completely via this function by
/// enumerating all of the possible parameter variations and making assertions
/// on the declarative output.
FormatExecution buildExecution(
  DevToolExecutionContext context, {
  List<String> configuredFormatterArgs,
  FormatMode defaultMode,
  List<Glob> exclude,
  Formatter formatter,
  bool organizeDirectives = false,
  String path,
}) {
  FormatMode mode;

  final useRestForInputs = (context?.argResults?.rest?.isNotEmpty ?? false) &&
      context.commandName == 'hackFastFormat';

  if (context.argResults != null) {
    assertNoPositionalArgsNorArgsAfterSeparator(
        context.argResults, context.usageException,
        allowRest: useRestForInputs,
        commandName: context.commandName,
        usageFooter:
            'Arguments can be passed to the "dartfmt" or "dart format" process via the '
            '--formatter-args option.');
    mode = validateAndParseMode(context.argResults, context.usageException);
  }
  mode ??= defaultMode;

  if (formatter == Formatter.dartStyle &&
      !packageIsImmediateDependency('dart_style', path: path)) {
    _log.severe(red.wrap('Cannot run "dart_style:format".\n') +
        yellow.wrap('You must either have a dependency on "dart_style" in '
            'pubspec.yaml or configure the format tool to use "dartfmt" '
            'instead.\n'
            'Either add "dart_style" to your pubspec.yaml or configure the '
            'format tool to use "dartfmt" instead.'));
    return FormatExecution.exitEarly(ExitCode.config.code);
  }

  if (context.commandName == 'hackFastFormat' && !useRestForInputs) {
    context.usageException('"hackFastFormat" must specify targets to format.\n'
        'hackFastFormat should only be used to format specific files. '
        'Running the command over an entire project may format files that '
        'would be excluded using the standard "format" command.');
  }

  final inputs = useRestForInputs
      ? FormatterInputs({...context.argResults.rest})
      : FormatTool.getInputs(
          exclude: exclude,
          root: path,
          collapseDirectories: true,
        );

  if (inputs.includedFiles.isEmpty) {
    _log.severe('The formatter cannot run because no inputs could be found '
        'with the configured includes and excludes.\n'
        'Please modify the excludes and/or includes in "tool/dart_dev/config.dart".');
    return FormatExecution.exitEarly(ExitCode.config.code);
  }

  if (inputs.excludedFiles?.isNotEmpty ?? false) {
    _log.fine('Excluding these paths from formatting:\n  '
        '${inputs.excludedFiles.join('\n  ')}');
  }

  if (inputs.skippedLinks?.isNotEmpty ?? false) {
    _log.fine('Excluding these links from formatting:\n  '
        '${inputs.skippedLinks.join('\n  ')}');
  }

  if (inputs.hiddenDirectories?.isNotEmpty ?? false) {
    _log.fine('Excluding these hidden directories from formatting:\n  '
        '${inputs.hiddenDirectories.join('\n  ')}');
  }

  final dartFormatter = buildFormatProcess(formatter);
  Iterable<String> args;
  if (formatter == Formatter.dartFormat) {
    args = buildArgsForDartFormat(dartFormatter.args, mode,
        argResults: context.argResults,
        configuredFormatterArgs: configuredFormatterArgs);
  } else {
    args = buildArgs(dartFormatter.args, mode,
        argResults: context.argResults,
        configuredFormatterArgs: configuredFormatterArgs);
  }
  logCommand(dartFormatter.executable, inputs.includedFiles, args,
      verbose: context.verbose);

  final formatProcess = ProcessDeclaration(
    dartFormatter.executable,
    [...args, ...inputs.includedFiles],
    mode: ProcessStartMode.inheritStdio,
  );
  DirectiveOrganization directiveOrganization;
  if (organizeDirectives) {
    directiveOrganization = DirectiveOrganization(
      inputs.includedFiles,
      check: mode == FormatMode.check,
    );
  }
  return FormatExecution.process(
    formatProcess,
    directiveOrganization,
  );
}

/// Returns a representation of the process that will be run by [FormatTool]
/// based on the given [formatter].
///
/// - [Formatter.dartfmt] -> `dartfmt`
/// - [Formatter.dartFormat] -> `dart format`
/// - [Formatter.dartStyle] -> `dart run dart_style:format`
ProcessDeclaration buildFormatProcess([Formatter formatter]) {
  switch (formatter) {
    case Formatter.dartStyle:
      return ProcessDeclaration('dart', ['run', 'dart_style:format']);
    case Formatter.dartFormat:
      return ProcessDeclaration('dart', ['format']);
    case Formatter.dartfmt:
    default:
      return ProcessDeclaration('dartfmt', []);
  }
}

/// Logs the dart formatter command that will be run by [FormatTool] so that
/// consumers can run it directly for debugging purposes.
///
/// Unless [verbose] is true, the list of inputs will be abbreviated to avoid an
/// unnecessarily long log.
void logCommand(
    String executable, Iterable<String> inputs, Iterable<String> args,
    {bool verbose}) {
  verbose ??= false;
  final exeAndArgs = '$executable ${args.join(' ')}'.trim();
  if (inputs.length <= 5 || verbose) {
    logSubprocessHeader(_log, '$exeAndArgs ${inputs.join(' ')}');
  } else {
    logSubprocessHeader(_log, '$exeAndArgs <${inputs.length} paths>');
  }
}

/// Attempts to parse and return a single [FormatMode] from [argResults] by
/// checking for the supported mode flags (`--check`, `--dry-run`, and
/// `--overwrite`).
///
/// If more than one of these mode flags are used together, [usageException]
/// will be called with a message explaining that only one mode can be used.
///
/// If none of the mode flags were enabled, this returns `null`.
FormatMode validateAndParseMode(
    ArgResults argResults, void Function(String message) usageException) {
  final check = argResults['check'] ?? false;
  final dryRun = argResults['dry-run'] ?? false;
  final overwrite = argResults['overwrite'] ?? false;

  if (check && dryRun && overwrite) {
    usageException(
        'Cannot use --check and --dry-run and --overwrite at the same time.');
  }
  if (check && dryRun) {
    usageException('Cannot use --check and --dry-run at the same time.');
  }
  if (check && overwrite) {
    usageException('Cannot use --check and --overwrite at the same time.');
  }
  if (dryRun && overwrite) {
    usageException('Cannot use --dry-run and --overwrite at the same time.');
  }

  if (check) {
    return FormatMode.check;
  }
  if (dryRun) {
    return FormatMode.dryRun;
  }
  if (overwrite) {
    return FormatMode.overwrite;
  }
  return null;
}
