import 'dart:convert';
import 'dart:io';

bool packageIsGloballyActivated(String packageName) {
  final executable = 'pub';
  final args = ['global', 'list'];
  final result = Process.runSync('pub', ['global', 'list'],
      stderrEncoding: utf8, stdoutEncoding: utf8);
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
      .map((String line) => line.replaceFirst(trimPattern, ''))
      .any((globalPackage) => globalPackage == packageName);
}
