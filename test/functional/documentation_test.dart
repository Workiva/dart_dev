/// Scans the project for Dart code blocks in markdown files and runs static
/// analysis on each to ensure that all of our documentation is valid.
///
/// To opt out of this, add `test=false` to the opening code fence:
///
///     ```dart test=false
///     // Code that we know won't statically analyze...
///     ```
@TestOn('vm')
@Timeout(Duration(seconds: 10))
library test.functional.documentation_test;

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

void main() {
  for (final dartBlock in getDartBlocks()) {
    test('${dartBlock.sourceUrl} (block #${dartBlock.index})', () async {
      final pubspecSource = pubspecWithPackages(dartBlock.packages);
      await d.dir('project', [
        d.file('doc.dart', dartBlock.source),
        d.file('pubspec.yaml', pubspecSource),
      ]).create();

      final pubGet = await TestProcess.start('pub', ['get'],
          workingDirectory: '${d.sandbox}/project');
      printOnFailure('PUBSPEC:\n$pubspecSource\n');
      await pubGet.shouldExit(0);

      final analysis = await TestProcess.start('dartanalyzer',
          ['.', '--fatal-lints', '--fatal-infos', '--fatal-warnings'],
          workingDirectory: '${d.sandbox}/project');
      printOnFailure('SOURCE:\n${dartBlock.source}\n');
      await analysis.shouldExit(0);
    });
  }
}

Iterable<DartBlock> getDartBlocks() sync* {
  final dartBlockPattern =
      RegExp(r'^```dart *([^\n]*)([^`]*)^```', multiLine: true);
  for (final file in Glob('**.md').listSync().whereType<File>()) {
    final source = file.readAsStringSync();
    var i = 1;
    for (final match in dartBlockPattern.allMatches(source)) {
      final params = match.group(1).split(' ');
      if (params.contains('test=false')) continue;
      yield DartBlock.fromSource(match.group(1), file.path, i++);
    }
  }
}

String pubspecWithPackages(Set<String> packages) {
  final buffer = StringBuffer()
    ..writeln('name: doc_test')
    ..writeln('dependencies:');
  for (final package in packages) {
    var constraint =
        package == 'dart_dev' ? '\n    path: ${p.current}' : ' any';
    buffer.writeln('  $package:$constraint');
  }
  return buffer.toString();
}

class DartBlock {
  final int index;
  final Set<String> packages;
  final String source;
  final String sourceUrl;

  DartBlock.fromSource(this.source, this.sourceUrl, this.index)
      : packages = parsePackagesFromSource(source);

  static Set<String> parsePackagesFromSource(String source) {
    final packagePattern = RegExp(r'''['"]package:(\w+)\/.*['"]''');
    return Set.of(
        packagePattern.allMatches(source).map((match) => match.group(1)));
  }
}
