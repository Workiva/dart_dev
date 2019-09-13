import 'dart:convert';
import 'dart:io';

/// Returns `true` if [packageName] is globally activated and `false` otherwise.
///
/// This is determined by running a `pub global list` and looking for
/// [packageName] in the output.
///
/// The pub-cache that gets checked during this can be overridden by providing
/// an [environment] map with a `'PUB_CACHE': '<path>'` entry, which will be
/// passed to the [Process] that is run by this function.
bool packageIsGloballyActivated(String packageName,
    {Map<String, String> environment}) {
  final executable = 'pub';
  final args = ['global', 'list'];
  final result = Process.runSync('pub', ['global', 'list'],
      environment: environment, stderrEncoding: utf8, stdoutEncoding: utf8);
  if (result.exitCode != 0) {
    throw ProcessException(
        executable,
        args,
        'Could not list global pub packages:\n${result.stderr}',
        result.exitCode);
  }
  final trimPattern = RegExp(r' .*$');
  return result.stdout
      .split('\n')
      .map((line) => line.replaceFirst(trimPattern, ''))
      .any((globalPackage) => globalPackage == packageName);
}
