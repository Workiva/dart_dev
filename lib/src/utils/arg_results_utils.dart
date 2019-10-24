import 'package:args/args.dart';

bool flagValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] == null) {
    return null;
  }
  if (argResults[name] is! bool) {
    throw ArgumentError('Option "$name" is not a flag.');
  }
  return argResults[name];
}

Iterable<String> multiOptionValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] == null) {
    return null;
  }
  if (argResults[name] is! Iterable<String>) {
    throw ArgumentError('Option "$name" is not a multi-option.');
  }
  return List<String>.from(argResults[name]);
}

String singleOptionValue(ArgResults argResults, String name) {
  if (argResults == null || argResults[name] == null) {
    return null;
  }
  if (argResults[name] is! String) {
    throw ArgumentError('Option "$name" is not a single option.');
  }
  return argResults[name];
}

Iterable<String> splitSingleOptionValue(ArgResults argResults, String name) =>
    singleOptionValue(argResults, name)?.split(' ');
