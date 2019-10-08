import 'package:args/args.dart';

bool getFlagValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] is! bool) {
    return false;
  }
  return argResults[name];
}

Iterable<String> getMultiOptionValues(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] is! Iterable<String>) {
    return <String>[];
  }
  return List<String>.from(argResults[name]).expand((arg) => ['--$name', arg]);
}

Iterable<String> splitSingleOptionValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] == null) {
    return <String>[];
  }
  return argResults[name].split(' ');
}
