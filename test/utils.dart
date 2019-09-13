import 'dart:convert';
import 'dart:io';

import 'package:dart_dev/utils.dart';
import 'package:test/test.dart';

class TempPubCache {
  final dir = Directory.current.createTempSync('test_pub_cache_');
  Map<String, String> get envOverride => {'PUB_CACHE': dir.absolute.path};
  void tearDown() => dir.deleteSync(recursive: true);
}

/// Globally activates the given [package].
///
/// If non-null, [environment] will be passed to the [Process]. This provides a
/// way to override certain things like the `PUB_CACHE` var that points pub to
/// the global pub-cache directory.
void globalActivate(String package, {Map<String, String> environment}) {
  final result = Process.runSync(
    'pub',
    ['global', 'activate', ...package.split(' ')],
    environment: environment,
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) {
    fail('Failed to global activate $package.\n'
        'Process stdout:\n'
        '---------------\n'
        '${result.stdout}\n'
        'Process stderr:\n'
        '---------------\n'
        '${result.stderr}\n');
  }
  final packageName = package.split(' ')[0];
  expect(
      packageIsGloballyActivated(packageName, environment: environment), isTrue,
      reason: "$packageName should be globally activated, but isn't.");
}
