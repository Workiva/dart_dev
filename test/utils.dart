import 'dart:convert';
import 'dart:io';

import 'package:dart_dev/src/utils/executables.dart' as exe;
import 'package:dart_dev/utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

class TempPubCache {
  final dir = Directory.systemTemp.createTempSync('test_pub_cache_');
  Map<String, String> get envOverride => {'PUB_CACHE': dir.absolute.path};
  void tearDown() => dir.deleteSync(recursive: true);
}

/// Globally activates the given [package].
///
/// If non-null, [environment] will be passed to the [Process]. This provides a
/// way to override certain things like the `PUB_CACHE` var that points pub to
/// the global pub-cache directory.
void globalActivate(String packageName, String constraint,
    {Map<String, String>? environment}) {
  final result = Process.runSync(
    exe.dart,
    ['pub', 'global', 'activate', packageName, constraint],
    environment: environment,
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) {
    fail('Failed to global activate $packageName.\n'
        'Process stdout:\n'
        '---------------\n'
        '${result.stdout}\n'
        'Process stderr:\n'
        '---------------\n'
        '${result.stderr}\n');
  }
  expect(
      globalPackageIsActiveAndCompatible(
          packageName, VersionConstraint.parse(constraint),
          environment: environment),
      isTrue,
      reason: "$packageName should be globally activated, but isn't.");
}
