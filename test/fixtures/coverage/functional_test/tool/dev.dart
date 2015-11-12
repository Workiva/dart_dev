library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.test.functionalTests = ['functional'];

  await dev(args);
}