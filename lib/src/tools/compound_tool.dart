import 'dart:async';
import 'dart:math';

import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';
import '../utils/rest_args_with_separator.dart';

final _log = Logger('CompoundTool');

typedef ArgMapper = ArgResults Function(ArgParser parser, ArgResults? results);

/// Return a parsed [ArgResults] that only includes the option args (flags,
/// single options, and multi options) supported by [parser].
///
/// Positional args and any option args not supported by [parser] will be
/// excluded.
///
/// This [ArgMapper] is the default for tools added to a [CompoundTool].
ArgResults takeOptionArgs(ArgParser parser, ArgResults results) =>
    parser.parse(optionArgsOnly(results, allowedOptions: parser.options.keys));

/// Return a parsed [ArgResults] that includes the option args (flags, single
/// options, and multi options) supported by [parser] as well as any positional
/// args.
///
/// Option args not supported by [parser] will be excluded.
///
/// Use this with a [CompoundTool] to indicate which tool should receive the
/// positional args given to the compound target.
///
///     // tool/dart_dev/config.dart
///     import 'package:dart_dev/dart_dev.dart';
///
///     final config = {
///       'test': CompoundTool()
///         // This tool will not receive any positional args
///         ..addTool(startServerTool)
///         // This tool will receive the test-specific option args as well as
///         // any positional args given to `ddev test`.
///         ..addTool(TestTool(), argMapper: takeAllArgs)
///     };
ArgResults takeAllArgs(ArgParser parser, ArgResults? results) => parser.parse([
      ...optionArgsOnly(results!, allowedOptions: parser.options.keys),
      ...restArgsWithSeparator(results),
    ]);

class CompoundTool extends DevTool with CompoundToolMixin {}

mixin CompoundToolMixin on DevTool {
  @override
  ArgParser get argParser => _argParser;
  final _argParser = CompoundArgParser();

  final _specs = <DevToolSpec>[];

  @override
  String? get description => _description ??= _specs
      .map((s) => s.tool.description)
      .firstWhere((desc) => desc != null, orElse: () => null);

  @override
  set description(String? value) => _description = value;
  String? _description;

  void addTool(DevTool tool, {bool? alwaysRun, ArgMapper? argMapper}) {
    final runWhen = alwaysRun ?? false ? RunWhen.always : RunWhen.passing;
    _specs.add(DevToolSpec(runWhen, tool, argMapper: argMapper));
    if (tool.argParser != null) {
      _argParser.addParser(tool.argParser!);
    }
  }

  @override
  FutureOr<int?> run([DevToolExecutionContext? context]) async {
    context ??= DevToolExecutionContext();

    int? code = 0;
    for (var i = 0; i < _specs.length; i++) {
      if (!shouldRunTool(_specs[i].when, code)) continue;
      final newCode =
          await _specs[i].tool.run(contextForTool(context, _specs[i]));
      _log.fine('Step ${i + 1}/${_specs.length} done (code: $newCode)\n');
      if (code == 0) {
        code = newCode;
      }
    }

    return code;
  }
}

List<String> optionArgsOnly(ArgResults results,
    {Iterable<String>? allowedOptions}) {
  final args = <String>[];
  for (final option in results.options) {
    if (!results.wasParsed(option)) continue;
    if (allowedOptions != null && !allowedOptions.contains(option)) continue;
    final value = results[option];
    if (value is bool) {
      args.add('--${value ? '' : 'no-'}$option');
    } else if (value is Iterable) {
      args.addAll([for (final v in value as List<String>) '--$option=$v']);
    } else {
      args.add('--$option=$value');
    }
  }
  return args;
}

DevToolExecutionContext contextForTool(
    DevToolExecutionContext baseContext, DevToolSpec? spec) {
  if (baseContext.argResults == null) return baseContext;

  final parser = spec!.tool.argParser ?? ArgParser();
  final argMapper = spec.argMapper ?? takeOptionArgs;
  return baseContext.update(
      argResults: argMapper(parser, baseContext.argResults!));
}

bool shouldRunTool(RunWhen runWhen, int? currentExitCode) {
  switch (runWhen) {
    case RunWhen.always:
      return true;
    case RunWhen.passing:
      return currentExitCode == 0;
    default:
      throw FallThroughError();
  }
}

class DevToolSpec {
  final ArgMapper? argMapper;

  final DevTool tool;

  final RunWhen when;

  DevToolSpec(this.when, this.tool, {this.argMapper});
}

enum RunWhen { always, passing }

class CompoundArgParser implements ArgParser {
  final _compoundParser = ArgParser();
  final _subParsers = <ArgParser>[];

