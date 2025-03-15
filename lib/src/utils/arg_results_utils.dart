import 'package:args/args.dart';

bool? flagValue(ArgResults? argResults, String name) {
  final result = argResults?[name];
  if (result == null) {
    return null;
  }

  if (result is! bool) {
    throw ArgumentError('Option "$name" is not a flag.');
  }
  return result;
}

Iterable<String>? multiOptionValue(ArgResults? argResults, String name) {
  final result = argResults?[name];
  if (result == null) {
    return null;
  }

  if (result is! Iterable<String>) {
    throw ArgumentError('Option "$name" is not a multi-option.');
  }
  return List<String>.from(result);
}

String? singleOptionValue(ArgResults? argResults, String name) {
  final result = argResults?[name];
  if (result == null) {
    return null;
  }

  if (result is! String) {
    throw ArgumentError('Option "$name" is not a single option.');
  }
  return result;
}

Iterable<String>? splitSingleOptionValue(ArgResults? argResults, String name) =>
    singleOptionValue(argResults, name)?.split(' ');
