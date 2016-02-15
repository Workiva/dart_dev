library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.test
    ..pubServe = true
    ..unitTests = ['test/unit_test.dart']
    ..platforms = ['content-shell'];

  await dev(args);
}
