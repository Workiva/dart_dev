library dart_dev.src.platform_util.standard_platform_util;

import 'dart:async';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:dart_dev/src/platform_util/platform_util.dart';

class StandardPlatformUtil implements PlatformUtil {
  bool hasImmediateDependency(String packageName) {
    File pubspec = new File('pubspec.yaml');
    Map pubspecYaml = loadYaml(pubspec.readAsStringSync());
    List deps = [];
    if (pubspecYaml.containsKey('dependencies')) {
      deps.addAll((pubspecYaml['dependencies'] as Map).keys);
    }
    if (pubspecYaml.containsKey('dev_dependencies')) {
      deps.addAll((pubspecYaml['dev_dependencies'] as Map).keys);
    }
    return deps.contains(packageName);
  }

  Future<bool> isExecutableInstalled(String executable) async {
    ProcessResult result = await Process.run('which', [executable]);
    return result.exitCode == 0;
  }
}
