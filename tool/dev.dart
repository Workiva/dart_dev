import 'package:dart_dev/configs/workiva.dart' as workiva_ddev_config;
import 'package:dart_dev/src/dart_dev_tool.dart';

Iterable<DartDevTool> get config => [
      ...workiva_ddev_config.build(),
    ];
