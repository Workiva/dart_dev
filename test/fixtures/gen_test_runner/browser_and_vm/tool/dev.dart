library test_generator_browser_and_vm.tool.dev;

import 'package:dart_dev/dart_dev.dart';

main(List<String> args) async {
  config.genTestRunner.configs = [
    new TestRunnerConfig(env: Environment.vm, directory: 'test/vm/'),
    new TestRunnerConfig(directory: 'test/browser/', genHtml: true),
  ];

  await dev(args);
}
