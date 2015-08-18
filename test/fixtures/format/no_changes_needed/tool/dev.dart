library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.format.directories = ['bin/', 'lib/', 'tool/'];
  await dev(args);
}
