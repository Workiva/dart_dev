import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';

import '../command_builder.dart';
import '../utils/ensure_process_exit.dart';
import '../utils/has_any_positional_args_before_separator.dart';
import '../utils/verbose_enabled.dart';

final _log = Logger('Analyze');

class AnalyzeCommand implements CommandBuilder {
  List<String> dartanalyzerArgs = [];

  @override
  String description;

  @override
  bool hidden;

  List<Glob> include = <Glob>[];

  @override
  Command<int> build(String commandName) => _AnalyzeCommand(
        commandName,
        dartanalyzerArgs ?? <String>[],
        description,
        hidden,
        include ?? <Glob>[],
      );
}

class _AnalyzeCommand extends Command<int> {
  final String _commandName;
  final List<String> _dartanalyzerArgs;
  final String _description;
  final bool _hidden;
  final List<Glob> _include;

  _AnalyzeCommand(
    this._commandName,
    this._dartanalyzerArgs,
    this._description,
    this._hidden,
    this._include,
  );

  @override
  String get name => _commandName ?? 'analyze';

  @override
  String get description =>
      _description ?? 'Run static analysis on dart files in this package.';

  @override
  bool get hidden => _hidden ?? false;

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
    final args = [..._dartanalyzerArgs, ...argResults.rest];
    final entrypoints = buildEntrypoints(_include);
    logDartanalyzerCommand(args, entrypoints, verbose: verboseEnabled(this));
    final process = await Process.start(
        'dartanalyzer', [...args, ...entrypoints],
        mode: ProcessStartMode.inheritStdio);
    ensureProcessExit(process, log: _log);
    return process.exitCode;
  }
}

void assertNoPositionalArgsBeforeSeparator(
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

Iterable<String> buildEntrypoints(List<Glob> include, {String root}) {
  final entrypoints = <String>{
    for (final glob in include ?? <Glob>[])
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

/// Returns a list of Globs that match all of the standard Dart project
/// analysis entry points:
/// - public dart files in lib/ (i.e. not in lib/src/)
/// - all dart files in benchmark/, bin/, example/, test/, tool/, and web/
///
/// Normally, using the default include glob of `.` is sufficient for most
/// projects. However, if customization is needed, this method may help.
List<Glob> buildIncludeGlobs({
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

void logDartanalyzerCommand(
    Iterable<String> args, Iterable<String> entrypoints,
    {bool verbose,}) {
  verbose ??= false;
  if (entrypoints.length <= 5 || verbose) {
    _log.info(
        'Running: dartanalyzer ${args.join(' ')} ${entrypoints.join(' ')}\n');
  } else {
    _log.info(
        'Running: dartanalyzer ${args.join(' ')} <${entrypoints.length} paths>\n');
  }
}