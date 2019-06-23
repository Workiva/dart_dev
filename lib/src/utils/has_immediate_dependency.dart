import 'package:dart_dev/src/utils/cached_pubspec.dart';

/// Returns `true` if [packageName] is an immediate dependency, and `false`
/// otherwise.
///
/// This is useful for determining whether an executable from [packageName] can
/// be run (pub requires that the package be an explicit dependency to do so) or
/// if a builder might be applied (some builders are configured to auto-apply
/// only to packages that explicitly depend on them).
///
/// This function checks the current project's pubspec to see if any of these
/// conditions are met:
/// - The current package is [packageName]
/// - [packageName] is a dependency
/// - [packageName] is a dev dependency
/// - [packageName] is a dependency override
bool hasImmediateDependency(String packageName, {String path}) {
  final pubspec = cachedPubspec(path: path);
  return pubspec.name == packageName ||
      pubspec.devDependencies.keys.any((d) => d == packageName) ||
      pubspec.dependencies.keys.any((d) => d == packageName) ||
      pubspec.dependencyOverrides.keys.any((d) => d == packageName);
}
