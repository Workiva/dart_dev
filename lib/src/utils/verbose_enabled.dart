import 'package:args/command_runner.dart';

bool verboseEnabled(Command<dynamic> command) =>
    command.globalResults!['verbose'] as bool? ?? false;
