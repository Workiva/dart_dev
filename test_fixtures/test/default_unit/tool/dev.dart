library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.test
    ..unitTests = ['lib/passing_unit.dart'];

  await dev(args);
}
