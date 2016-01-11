library test_generator_browser_and_vm.tool.dev;

import 'package:dart_dev/dart_dev.dart';

main(List<String> args) async {
  config.genTestRunner.configs = [
    new SingleRunnerConfig(env: Environment.vm, react: false, directory: 'test/vm'),
    new SingleRunnerConfig(react: false, directory: 'test/browser', genHtml: true),
  ];

  await dev(args);
}
