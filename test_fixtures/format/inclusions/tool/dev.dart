library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.format.paths = [
    'lib/included.dart',
    // test absent and present trailing slashes
    'lib/included_dir_1',
    'lib/included_dir_2/',
  ];
  await dev(args);
}
