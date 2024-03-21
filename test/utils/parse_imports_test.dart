import 'package:dart_dev/src/utils/parse_imports.dart';
import 'package:test/test.dart';

void main() {
  final expectedImportList = [
    'dart:async',
    'dart:convert',
    'dart:io',
    'package:analyzer/dart/analysis/utilities.dart',
    'package:dart_dev/dart_dev.dart',
    'package:dart_dev/src/tools/over_react_format_tool.dart',
    'package:dart_dev/src/utils/format_tool_builder.dart',
    'package:test/test.dart',
    'utils/assert_dir_is_dart_package.dart',
    'utils/cached_pubspec.dart',
    'utils/dart_dev_paths.dart',
  ];
  group(
      'parseImports',
      () => test('correctly returns all imports',
          () => expect(parseImports(sampleFile), equals(expectedImportList))));

  group(
      'computePackageNamesFromImports',
      () => test(
          'correctly computes package names from imports',
          () => expect(computePackageNamesFromImports(expectedImportList),
              equals(['analyzer', 'dart_dev', 'test']))));
}

const sampleFile = '''
@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/tools/over_react_format_tool.dart';
import 'package:dart_dev/src/utils/format_tool_builder.dart';
import 'package:test/test.dart';

import 'utils/assert_dir_is_dart_package.dart';
import 'utils/cached_pubspec.dart';
import 'utils/dart_dev_paths.dart';

void main() {
  group('FormatToolBuilder', () {
    group('detects an OverReactFormatTool correctly', () {
      test('when the tool is a MethodInvocation', () {
        final visitor = FormatToolBuilder();

        parseString(content: orfNoCascadeSrc).unit.accept(visitor);

        expect(visitor.formatDevTool, isNotNull);
        expect(visitor.formatDevTool, isA<OverReactFormatTool>());
      });
    });
  });
}
''';
