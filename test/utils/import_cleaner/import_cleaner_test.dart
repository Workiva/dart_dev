import 'package:dart_dev/src/utils/import_cleaner/import_cleaner.dart';
import 'package:test/test.dart' show group, test, expect, equals;

import '../../tools/fixtures/sort_imports/imports.dart';

void main() {
  const testCases = [
    _TestCase(
        '1. sorts dart imports alphabetically', uncleanImports1, cleanImports1),
    _TestCase(
        '2. sorts pkg imports alphabetically', uncleanImports2, cleanImports2),
    _TestCase('3. sorts relative imports alphabetically', uncleanImports3,
        cleanImports3),
    _TestCase('4. sorts dart above pkg above relative', uncleanImports4,
        cleanImports4),
    _TestCase('5. cleans up double quotes', uncleanImports5, cleanImports5),
    _TestCase('6. ignores imports as variables or strings', uncleanImports6,
        cleanImports6),
    _TestCase('7. joins split line imports (mixed with other imports)',
        uncleanImports7, cleanImports7),
    _TestCase('8. joins split line imports (only split line imports)',
        uncleanImports8, cleanImports8),
    _TestCase('9. does not try to sort library directive or @TestOn',
        uncleanImports9, cleanImports9),
    _TestCase('10. joins split line imports using show/hide', uncleanImports10,
        cleanImports10),
    _TestCase('11. dart, pkg, and relative imports need sorting',
        uncleanImports11, cleanImports11),
    _TestCase(
        '12. relative imports sorted correctly when contains `dart` or `package`',
        uncleanImports12,
        cleanImports12),
    _TestCase('13. preserves comments', uncleanImports13, cleanImports13),
    _TestCase('14. preserves comments trailing semi-colon', uncleanImports14,
        cleanImports14),
    _TestCase('15. preserves comments above import', uncleanImports15,
        cleanImports15),
    _TestCase('16. multiple blank lines between comments', uncleanImports16,
        cleanImports16),
    _TestCase(
        '17. content contains word `import`', uncleanImports17, cleanImports17),
    _TestCase(
        '18. preserves implementation imports comment on single line import',
        uncleanImports18,
        cleanImports18),
    _TestCase('19. multi-line comments', uncleanImports19, cleanImports19),
    _TestCase(
        '20. multi comments on one line', uncleanImports20, cleanImports20),
    _TestCase(
        '21. multiple imports same line', uncleanImports21, cleanImports21),
    _TestCase('22. empty file', uncleanImports22, cleanImports22),
    _TestCase('23. no imports', uncleanImports23, cleanImports23),
    _TestCase('24. comments between imports', uncleanImports24, cleanImports24),
    _TestCase(
        '25. comments contains double quotes', uncleanImports25, cleanImports25)
  ];

  group('cleanImports', () {
    for (final testCase in testCases) {
      test(testCase.description, () {
        expect(
          cleanImports(testCase.unclean),
          equals(testCase.clean),
        );
      });
    }
  });
}

class _TestCase {
  final String description;
  final String unclean;
  final String clean;

  const _TestCase(this.description, this.unclean, this.clean);
}
