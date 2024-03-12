import 'dart:collection';

import 'package:yaml/yaml.dart';

/// Index into the pubspecLock to locate the 'source' field for the given
/// package.
String? _getPubSpecLockPackageSource(
    YamlDocument pubSpecLock, String packageName) {
  final contents = pubSpecLock.contents;
  if (contents is YamlMap) {
    final packages = contents['packages'];
    if (packages is YamlMap) {
      final specificDependency = packages[packageName];
      if (specificDependency is YamlMap) return specificDependency['source'];
    }
  }
  return null;
}

/// Return a mapping of package name to dependency 'type', using the pubspec
/// lock document. If a package cannot be located in the pubspec lock document,
/// it will map to null.
HashMap<String, String?> getDependencySources(
        YamlDocument pubspecLockDocument, Iterable<String> packageNames) =>
    HashMap.fromIterable(packageNames,
        value: (name) =>
            _getPubSpecLockPackageSource(pubspecLockDocument, name));
