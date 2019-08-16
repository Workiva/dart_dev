import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Globally activates the `webdev` package at the given [constraint].
Future<Null> activateWebdev(String constraint) async {
  final process = await Process.start(
    'pub',
    ['global', 'activate', 'webdev', constraint],
    mode: ProcessStartMode.normal,
  );
  if (await process.exitCode != 0) {
    fail('Failed to global activate webdev $constraint.\n'
        'Process stdout:\n'
        '---------------\n'
        '${await process.stdout.transform(utf8.decoder).join('')}\n'
        'Process stderr:\n'
        '---------------\n'
        '${await process.stderr.transform(utf8.decoder).join('')}\n');
  }
  expect(isWebdevGlobalActivated(), isTrue,
      reason: "Webdev should be globally activated, but isn't.");
}

/// Globally deactivates the `webdev` package.
Future<Null> deactivateWebdev() async {
  if (!isWebdevGlobalActivated()) {
    return;
  }
  final process = await Process.start(
    'pub',
    ['global', 'deactivate', 'webdev'],
    mode: ProcessStartMode.normal,
  );
  if (await process.exitCode != 0) {
    fail('Failed to globally deactivate webdev.\n'
        'Process stdout:\n'
        '---------------\n'
        '${await process.stdout.transform(utf8.decoder).join('')}\n'
        'Process stderr:\n'
        '---------------\n'
        '${await process.stderr.transform(utf8.decoder).join('')}\n');
  }
  expect(isWebdevGlobalActivated(), isFalse,
      reason: 'Webdev should not be globally activated, but is.');
}

final webdevGlobalPattern = RegExp(r'webdev [\d.]+');

/// Returns `true` if the `webdev` package is globally activated, and `false`
/// otherwise.
bool isWebdevGlobalActivated() {
  final procResult = Process.runSync(
    'pub',
    ['global', 'list'],
    stdoutEncoding: utf8,
  );
  return procResult.stdout
      .toString()
      .split('\n')
      .any(webdevGlobalPattern.hasMatch);
}
