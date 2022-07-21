import 'package:dart_dev/src/utils/organize_directives/organize_directives.dart';
import 'package:test/test.dart' show group, test, expect, equals;

import '../../tools/fixtures/organize_directives/directives.dart';

void main() {
  const testCases = [
    _TestCase(
      '1. sorts dart imports alphabetically',
      unorganized1,
      organized1,
    ),
    _TestCase(
      '2. sorts pkg imports alphabetically',
      unorganized2,
      organized2,
    ),
    _TestCase(
      '3. sorts relative imports alphabetically',
      unorganized3,
      organized3,
    ),
    _TestCase(
      '4. sorts dart above pkg above relative',
      unorganized4,
      organized4,
    ),
    _TestCase('5. cleans up double quotes', unorganized5, organized5),
    _TestCase(
      '6. ignores imports as variables or strings',
      unorganized6,
      organized6,
    ),
    _TestCase(
      '7. joins split line imports (mixed with other imports)',
      unorganized7,
      organized7,
    ),
    _TestCase(
      '8. joins split line imports (only split line imports)',
      unorganized8,
      organized8,
    ),
    _TestCase(
      '9. does not try to sort library directive or @TestOn',
      unorganized9,
      organized9,
    ),
    _TestCase(
      '10. joins split line imports using show/hide',
      unorganized10,
      organized10,
    ),
    _TestCase(
      '11. dart, pkg, and relative imports need sorting',
      unorganized11,
      organized11,
    ),
    _TestCase(
      '12. relative imports sorted correctly when contains `dart` or `package`',
      unorganized12,
      organized12,
    ),
    _TestCase('13. preserves comments', unorganized13, organized13),
    _TestCase(
      '14. preserves comments trailing semi-colon',
      unorganized14,
      organized14,
    ),
    _TestCase(
      '15. preserves comments above import',
      unorganized15,
      organized15,
    ),
    _TestCase(
      '16. multiple blank lines between comments',
      unorganized16,
      organized16,
    ),
    _TestCase('17. content contains word `import`', unorganized17, organized17),
    _TestCase(
      '18. preserves implementation imports comment on single line import',
      unorganized18,
      organized18,
    ),
    _TestCase('19. multi-line comments', unorganized19, organized19),
    _TestCase('20. multi comments on one line', unorganized20, organized20),
    _TestCase('21. multiple imports same line', unorganized21, organized21),
    _TestCase('22. empty file', unorganized22, organized22),
    _TestCase('23. no imports', unorganized23, organized23),
    _TestCase('24. comments between imports', unorganized24, organized24),
    _TestCase(
      '25. comments contains double quotes',
      unorganized25,
      organized25,
    ),
    _TestCase('26. exports', unorganized26, organized26),
    _TestCase('27. exports using show/hide', unorganized27, organized27),
    _TestCase('28. mixed imports and exports', unorganized28, organized28),
    _TestCase(
      '29. unnecessary new lines between imports and exports',
      unorganized29,
      organized29,
    ),
    _TestCase(
      '30. unnecessary new lines between all imports and exports',
      unorganized30,
      organized30,
    ),
    _TestCase('31. comments with exports', unorganized31, organized31),
  ];

  group('organizeDirectives', () {
    for (final testCase in testCases) {
      test(testCase.description, () {
        expect(
          organizeDirectives(testCase.unorganized),
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
