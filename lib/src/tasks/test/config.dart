library dart_dev.src.tasks.test.config;

import 'package:dart_dev/src/tasks/config.dart';

const bool defaultIntegration = false;
const List<String> defaultIntegrationTests = const [];
const bool defaultUnit = true;
const List<String> defaultUnitTests = const ['test/'];
const List<String> defaultPlatforms = const [];

class TestConfig extends TaskConfig {
  List<String> integrationTests = defaultIntegrationTests;
  List<String> platforms = defaultPlatforms;
  List<String> unitTests = defaultUnitTests;
}
