import 'dart:io';

import 'package:io/ansi.dart';

import '../utils/import_cleaner/import_cleaner.dart';

int organizeImports(
  Iterable<String> targetFiles, {
  bool check = false,
  bool verbose = false,
}) {
  final filesToSort = _getSortableFiles(targetFiles);
  return _sortImports(filesToSort, verbose: verbose, check: check);
}

Iterable<String> _getSortableFiles(Iterable<String> filePaths) {
  final sortableFiles = Set<String>();

  for (final path in filePaths) {
    switch (FileSystemEntity.typeSync(path)) {
      case FileSystemEntityType.directory:
        // skip hidden directories
        if (path.startsWith('.')) {
          continue;
        }
        final children = Directory(path).listSync().map((e) => e.path);
        sortableFiles.addAll(_getSortableFiles(children));
        break;
      case FileSystemEntityType.file:
        if (File(path).path.endsWith('.dart')) {
          sortableFiles.add(path);
        }
        break;
      case FileSystemEntityType.link:
        // skip links
        break;
      default:
        throw Exception('Unknown FileSystemEntity type encountered');
    }
  }

  return sortableFiles;
}

int _sortImports(
  Iterable<String> paths, {
  bool verbose = false,
  bool check = false,
}) {
  for (final path in paths) {
    final exitCode = _sortImportsInFile(path, verbose: verbose, check: check);
    if (exitCode != 0) {
      return exitCode;
    }
  }
  return 0;
}

int _sortImportsInFile(
  String filePath, {
  bool verbose = false,
  bool check = false,
}) {
  final file = File(filePath);
  final fileContents = _safelyReadFileContents(file);
  if (fileContents == null) {
    return _fail('$filePath not found. Skipping import sort for file.');
  }

  final fileWithSortedImports = _safelyCleanImports(fileContents);
  if (fileWithSortedImports == null) {
    return _fail(
      '$filePath has syntax errors. Please fix syntax errors and try again.',
    );
  }

  final fileChanged = fileWithSortedImports != fileContents;
  if (fileChanged && check) {
    return _fail('$filePath has imports that need to be sorted.');
  } else if (fileChanged && !_safelyWriteFile(file, fileWithSortedImports)) {
    return _fail(
      '$filePath encountered a FileSystemException while writing output.',
    );
  }

  if (verbose && !check) {
    print(green.wrap('$filePath successfully sorted imports'));
  }

  return 0;
}

int _fail(String message) {
  print(red.wrap(message));
  return 1;
}

String _safelyReadFileContents(File file) {
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return null;
  }
}

String _safelyCleanImports(String fileContents) {
  try {
    return cleanImports(fileContents);
  } on ArgumentError {
    return null;
  }
}

bool _safelyWriteFile(File file, String fileContents) {
  try {
    file.writeAsStringSync(fileContents);
    return true;
  } on FileSystemException {
    return false;
  }
}
