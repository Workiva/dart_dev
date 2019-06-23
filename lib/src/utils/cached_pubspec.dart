import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';

Pubspec cachedPubspec({String path}) {
  _pubspec ??= Pubspec.parse(loadYaml(
      File(p.join(path ?? p.current, 'pubspec.yaml')).readAsStringSync()));
  return _pubspec;
}

Pubspec _pubspec;
