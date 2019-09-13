import 'dart:io';

import 'package:dart_dev/src/executable.dart' as executable;

void main(List<String> args) async {
  final code = await executable.run(args);
  exit(code);
}
