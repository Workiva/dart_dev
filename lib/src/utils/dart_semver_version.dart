import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

final versionPattern = RegExp(r'(\d+.\d+.\d+)');

Version get dartSemverVersion =>
    Version.parse(versionPattern.firstMatch(Platform.version).group(1));

bool get dartVersionHasDartanalyzer =>
    dartSemverVersion < Version.parse('2.18.0');

bool get dartVersionHasDartfmt => dartSemverVersion < Version.parse('2.15.0');
