library test_generator_default_config.tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;
import 'package:dart_dev/src/tasks/gen_test_runner/config.dart';

main(List<String> args) async {

  await dev(args);
}
