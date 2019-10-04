import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// Builds and returns the list of inputs on which the formatter should be run.
///
/// These inputs are determined by expanding the [include] globs and filtering
/// out any paths that match the expanded [exclude] globs.
///
/// Logs may be output in certain scenarios for debugging purposes.
///
/// By default these globs are assumed to be relative to the current working
/// directory, but that can be overridden via [root] for testing purposes.
Map<String, dynamic> buildInputs(
    {List<Glob> exclude, List<Glob> include, String root}) {
  Map<String, dynamic> returnInputs = {
    'files': <String>[],
    'skipped': {
      'links': <String>[],
      'excluded': <String>[],
      'hidden_directories': Set<String>(),
    },
  };

  exclude ??= <Glob>[];
  include ??= <Glob>[];
  Directory dir = Directory(root ?? '.');
  for (final entry in dir.listSync(recursive: true, followLinks: false)) {
    String relative = p.relative(entry.path, from: dir.path);
    bool isExcluded = false;

    if (entry is Link) {
      returnInputs['skipped']['links'].add(relative);
      continue;
    }

    for (final glob in exclude) {
      if (glob.matches(relative)) {
        returnInputs['skipped']['excluded'].add(relative);
        isExcluded = true;
        continue;
      }
    }
    if (isExcluded) continue;

    if (entry is! File || !entry.path.endsWith('.dart')) continue;

    // If subdirectory starts with ".", ignore it.\
    if (relative.startsWith('.')) {
      final hidden_directory = p.split(relative)[0];
      returnInputs['skipped']['hidden_directories'].add(hidden_directory);
      continue;
    }

    if (entry.path.endsWith('.dart')) {
      returnInputs['files'].add(relative);
    }
  }
  return returnInputs;
}
