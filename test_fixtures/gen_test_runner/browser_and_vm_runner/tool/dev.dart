library test_generator_browser_and_vm_runner.tool.dev;

import 'package:dart_dev/dart_dev.dart';

main(List<String> args) async {
  config.genTestRunner.configs = [
    new TestRunnerConfig(env: Environment.both, directory: 'test/'),
  ];

  await dev(args);
}
