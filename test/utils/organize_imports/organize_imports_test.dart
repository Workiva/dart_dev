import 'package:dart_dev/src/utils/organize_imports/organize_imports.dart';
import 'package:test/test.dart' show group, test, expect, equals;

import '../../tools/fixtures/organize_imports/imports.dart';

void main() {
  const testCases = [
    _TestCase(
      '1. sorts dart imports alphabetically',
      unorganizedImports1,
      organizedImports1,
    ),
    _TestCase(
      '2. sorts pkg imports alphabetically',
      unorganizedImports2,
      organizedImports2,
    ),
    _TestCase(
      '3. sorts relative imports alphabetically',
      unorganizedImports3,
      organizedImports3,
    ),
    _TestCase(
      '4. sorts dart above pkg above relative',
      unorganizedImports4,
      organizedImports4,
    ),
    _TestCase(
      '5. cleans up double quotes',
      unorganizedImports5,
      organizedImports5,
    ),
    _TestCase(
      '6. ignores imports as variables or strings',
      unorganizedImports6,
      organizedImports6,
    ),
    _TestCase(
      '7. joins split line imports (mixed with other imports)',
      unorganizedImports7,
      organizedImports7,
    ),
    _TestCase(
      '8. joins split line imports (only split line imports)',
      unorganizedImports8,
      organizedImports8,
    ),
    _TestCase(
      '9. does not try to sort library directive or @TestOn',
      unorganizedImports9,
      organizedImports9,
    ),
    _TestCase(
      '10. joins split line imports using show/hide',
      unorganizedImports10,
      organizedImports10,
    ),
    _TestCase(
      '11. dart, pkg, and relative imports need sorting',
      unorganizedImports11,
      organizedImports11,
    ),
    _TestCase(
      '12. relative imports sorted correctly when contains `dart` or `package`',
      unorganizedImports12,
      organizedImports12,
    ),
    _TestCase(
      '13. preserves comments',
      unorganizedImports13,
      organizedImports13,
    ),
    _TestCase(
      '14. preserves comments trailing semi-colon',
      unorganizedImports14,
      organizedImports14,
    ),
    _TestCase(
      '15. preserves comments above import',
      unorganizedImports15,
      organizedImports15,
    ),
    _TestCase(
      '16. multiple blank lines between comments',
      unorganizedImports16,
      organizedImports16,
    ),
    _TestCase(
      '17. content contains word `import`',
      unorganizedImports17,
      organizedImports17,
    ),
    _TestCase(
      '18. preserves implementation imports comment on single line import',
      unorganizedImports18,
      organizedImports18,
    ),
    _TestCase(
      '19. multi-line comments',
      unorganizedImports19,
      organizedImports19,
    ),
    _TestCase(
      '20. multi comments on one line',
      unorganizedImports20,
      organizedImports20,
    ),
    _TestCase(
      '21. multiple imports same line',
      unorganizedImports21,
      organizedImports21,
    ),
    _TestCase('22. empty file', unorganizedImports22, organizedImports22),
    _TestCase('23. no imports', unorganizedImports23, organizedImports23),
    _TestCase(
      '24. comments between imports',
      unorganizedImports24,
      organizedImports24,
    ),
    _TestCase(
      '25. comments contains double quotes',
      unorganizedImports25,
      organizedImports25,
    ),
    _TestCase('26. exports', unorganizedImports26, organizedImports26),
    _TestCase(
      '27. exports using show/hide',
      unorganizedImports27,
      organizedImports27,
    ),
    _TestCase(
      '28. mixed imports and exports',
      unorganizedImports28,
      organizedImports28,
    ),
    _TestCase(
      '29. unnecessary new lines between imports and exports',
      unorganizedImports29,
      organizedImports29,
    ),
    _TestCase(
      '30. unnecessary new lines between all imports and exports',
      unorganizedImports30,
      organizedImports30,
    ),
    _TestCase(
      '31. comments with exports',
      unorganizedImports31,
      organizedImports31,
    ),
  ];

  group('organizeImports', () {
    for (final testCase in testCases) {
      test(testCase.description, () {
        expect(
          organizeImports(testCase.unorganized),
          equals(testCase.organized),
        );
      });
    }
  });
}

class _TestCase {
  final String description;
  final String unorganized;
  final String organized;

  const _TestCase(this.description, this.unorganized, this.organized);
}
