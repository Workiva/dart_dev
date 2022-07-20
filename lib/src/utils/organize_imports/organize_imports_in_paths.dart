import 'dart:io';

import 'package:io/ansi.dart';

import 'organize_imports.dart';

/// Organizes imports in a list of files and directories.
int organizeImportsInPaths(
  Iterable<String> paths, {
  bool check = false,
  bool verbose = false,
}) {
  final allFiles = _getAllFiles(paths);
  return _organizeImportsInFiles(allFiles, verbose: verbose, check: check);
}

/// Returns all file paths from a given set of files and directories.
Iterable<String> _getAllFiles(Iterable<String> paths) {
  final allFiles = Set<String>();

  for (final path in paths) {
    switch (FileSystemEntity.typeSync(path)) {
      case FileSystemEntityType.directory:
        // skip hidden directories
        if (path.startsWith('.')) {
          continue;
        }
        final children = Directory(path).listSync().map((e) => e.path);
        allFiles.addAll(_getAllFiles(children));
        break;
      case FileSystemEntityType.file:
        if (File(path).path.endsWith('.dart')) {
          allFiles.add(path);
        }
        break;
      case FileSystemEntityType.link:
        // skip links
        break;
      default:
        throw Exception('Unknown FileSystemEntity type encountered');
    }
  }

  return allFiles;
}

/// Organizes imports in a list of files.
int _organizeImportsInFiles(
  Iterable<String> paths, {
  bool verbose = false,
  bool check = false,
}) {
  for (final path in paths) {
    final exitCode =
        _organizeImportsInFile(path, verbose: verbose, check: check);
    if (exitCode != 0) {
      return exitCode;
    }
  }
  return 0;
}

/// Organizes imports in a file.
int _organizeImportsInFile(
  String filePath, {
  bool verbose = false,
  bool check = false,
}) {
  final file = File(filePath);
  final fileContents = _safelyReadFileContents(file);
  if (fileContents == null) {
    return _fail('$filePath not found. Skipping import organization for file.');
  }

  final fileWithOrganizedImports = _safelyOrganizeImports(fileContents);
  if (fileWithOrganizedImports == null) {
    return _fail(
      '$filePath has syntax errors. Please fix syntax errors and try again.',
    );
  }

  final fileChanged = fileWithOrganizedImports != fileContents;
  if (fileChanged && check) {
    return _fail('$filePath has imports that need to be organized.');
  } else if (fileChanged && !_safelyWriteFile(file, fileWithOrganizedImports)) {
    return _fail(
      '$filePath encountered a FileSystemException while writing output.',
    );
  }

  if (verbose && !check) {
    print(green.wrap('$filePath successfully organized imports'));
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

String _safelyOrganizeImports(String fileContents) {
  try {
    return organizeImports(fileContents);
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
