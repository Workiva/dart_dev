import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_dev/src/utils/verbose_enabled.dart';
import 'package:glob/glob.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';

import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:dart_dev/src/utils/has_immediate_dependency.dart';
import 'package:dart_dev/src/utils/has_any_positional_args_before_separator.dart';
import 'package:dart_dev/src/utils/parse_flag_from_args.dart';

final _log = Logger('Format');

class FormatTool implements DartDevTool {
  @override
  final FormatCommand command;

  FormatTool(FormatConfig config) : command = FormatCommand(config);
}

class FormatCommand extends Command<int> {
  final FormatConfig config;

  FormatCommand([FormatConfig config]) : config = config ?? FormatConfig();

  @override
  String get name => config.commandName ?? 'format';

  @override
  String get description => 'Format dart files in this package.';

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[dart_dev arguments]')} '
      '[-- [formatter arguments]]';

  @override
  String get usageFooter => '\n'
      'Run "${_fmtExecutable} -h" to see the available formatter arguments.\n'
      'You can use any of them with "dart_dev $name" by passing them after a '
      '"--" separator.';

  String get _fmtExecutable => config.formatter == Formatter.dartStyle
      ? 'pub run dart_style:format'
      : 'dartfmt';

  @override
  Future<int> run() async {
    if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
      usageException('This "$name" command does not support positional args '
          'before the `--` separator.\n'
          'Args for the dart formatter should be passed in after a `--` '
          'separator.');
    }

    final dryRun = parseFlagFromArgs(argResults.rest, 'dry-run', abbr: 'n');
    final overwrite =
        parseFlagFromArgs(argResults.rest, 'overwrite', abbr: 'w');
    final noModeSelected = !dryRun && !overwrite;

    String executable;
    List<String> executableArgs;
    switch (config.formatter) {
      case Formatter.dartStyle:
        if (!hasImmediateDependency('dart_style')) {
          _log.severe('Cannot run the "dart_style:format" executable because '
              'the "dart_style" package is not an immediate dependency.\n'
              'Either add "dart_style" to your pubspec.yaml or configure the '
              'format tool to use "dartfmt" instead.');
          return ExitCode.config.code;
        }
        executable = 'pub';
        executableArgs = ['run', 'dart_style:format'];
        break;

      case Formatter.dartfmt:
      default:
        executable = 'dartfmt';
        executableArgs = [];
    }

    // Build the list of inputs (includes minus excludes).
    final excludeGlobs = config.exclude ?? [];
    final includeGlobs =
        config.include ?? [excludeGlobs.isEmpty ? Glob('.') : Glob('**.dart')];
    final include = {
      for (final glob in includeGlobs)
        ...glob
            .listSync()
            .where((entity) => entity is File || entity is Directory)
            .map((file) => file.path),
      // .where((path) => !exclude.any((glob) => glob.matches(path))),
    };
    final exclude = {
      for (final glob in excludeGlobs)
        ...glob
            .listSync()
            .where((entity) => entity is File || entity is Directory)
            .map((file) => file.path),
    };
    final inputs = include.difference(exclude);
    if (inputs.isEmpty) {
      inputs.add('.');
    }

    _log.fine('Excluding these paths from formatting:\n\t'
        '${include.intersection(exclude).join('\n\t')}');

    final args = [
      ...executableArgs,

      // Pass in a default mode if one was not selected.
      if (noModeSelected && config.defaultMode == FormatMode.dryRun)
        '-n',
      if (noModeSelected && config.defaultMode == FormatMode.overwrite)
        '-w',

      // Pass in the line-length if configured.
      if (config.lineLength != null) ...['-l', '${config.lineLength}'],

      // Pass through the rest of the args (this may be empty).
      ...argResults.rest,
    ];

    if (inputs.length <= 5 || verboseEnabled(this)) {
      _log.info(
          'Running: ${executable} ${args.join(' ')} ${inputs.join(' ')}\n');
    } else {
      _log.info(
          'Running: ${executable} ${args.join(' ')} <${inputs.length} paths>\n');
    }

    final process = await Process.start(
      executable,
      [...args, ...inputs],
      mode: ProcessStartMode.inheritStdio,
    );

    return process.exitCode;
  }
}

class FormatConfig extends DartDevToolConfig {
  FormatConfig({
    String commandName,
    this.defaultMode,
    this.exclude,
    this.formatter,
    this.include,
    this.lineLength,
  }) : super(commandName);

  final FormatMode defaultMode;

  final List<Glob> exclude;

  final Formatter formatter;

  final List<Glob> include;

  final int lineLength;

  FormatConfig merge(FormatConfig other) => FormatConfig(
        commandName: other?.commandName ?? commandName,
        defaultMode: other?.defaultMode ?? defaultMode,
        exclude: other?.exclude ?? exclude,
        formatter: other?.formatter ?? formatter,
        include: other?.include ?? include,
        lineLength: other?.lineLength ?? lineLength,
      );
}

enum FormatMode {
  dryRun,
  overwrite,
  printChanges,
}

enum Formatter {
  dartfmt,
  dartStyle,
}
