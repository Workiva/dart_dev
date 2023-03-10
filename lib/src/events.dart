import 'dart:async';

Future<void> commandComplete(CommandResult result) async {
  await Future.wait(_commandCompleteListeners
      .map((listener) => Future<void>.value(listener(result))));
}

void onCommandComplete(FutureOr<void> Function(CommandResult result) callback) {
  _commandCompleteListeners.add(callback);
}

final _commandCompleteListeners =
    <FutureOr<void> Function(CommandResult result)>[];

class CommandResult {
  CommandResult(this.args, this.exitCode, this.duration);
  final List<String> args;
  final Duration duration;
  final int exitCode;
}
