library dart_dev.dev;

import 'package:dart_dev/dart_dev.dart';

main(args) async {
  config.analyze.entryPoints = ['bin/', 'lib/', 'test/integration/', 'tool/'];
  config.format.directories = ['bin/', 'lib/', 'test/integration/', 'tool/'];
  config.test
    ..unitTests = []
    ..integrationTests = ['test/integration/'];

  await dev(args);
}
