library dart_dev.src.platform_util.platform_util;

import 'dart:async';

import 'package:dart_dev/src/platform_util/standard_platform_util.dart';

PlatformUtil platformUtil = new StandardPlatformUtil();

abstract class PlatformUtil {
  static PlatformUtil retrieve() {
    if (platformUtil == null) throw new StateError(
        'dart_dev\'s PlatformUtil instance must not be null.');
    return platformUtil;
  }

  /// Generates an HTML report for an LCOV formatted coverage file.
  // TODO: Future<bool> generateLcovHtml(String lcovPath, String outputPath);

  /// Determines whether or not the project in the current working directory has
  /// defined [packageName] as an immediate dependency. In other words, this
  /// checks if [packageName] is in the project's pubspec.yaml.
  bool hasImmediateDependency(String packageName);

  /// Determines whether or not [executable] is installed on this platform.
  Future<bool> isExecutableInstalled(String executable);
}
