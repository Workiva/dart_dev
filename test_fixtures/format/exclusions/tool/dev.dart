library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.format.exclude = [
    'lib/excluded_file.dart',
    // test absent and present trailing slashes
    'lib/excluded_dir_1',
    'lib/excluded_dir_2/',
  ];
  await dev(args);
}
