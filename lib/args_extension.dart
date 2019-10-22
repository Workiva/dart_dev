import 'package:args/args.dart';

extension DartDevArgResults on ArgResults {
  bool flagValue(String name) {
    var value = this[name];
    if (value == null) return null;
    if (value is! bool) {
      throw ArgumentError('Option "$name" is not a flag.');
    }
    return value;
  }

  List<String> multiOptionValue(String name) {
    var value = this[name];
    if (value == null) return null;
    if (value is! Iterable<String>) {
      throw ArgumentError('Option "$name" is not a multi-option.');
    }
    return value;
  }

  String singleOptionValue(String name) {
    var value = this[name];
    if (value == null) return null;
    if (value is! String) {
      throw ArgumentError('Option "$name" is not a single option.');
    }
    return value;
  }

  List<String> splitSingleOptionValue(String name, {String split}) {
    final value = this.singleOptionValue(name);
    if (value == null) return null;
    return value.split(split ?? ' ');
  }
}
