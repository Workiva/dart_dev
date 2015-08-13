library dart_dev.src.tasks.copy_license.config;

import 'package:dart_dev/src/tasks/config.dart';

const List<String> defaultDirectories = const ['lib/'];
const String defaultLicensePath = 'LICENSE';

class CopyLicenseConfig extends TaskConfig {
  List<String> directories = defaultDirectories;
  String licensePath = defaultLicensePath;
}
