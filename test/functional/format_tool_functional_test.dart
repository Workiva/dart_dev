@TestOn('vm')
@Timeout(Duration(seconds: 20))
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../functional.dart';

void main() {
  group('Format Tool', () {
    Future<_SourceFile> _format(String projectPath) async {
      const filePath = 'lib/main.dart';

      final process = await runDevToolFunctionalTest('format', projectPath);
      await process.shouldExit(0);

      final contentsBefore = File('$projectPath$filePath').readAsStringSync();
      final contentsAfter = File('${d.sandbox}/$filePath').readAsStringSync();
      return _SourceFile(contentsBefore, contentsAfter);
    }

    test('organize imports off', () async {
      const projectPath =
          'test/functional/fixtures/format/unsorted_imports/organize_imports_off/';
      final sourceFile = await _format(projectPath);
      expect(
        sourceFile.contentsBefore,
        equals(sourceFile.contentsAfter),
      );
    });

    test('organize imports on', () async {
      const projectPath =
          'test/functional/fixtures/format/unsorted_imports/organize_imports_on/';
      final sourceFile = await _format(projectPath);
      expect(
        sourceFile.contentsBefore,
        isNot(equals(sourceFile.contentsAfter)),
      );
    });
  });
}

class _SourceFile {
  String contentsBefore;

  String contentsAfter;

  _SourceFile(this.contentsBefore, this.contentsAfter);
}
