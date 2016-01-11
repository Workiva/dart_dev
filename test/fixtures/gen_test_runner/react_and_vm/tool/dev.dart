library test_generator_react_and_vm.tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config, SingleRunnerConfig;
import 'package:dart_dev/src/tasks/gen_test_runner/config.dart';

main(List<String> args) async {

  config.genTestRunner.configs = [
    new SingleRunnerConfig(env: Environment.vm)
  ];

  await dev(args);
}
