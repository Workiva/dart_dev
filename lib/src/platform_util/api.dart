library dart_dev.src.platform_util.api;

import 'dart:async';

import 'package:dart_dev/src/platform_util/platform_util.dart';

/// Determines whether or not the project in the current working directory has
/// defined [packageName] as an immediate dependency. In other words, this
/// checks if [packageName] is in the project's pubspec.yaml.
bool hasImmediateDependency(String packageName) =>
    PlatformUtil.retrieve().hasImmediateDependency(packageName);

/// Determines whether or not [executable] is installed on this platform.
Future<bool> isExecutableInstalled(String executable) =>
    PlatformUtil.retrieve().isExecutableInstalled(executable);
