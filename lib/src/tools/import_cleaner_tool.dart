import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:io/ansi.dart';

import '../utils/import_cleaner/import_cleaner.dart';

class ImportCleanerTool extends DevTool {
  int _exitCode = 0;

  @override
  final ArgParser argParser = ArgParser(allowTrailingOptions: true)
    ..addSeparator('======== Import Cleaner')
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Provide verbose output',
    )
    ..addMultiOption(
      'files',
      abbr: 'f',
      help: 'Files to sort imports on',
    )
    ..addFlag(
      'check',
      abbr: 'c',
      negatable: false,
      help: 'Check if changes need to be made and sets the exit code.',
    );

  @override
  FutureOr<int> run([DevToolExecutionContext context]) async {
    final parsed = context.argResults;

    final targetFiles = parsed['files'] as List<String>;
    final filesToSort = _getSortableFiles(targetFiles);

    _sortImports(
      filesToSort,
      verbose: parsed['verbose'] as bool,
      check: parsed['check'] as bool,
    );
    return _exitCode;
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

  void _sortImports(Iterable<String> paths,
      {bool verbose = false, bool check = false}) {
    for (final path in paths) {
      _sortImportsInFile(path, verbose: verbose, check: check);
    }
  }

  void _sortImportsInFile(
    String filePath, {
    bool verbose = false,
    bool check = false,
  }) {
    final file = File(filePath);
    final fileContents = _safelyReadFileContents(file);
    if (fileContents == null) {
      _fail('$filePath not found. Skipping import sort for file.');
      return;
    }

    final fileWithSortedImports = _safelyCleanImports(fileContents);
    if (fileWithSortedImports == null) {
      _fail(
          '$filePath has syntax errors. Please fix syntax errors and try again.');
      return;
    }

    final fileChanged = fileWithSortedImports != fileContents;
    if (fileChanged && check) {
      _fail('$filePath has imports that need to be sorted.');
    } else if (fileChanged && !_safelyWriteFile(file, fileWithSortedImports)) {
      _fail(
          '$filePath encountered a FileSystemException while writing output.');
      return;
    }

    if (verbose && !check) {
      print(green.wrap('$filePath successfully sorted imports'));
    }
  }

  void _fail(String message) {
    _exitCode = 1;
    print(red.wrap(message));
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
}
