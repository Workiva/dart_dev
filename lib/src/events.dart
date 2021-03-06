import 'dart:async';

Future<void> commandComplete(CommandResult result) async {
  await Future.wait(
      _commandCompleteListeners.map((listener) => listener(result)));
}

void onCommandComplete(FutureOr<dynamic> callback(CommandResult result)) {
  _commandCompleteListeners.add(callback);
}

final _commandCompleteListeners =
    <FutureOr<dynamic> Function(CommandResult result)>[];

class CommandResult {
  CommandResult(this.args, this.exitCode, this.duration);
  final List<String> args;
  final Duration duration;
  final int exitCode;
}
