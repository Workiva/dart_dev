import 'dart:io';

import 'package:path/path.dart' as p;

void assertDirIsDartPackage({String path}) {
  path ??= p.current;
  final pubspec = File(p.join(path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw DirectoryIsNotPubPackage(path);
  }
}

class DirectoryIsNotPubPackage implements Exception {
  final String path;

  DirectoryIsNotPubPackage(this.path);

  @override
  String toString() => 'Could not find a file named "pubspec.yaml" in "$path".';
}
