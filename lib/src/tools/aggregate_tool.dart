import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../dart_dev_tool.dart';

DevTool chainTool(DevTool tool, {List<DevTool> before, List<DevTool> after}) =>
    AggregateTool(tool, before: before, after: after, failEarly: true);

DevTool setUpTool(DevTool tool, {List<DevTool> setUp, List<DevTool> tearDown}) =>
    AggregateTool(tool, before: setUp, after: tearDown, failEarly: false);

class AggregateTool extends DevTool {
  AggregateTool(DevTool tool,
      {List<DevTool> after, List<DevTool> before, bool failEarly})
      : _after = after,
        _before = before,
        _failEarly = failEarly ?? true,
        _tool = tool {
    description = _tool.description;
    hidden = _tool.hidden;
  }

  final List<DevTool> _after;

  final List<DevTool> _before;

  final bool _failEarly;

  final DevTool _tool;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    context ??= DevToolExecutionContext();
    int code;

    int worseOf(int a, [int b]) => (b ?? 0) == 0 ? a : b;

    for (final tool in _before ?? <DevTool>[]) {
      code = worseOf(
          await tool.run(DevToolExecutionContext(verbose: context.verbose)),
          code);
      if (_failEarly && code != 0) {
        return code;
      }
    }

    code = worseOf(await _tool.run(context), code);
    if (_failEarly && code != 0) {
      return code;
    }

    for (final tool in _after ?? <DevTool>[]) {
      code = worseOf(
          await tool.run(DevToolExecutionContext(verbose: context.verbose)),
          code);
      if (_failEarly && code != 0) {
        return code;
      }
    }

    return code;
  }

  @override
  Command<int> toCommand(String name) =>
      WrappedCommand(name, this, _tool.toCommand(name));
}

class WrappedCommand extends DevToolCommand {
  WrappedCommand(String name, DevTool devTool, Command<int> innerCommand)
      : _command = innerCommand,
        super(name, devTool) {
    // Update the argParser for this command in the constructor body so that it
    // happens _after_ the super class constructor which will add a "help"
    // option to the parser. We have to do this because we're re-using a parser
    // from another [Command]; otherwise, we'd get a duplicate option error.
    _argParser = _command.argParser;
  }

  ArgParser _argParser;
  final Command<int> _command;

  @override
  ArgParser get argParser => _argParser ?? super.argParser;

  @override
  String get usageFooter => _command.usageFooter;
}
