import 'dart:async';

Future<void> close() async => await onCommandCompleteController.close();

Stream<CommandResult> get onCommandComplete =>
    onCommandCompleteController.stream;
final onCommandCompleteController = StreamController<CommandResult>();

class CommandResult {
  CommandResult(this.args, this.exitCode, this.duration);
  final List<String> args;
  final Duration duration;
  final int exitCode;
}
