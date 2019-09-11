import 'package:args/command_runner.dart';

bool verboseEnabled<T>(Command<T> command) =>
    command.globalResults['verbose'] == true;
