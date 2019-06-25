import 'package:args/command_runner.dart';
import 'package:dart_dev/configs/workiva.dart' as workiva_ddev_config;

Iterable<Command<int>> get config => [
      ...workiva_ddev_config.build(),
    ];
