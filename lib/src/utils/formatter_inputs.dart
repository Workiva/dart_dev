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
  FormatterInputs inputs = FormatterInputs(Set(), Set(), Set(), Set());

  exclude ??= <Glob>[];

  if (exclude.isEmpty) inputs.includedFiles.add(root ?? '.');

  Directory dir = Directory(root ?? '.');

  for (final entry in dir.listSync(recursive: true, followLinks: false)) {
    String relative = p.relative(entry.path, from: dir.path);

    if (entry is Link) {
      inputs.links.add(relative);
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
      inputs.hiddenDirectories.add(hiddenDirectory);
      continue;
    }

    if (exclude.isNotEmpty) {
      if (exclude.any((glob) => glob.matches(relative))) {
        inputs.excludedFiles.add(relative);
      } else {
        if (entry is File) inputs.includedFiles.add(relative);
      }
    }
  }

  return inputs;
}

class FormatterInputs {
  FormatterInputs(this.includedFiles, this.links, this.excludedFiles,
      this.hiddenDirectories);

  final Set<String> includedFiles;

  final Set<String> links;

  final Set<String> excludedFiles;

  final Set<String> hiddenDirectories;
}
