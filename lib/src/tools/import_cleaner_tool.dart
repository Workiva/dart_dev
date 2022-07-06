import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:io/ansi.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

import '../utils/import_cleaner/import_cleaner.dart';

class ImportCleanerTool extends DevTool {
  List<Glob> directoriesToInclude;
  int _exitCode = 0;
  String packageName;

  @override
  final ArgParser argParser = ArgParser(allowTrailingOptions: true)
    ..addSeparator('======== Import Cleaner')
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Provide verbose output',
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

    final globs = directoriesToInclude
        .map((glob) => glob.listSync())
        .expand((i) => i)
        .toList();

    final targetFiles = <String>[];
    for (final glob in globs) {
      targetFiles.add(glob.path);
    }

    _sortImports(targetFiles,
        verbose: parsed['verbose'] as bool, check: parsed['check'] as bool);
    return _exitCode;
  }

  void _sortImports(List<String> paths,
      {bool verbose = false, bool check = false}) {
    for (final path in paths) {
      _sortImportsInFile(path, verbose: verbose, check: check);
    }
  }

  void _sortImportsInFile(String filePath,
      {bool verbose = false, bool check = false}) {
    final file = File(filePath);
    final fileContents = _safelyReadFileContents(file);
    if (fileContents == null) {
      _fail('$filePath not found. Skipping format for file.');
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
      return cleanImports(fileContents, currentPackageName: this.packageName);
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
