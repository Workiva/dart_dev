import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import 'executables.dart' as exe;

/// Returns `true` if [packageName] is globally activated at a version
/// allowed by [constraint]. Returns `false` otherwise.
///
/// This is determined by running a `dart pub global list` and looking for
/// [packageName] in the output and then testing its version against
/// [constraint].
///
/// The pub-cache that gets checked during this can be overridden by providing
/// an [environment] map with a `'PUB_CACHE': '<path>'` entry, which will be
/// passed to the [Process] that is run by this function.
bool globalPackageIsActiveAndCompatible(
    String packageName, VersionConstraint constraint,
    {Map<String, String> environment}) {
  final args = ['pub', 'global', 'list'];
  final result = Process.runSync(exe.dart, args,
      environment: environment, stderrEncoding: utf8, stdoutEncoding: utf8);
  if (result.exitCode != 0) {
    throw ProcessException(
        exe.dart,
        args,
        'Could not list global pub packages:\n${result.stderr}',
        result.exitCode);
  }

  for (final line in result.stdout.split('\n')) {
    // Example line: "webdev 2.5.1" or "dart_dev 3.0.0 at path ..."
    final parts = line.split(' ');
    if (parts.length < 2 || parts[0] != packageName) {
      continue;
    }
    return constraint.allows(Version.parse(parts[1]));
  }
  return false;
}
