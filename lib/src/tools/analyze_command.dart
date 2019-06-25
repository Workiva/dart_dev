import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';

import '../utils/ensure_process_exit.dart';
import '../utils/has_any_positional_args_before_separator.dart';
import '../utils/verbose_enabled.dart';

final _log = Logger('AnalyzeTool');

class AnalyzeCommand extends Command<int> {
  final AnalyzeConfig config;

  AnalyzeCommand([AnalyzeConfig config]) : config = config ?? AnalyzeConfig();

  @override
  String get name => config.commandName ?? 'analyze';

  @override
  String get description =>
      'Run static analysis on dart files in this package.';

  @override
  bool get hidden => config.hidden ?? false;

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[dart_dev arguments]')} '
      '[-- [dartanalyzer arguments]]';

  @override
  String get usageFooter => '\n'
      'Run "dartanalyzer -h" to see the available dartanalyzer arguments.\n'
      'You can use any of them with "dart_dev $name" by passing them after a '
      '"--" separator.';

  @override
  Future<int> run() async {
    assertNoPositionalArgsBeforeSeparator(name, argResults, usageException);
    final args = buildDartanalyzerArgs(config, argResults);
    final entrypoints = buildEntrypoints(config);
    logDartanalyzerCommand(args, entrypoints, verbose: verboseEnabled(this));
    final process = await Process.start(
        'dartanalyzer', [...args, ...entrypoints],
        mode: ProcessStartMode.inheritStdio);
    ensureProcessExit(process);
    return process.exitCode;
  }

  static void assertNoPositionalArgsBeforeSeparator(
    String name,
    ArgResults argResults,
    void usageException(String message),
  ) {
    if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
      usageException('The "$name" command does not support positional args '
          'before the "--" separator.\n'
          'Args for the dartanalyzer should be passed in after a "--" '
          'separator.');
    }
  }

  static Iterable<String> buildDartanalyzerArgs(
          AnalyzeConfig config, ArgResults argResults) =>
      [
        // Pass through the configured dartanalyzer args (this may be empty).
        ...config.dartanalyzerArgs ?? [],

        // Pass through the rest of the args (this may be empty).
        ...argResults.rest,
      ];

  static Iterable<String> buildEntrypoints(AnalyzeConfig config,
      {String root}) {
    final entrypoints = <String>{
      for (final glob in config.include ?? [])
        ...glob
            .listSync(root: root)
            .where((entity) => entity is File || entity is Directory)
            .map((entity) => entity.path),
    };
    if (entrypoints.isEmpty) {
      entrypoints.add('.');
    }
    return entrypoints;
  }

  static void logDartanalyzerCommand(
      Iterable<String> args, Iterable<String> entrypoints,
      {bool verbose}) {
    verbose ??= false;
    if (entrypoints.length <= 5 || verbose) {
      _log.info(
          'Running: dartanalyzer ${args.join(' ')} ${entrypoints.join(' ')}\n');
    } else {
      _log.info(
          'Running: dartanalyzer ${args.join(' ')} <${entrypoints.length} paths>\n');
    }
  }
}

class AnalyzeConfig {
  AnalyzeConfig({
    this.dartanalyzerArgs,
    this.commandName,
    this.include,
    this.hidden,
  });

  final String commandName;

  final List<String> dartanalyzerArgs;

  final bool hidden;

  final List<Glob> include;

  AnalyzeConfig merge(AnalyzeConfig other) => AnalyzeConfig(
        commandName: other?.commandName ?? commandName,
        dartanalyzerArgs: other?.dartanalyzerArgs ?? dartanalyzerArgs,
        hidden: other?.hidden ?? hidden,
        include: other?.include ?? include,
      );

  /// Returns a list of Globs that match all of the standard Dart project
  /// analysis entry points:
  /// - public dart files in lib/ (i.e. not in lib/src/)
  /// - all dart files in benchmark/, bin/, example/, test/, tool/, and web/
  ///
  /// Normally, using the default include glob of `.` is sufficient for most
  /// projects. However, if customization is needed, this method may help.
  static List<Glob> buildIncludeGlobs({
    bool includeBenchmark,
    bool includeBin,
    bool includeExample,
    bool includeLib,
    bool includeTest,
    bool includeTool,
    bool includeWeb,
  }) =>
      [
        // All public entry points (dart files in lib/ except those in lib/src/).
        if (includeLib != false)
          Glob('lib/{**.dart,!src/**}'),

        // All dart files in the rest of the standard dart project directories.
        if (includeBenchmark != false)
          Glob('benchmark/**.dart'),
        if (includeBin != false)
          Glob('bin/**.dart'),
        if (includeExample != false)
          Glob('example/**.dart'),
        if (includeTest != false)
          Glob('test/**.dart'),
        if (includeTool != false)
          Glob('tool/**.dart'),
        if (includeWeb != false)
          Glob('web/**.dart'),
      ];
}
