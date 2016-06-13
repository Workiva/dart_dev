library tool.dev;

import 'package:dart_dev/dart_dev.dart';

main(args) async {
  config.local.followSymlinks = false;
  await dev(args);
}
