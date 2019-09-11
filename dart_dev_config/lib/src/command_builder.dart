import 'package:args/command_runner.dart';

abstract class CommandBuilder {
  String get description;
  set description(String value);

  bool get hidden;
  set hidden(bool value);

  Command<int> build(String commandName);
}
