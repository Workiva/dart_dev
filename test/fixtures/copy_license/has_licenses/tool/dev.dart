library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.copyLicense
    ..directories = ['example/']
    ..licensePath = 'NONSTANDARDLICENSE';

  await dev(args);
}
