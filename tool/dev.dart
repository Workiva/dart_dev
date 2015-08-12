library dart_dev.dev;

import 'package:dart_dev/dart_dev.dart';

main(args) async {
  config.analyze.entryPoints = ['bin/', 'lib/', 'tool/'];
  config.format.directories = ['bin/', 'lib/', 'tool/'];

  await dev(args);
}
