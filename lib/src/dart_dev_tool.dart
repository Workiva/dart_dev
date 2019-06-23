import 'package:args/command_runner.dart';

abstract class DartDevTool {
  Command<int> get command;
}

abstract class DartDevToolConfig {
  String commandName;

  DartDevToolConfig(this.commandName);
}
