import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

Pubspec cachedPubspec({String path}) {
  final sourceUrl = p.join(path ?? p.current, 'pubspec.yaml');
  _cachedPubspecs.putIfAbsent(
      sourceUrl,
      () => Pubspec.parse(File(sourceUrl).readAsStringSync(),
          sourceUrl: sourceUrl));
  return _cachedPubspecs[sourceUrl];
}

final _cachedPubspecs = <String, Pubspec>{};
