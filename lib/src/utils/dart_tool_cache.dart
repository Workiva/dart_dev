import 'dart:io';

import 'package:dart_dev/src/utils/dart_dev_paths.dart';

void createCacheDir({String subPath}) {
  final dir = Directory(DartDevPaths().cache(subPath));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}
