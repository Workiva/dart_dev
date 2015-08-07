library dart_dev.dev;

import 'package:dart_dev/dart_dev.dart';

main(args) async {
  config.analyze.entryPoints = ['lib/', 'test/', 'tool/'];
  config.format.directories = ['lib/', 'test/', 'tool/'];

  await dev(args);
}
