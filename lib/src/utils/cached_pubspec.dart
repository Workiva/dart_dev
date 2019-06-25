import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

Pubspec cachedPubspec({String path}) {
  final sourceUrl = p.join(path ?? p.current, 'pubspec.yaml');
  _pubspec ??=
      Pubspec.parse(File(sourceUrl).readAsStringSync(), sourceUrl: sourceUrl);
  return _pubspec;
}

Pubspec _pubspec;
