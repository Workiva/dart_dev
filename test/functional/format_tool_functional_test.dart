@TestOn('vm')
@Timeout(Duration(seconds: 20))
import 'dart:io';

import 'package:dart_dev/src/utils/dart_semver_version.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../functional.dart';

void main() {
  group('Format Tool', () {
    Future<_SourceFile> format(String projectPath) async {
      const filePath = 'lib/main.dart';

      final process = await runDevToolFunctionalTest('format', projectPath);
      await process.shouldExit(0);

      final contentsBefore = File('$projectPath$filePath').readAsStringSync();
      final contentsAfter = File('${d.sandbox}/$filePath').readAsStringSync();
      return _SourceFile(contentsBefore, contentsAfter);
    }

    test('organize directives off', () async {
      const projectPath =
          'test/functional/fixtures/format/unsorted_imports/organize_directives_off/';
      final sourceFile = await format(projectPath);
      expect(sourceFile.contentsBefore, equals(sourceFile.contentsAfter));
    });

    test('organize directives on', () async {
      const projectPath =
          'test/functional/fixtures/format/unsorted_imports/organize_directives_on/';
      final sourceFile = await format(projectPath);
      expect(
        sourceFile.contentsBefore,
        isNot(equals(sourceFile.contentsAfter)),
      );
    });

    test(
      'passes configured languageVersion to dart format when supported',
      () async {
        const projectPath =
            'test/functional/fixtures/format/language_version/dart_format_configured/';

        final process = await runDevToolFunctionalTest('format', projectPath);
        final stdoutFuture = process.stdoutStream().toList();

        await process.shouldExit(0);

        final stdout = (await stdoutFuture).join('\n');
        final expectedCommandPattern = RegExp(
          [
            RegExp.escape('dart format'),
            if (dartSemverVersion.major >= 3)
              RegExp.escape('--language-version=3.0'),
            r'lib[\\/]main\.dart',
          ].join(r'\s+'),
        );

        expect(stdout, contains(expectedCommandPattern));
      },
    );
  });
}

class _SourceFile {
  String contentsBefore;

  String contentsAfter;

  _SourceFile(this.contentsBefore, this.contentsAfter);
}
