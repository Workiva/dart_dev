import 'dart:async';
import 'dart:math';

import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:logging/logging.dart';

import '../dart_dev_tool.dart';

final _log = Logger('CompoundTool');

class CompoundTool extends DevTool with CompoundToolMixin {}

mixin CompoundToolMixin on DevTool {
  @override
  ArgParser get argParser => _argParser;
  final _argParser = CompoundArgParser();

  final _specs = <DevToolSpec>[];

  @override
  String get description => _specs
      .map((s) => s.tool.description)
      .firstWhere((desc) => desc != null, orElse: () => null);

  void addTool(DevTool tool, {bool alwaysRun}) {
    final runWhen = alwaysRun ?? false ? RunWhen.always : RunWhen.passing;
    _specs.add(DevToolSpec(runWhen, tool));
    if (tool.argParser != null) {
      _argParser.addParser(tool.argParser);
    }
  }

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    context ??= DevToolExecutionContext();

    int code = 0;
    for (var i = 0; i < _specs.length; i++) {
      if (!shouldRunTool(_specs[i], code)) continue;
      final newCode = await _specs[i].tool.run(context);
      _log.fine('Step ${i + 1}/${_specs.length} done (code: $newCode)');
      _log.info('\n\n');
      if (code == 0) {
        code = newCode;
      }
    }

    return code;
  }
}

bool shouldRunTool(DevToolSpec spec, int currentExitCode) {
  switch (spec.when) {
    case RunWhen.always:
      return true;
    case RunWhen.passing:
      return currentExitCode == 0;
    default:
      throw FallThroughError();
  }
}

class DevToolSpec {
  final DevTool tool;

  final RunWhen when;

  DevToolSpec(this.when, this.tool);
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
            negatable: option.negatable,
            callback: option.callback,
            hide: option.hide);
      } else if (option.isMultiple) {
        _compoundParser.addMultiOption(option.name,
            abbr: option.abbr,
            help: option.help,
            valueHelp: option.valueHelp,
            allowed: option.allowed,
            allowedHelp: option.allowedHelp,
            defaultsTo: option.defaultsTo,
            callback: option.callback,
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
            callback: option.callback,
            hide: option.hide);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ArgParser overrides.
  // ---------------------------------------------------------------------------

  @override
  bool get allowTrailingOptions =>
      _subParsers.every((ap) => ap.allowTrailingOptions);

  @override
  bool get allowsAnything => false;

  @override
  Map<String, ArgParser> get commands => _compoundParser.commands;

  @override
  Option findByAbbreviation(String abbr) =>
      _compoundParser.findByAbbreviation(abbr);

  @override
  getDefault(String option) => _compoundParser.getDefault(option);

  @deprecated
  @override
  String getUsage() => usage;

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
  int get usageLineLength {
    if (_subParsers.isEmpty) return null;
    int max;
    for (final parser in _subParsers) {
      if (max != null &&
          parser.usageLineLength != null &&
          parser.usageLineLength > max) {
        max = parser.usageLineLength;
      }
    }
    return max;
  }

  @override
  ArgParser addCommand(String name, [ArgParser parser]) =>
      _compoundParser.addCommand(name, parser);

  @override
  void addFlag(String name,
          {String abbr,
          String help,
          bool defaultsTo = false,
          bool negatable = true,
          void Function(bool value) callback,
          bool hide = false}) =>
      _compoundParser.addFlag(name,
          abbr: abbr,
          help: help,
          defaultsTo: defaultsTo,
          negatable: negatable,
          callback: callback,
          hide: hide);

  @override
  void addMultiOption(String name,
          {String abbr,
          String help,
          String valueHelp,
          Iterable<String> allowed,
          Map<String, String> allowedHelp,
          Iterable<String> defaultsTo,
          void Function(List<String> values) callback,
          bool splitCommas = true,
          bool hide = false}) =>
      _compoundParser.addMultiOption(name,
          abbr: abbr,
          help: help,
          valueHelp: valueHelp,
          allowed: allowed,
          allowedHelp: allowedHelp,
          defaultsTo: defaultsTo,
          callback: callback,
          splitCommas: splitCommas,
          hide: hide);

  @override
  void addOption(String name,
          {String abbr,
          String help,
          String valueHelp,
          Iterable<String> allowed,
          Map<String, String> allowedHelp,
          String defaultsTo,
          Function callback,
          bool allowMultiple = false,
          bool splitCommas,
          bool hide = false}) =>
      _compoundParser.addOption(name,
          abbr: abbr,
          help: help,
          valueHelp: valueHelp,
          allowed: allowed,
          allowedHelp: allowedHelp,
          defaultsTo: defaultsTo,
          callback: callback,
          // ignore: deprecated_member_use
          allowMultiple: allowMultiple,
          // ignore: deprecated_member_use
          splitCommas: splitCommas,
          hide: hide);

  @override
  void addSeparator(String text) => _compoundParser.addSeparator(text);
}
