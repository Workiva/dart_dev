import 'package:args/command_runner.dart';

bool verboseEnabled(Command command) =>
    command.globalResults['verbose'] == true;
