import 'dart:io';

import 'package:yaml/yaml.dart';

/// The version number of the dart_dev package, or `null` if it couldn't be
/// loaded.
///
/// This is a semantic version, optionally followed by a space and additional
/// data about its source.
///
/// TODO: credit test pkg https://github.com/dart-lang/test/blob/1ccf56082adf35d5436e09793f547dbaa2e48218/pkgs/test_core/lib/src/runner/version.dart
final String dartDevVersion = (() {
  dynamic lockfile;
  try {
    lockfile = loadYaml(File('pubspec.lock').readAsStringSync());
  } on FormatException catch (_) {
    return null;
  } on IOException catch (_) {
    return null;
  }

  if (lockfile is! Map<dynamic, dynamic>) return null;
  var packages = lockfile['packages'];
  if (packages is! Map<dynamic, dynamic>) return null;
  var package = packages['dart_dev'];
  if (package is! Map<dynamic, dynamic>) return null;

  var source = package['source'];
  if (source is! String) return null;

  switch (source as String) {
    case 'hosted':
      var version = package['version'];
      return (version is String) ? version : null;

    case 'git':
      var version = package['version'];
      if (version is! String) return null;
      var description = package['description'];
      if (description is! Map<dynamic, dynamic>) return null;
      var ref = description['resolved-ref'];
      if (ref is! String) return null;

      return '$version (${ref.substring(0, 7)})';

    case 'path':
      var version = package['version'];
      if (version is! String) return null;
      var description = package['description'];
      if (description is! Map<dynamic, dynamic>) return null;
      var path = description['path'];
      if (path is! String) return null;

      return '$version (from $path)';

    default:
      return null;
  }
})();
