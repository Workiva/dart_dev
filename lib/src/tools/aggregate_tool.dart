import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../dart_dev_tool.dart';

// TODO: There are two use cases here and they probably need to be solved
// separately and not via a single "compose()" fn.
// UC1: Adding setup/teardown logic. Like tests, this logic needs to run
//      even if the task fails. Example: starting an integration server prior to
//      running tests and then tearing the server down after the tests.
// UC2: Chaining tasks together (like a shell `&&`). If any task in the chain
//      fails, the failure should be returned immediately (subsequent tasks
//      should not run).
class AggregateTool extends DevTool {
  AggregateTool(this._tool) {
    description = _tool.description;
    hidden = _tool.hidden;
  }

  List<DevTool> after;

  List<DevTool> before;

  final DevTool _tool;

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    context ??= DevToolExecutionContext();
    int code;

    for (final tool in before ?? <DevTool>[]) {
      code = await tool.run(DevToolExecutionContext(verbose: context.verbose));
      if (code != 0) {
        return code;
      }
    }

    code = await _tool.run(context);

    for (final tool in after ?? <DevTool>[]) {
      code = await tool.run(DevToolExecutionContext(verbose: context.verbose));
      if (code != 0) {
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
