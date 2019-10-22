import 'package:args/args.dart';

bool getFlagValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] is! bool) {
    return false;
  }
  return argResults[name];
}

Iterable<String> getMultiOptionValues(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] is! Iterable<String>) {
    return null;
  }
  return List<String>.from(argResults[name]).expand((arg) => ['--$name', arg]);
}

String getOptionValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] is! String) {
    return null;
  }
  return argResults[name];
}

Iterable<String> splitSingleOptionValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] == null) {
    return null;
  }
  return argResults[name].split(' ');
}
