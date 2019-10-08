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
  final includedFiles = <String>{};
  final excludedFiles = <String>{};
  final skippedLinks = <String>{};
  final hiddenDirectories = <String>{};

  exclude ??= <Glob>[];

  if (exclude.isEmpty) {
    return FormatterInputs({'.'});
  }

  Directory dir = Directory(root ?? '.');

  for (final entry in dir.listSync(recursive: true, followLinks: false)) {
    String relative = p.relative(entry.path, from: dir.path);

    if (entry is Link) {
      skippedLinks.add(relative);
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
      final hiddenDirectory = p.joinAll(parts.take(hiddenIndex + 1));
      hiddenDirectories.add(hiddenDirectory);
      continue;
    }

    if (exclude.any((glob) => glob.matches(relative))) {
      excludedFiles.add(relative);
    } else {
      if (entry is File) includedFiles.add(relative);
    }
  }

  return FormatterInputs(includedFiles,
      excludedFiles: excludedFiles,
      skippedLinks: skippedLinks,
      hiddenDirectories: hiddenDirectories);
}

class FormatterInputs {
  FormatterInputs(this.includedFiles,
      {this.skippedLinks, this.excludedFiles, this.hiddenDirectories});

  final Set<String> includedFiles;

  final Set<String> skippedLinks;

  final Set<String> excludedFiles;

  final Set<String> hiddenDirectories;
}