  void addParser(ArgParser argParser) {
    _subParsers.add(argParser);

    argParser.commands.forEach(_compoundParser.addCommand);

    for (final option in argParser.options.values) {
      if (option.isFlag) {
        _compoundParser.addFlag(option.name,
            abbr: option.abbr,
            help: option.help,
            defaultsTo: option.defaultsTo,
            negatable: option.negatable!,
            callback: option.callback as void Function(bool)?,
            hide: option.hide);
      } else if (option.isMultiple) {
        _compoundParser.addMultiOption(option.name,
            abbr: option.abbr,
            help: option.help,
            valueHelp: option.valueHelp,
            allowed: option.allowed,
            allowedHelp: option.allowedHelp,
            defaultsTo: option.defaultsTo,
            callback: option.callback as void Function(List<String>)?,
            splitCommas: option.splitCommas,
            hide: option.hide);
      } else if (option.isSingle) {
        _compoundParser.addOption(option.name,
            abbr: option.abbr,
            help: option.help,
            valueHelp: option.valueHelp,
            allowed: option.allowed,
            allowedHelp: option.allowedHelp,
            defaultsTo: option.defaultsTo,
            callback: option.callback as void Function(String?)?,
            hide: option.hide);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ArgParser overrides.
  // ---------------------------------------------------------------------------

  @override
  void addSeparator(String text) => _compoundParser.addSeparator(text);

  @override
  bool get allowTrailingOptions =>
      _subParsers.every((ap) => ap.allowTrailingOptions);

  @override
  bool get allowsAnything => false;

  @override
  Map<String, ArgParser> get commands => _compoundParser.commands;

  @override
  defaultFor(String option) => _compoundParser.defaultFor(option);

  @override
  Option? findByAbbreviation(String abbr) =>
      _compoundParser.findByAbbreviation(abbr);

  @override
  Option? findByNameOrAlias(String name) =>
      _compoundParser.findByNameOrAlias(name);

  @override
  getDefault(String option) => _compoundParser.defaultFor(option);

  @override
  Map<String, Option> get options => _compoundParser.options;

  @override
  ArgResults parse(Iterable<String> args) => _compoundParser.parse(args);

  @override
  String get usage {
    if (_subParsers.isEmpty) return '';

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('This command is composed of multiple parts, each of which has '
          'its own options.');
    for (final parser in _subParsers) {
      buffer
        ..writeln()
        ..writeln('-' * max(usageLineLength ?? 80, 80))
        ..writeln()
        ..writeln(parser.usage);
    }

    return buffer.toString();
  }

  @override
  int? get usageLineLength {
    if (_subParsers.isEmpty) return null;
    int? max;
    for (final parser in _subParsers) {
      if (max != null &&
          parser.usageLineLength != null &&
          parser.usageLineLength! > max) {
        max = parser.usageLineLength;
      }
    }
    return max;
  }

  @override
  ArgParser addCommand(String name, [ArgParser? parser]) =>
      _compoundParser.addCommand(name, parser);

  @override
  void addFlag(String name,
          {String? abbr,
          String? help,
          bool? defaultsTo = false,
          bool negatable = true,
          void Function(bool value)? callback,
          bool hide = false,
          List<String> aliases = const []}) =>
      _compoundParser.addFlag(name,
          abbr: abbr,
          help: help,
          defaultsTo: defaultsTo,
          negatable: negatable,
          callback: callback,
          hide: hide,
          aliases: aliases);

  @override
  void addMultiOption(String name,
          {String? abbr,
          String? help,
          String? valueHelp,
          Iterable<String>? allowed,
          Map<String, String>? allowedHelp,
          Iterable<String>? defaultsTo,
          void Function(List<String> values)? callback,
          bool splitCommas = true,
          bool hide = false,
          List<String> aliases = const []}) =>
      _compoundParser.addMultiOption(name,
          abbr: abbr,
          help: help,
          valueHelp: valueHelp,
          allowed: allowed,
          allowedHelp: allowedHelp,
          defaultsTo: defaultsTo,
          callback: callback,
          splitCommas: splitCommas,
          hide: hide,
          aliases: aliases);

  @override
  void addOption(String name,
          {String? abbr,
          String? help,
          String? valueHelp,
          Iterable<String>? allowed,
          Map<String, String>? allowedHelp,
          String? defaultsTo,
          Function? callback,
          bool mandatory = false,
          bool hide = false,
          List<String> aliases = const []}) =>
      _compoundParser.addOption(name,
          abbr: abbr,
          help: help,
          valueHelp: valueHelp,
          allowed: allowed,
          allowedHelp: allowedHelp,
          defaultsTo: defaultsTo,
          callback: callback as void Function(String?)?,
          mandatory: mandatory,
          hide: hide,
          aliases: aliases);
}
