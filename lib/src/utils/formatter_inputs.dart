import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// Builds and returns the object that contains:
/// - The file paths
/// - The paths that were excluded by an exclude glob
/// - The paths that were skipped because they are links
/// - The hidden directories(start with a '.') that were skipped
///
/// The file paths will include all .dart files in [path] (and its subdirectories),
/// except any paths that match the expanded [exclude] globs.
///
/// By default these globs are assumed to be relative to the current working
/// directory, but that can be overridden via [root] for testing purposes.
FormatterInputs getFormatterInputs({List<Glob> exclude, String root}) {
  FormatterInputs returnInputs = FormatterInputs(Set(), Set(), Set(), Set());

  exclude ??= <Glob>[];

  if (exclude.isEmpty) returnInputs.filesToFormat.add(root ?? '.');

  Directory dir = Directory(root ?? '.');

  for (final entry in dir.listSync(recursive: true, followLinks: false)) {
    String relative = p.relative(entry.path, from: dir.path);
    bool isExcluded = false;

    if (entry is Link) {
      returnInputs.links.add(relative);
      continue;
    }

    if (entry is File && !entry.path.endsWith('.dart')) continue;

    // If the path is in a subdirectory starting with ".", ignore it.
    List<String> parts = p.split(relative);
    int hiddenIndex;
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].startsWith(".")) {
        hiddenIndex = i;
        break;
      }
    }

    if (hiddenIndex != null) {
      final hidden_directory = p.joinAll(parts.take(hiddenIndex + 1));
      returnInputs.hiddenDirectories.add(hidden_directory);
      continue;
    }

    if (exclude.isNotEmpty) {
      for (final glob in exclude) {
        if (glob.matches(relative)) {
          returnInputs.excludedFiles.add(relative);
          isExcluded = true;
          continue;
        }
      }
      if (isExcluded) continue;

      if (entry is File) returnInputs.filesToFormat.add(relative);
    }
  }

  return returnInputs;
}

class FormatterInputs {
  FormatterInputs(this.filesToFormat, this.links, this.excludedFiles,
      this.hiddenDirectories);

  Set<String> filesToFormat;

  Set<String> links;

  Set<String> excludedFiles;

  Set<String> hiddenDirectories;
}
