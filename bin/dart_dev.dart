import 'dart:io';

import 'package:dart_dev/src/executable.dart' as executable;

void main(List<String> args) async {
  exit(await executable.run(args));
}
