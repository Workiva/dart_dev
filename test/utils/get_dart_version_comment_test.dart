@TestOn('vm')
import 'package:dart_dev/src/utils/get_dart_version_comment.dart';
import 'package:test/test.dart';

void main() {
  group('getDartVersionComment returns the version comment in a Dart file', () {
    test('', () {
      expect(
          getDartVersionComment([
            '//@dart=2.9',
            '',
            'main() {}',
          ].join('\n')),
          '//@dart=2.9');
    });

    test('allowing for whitespace', () {
      expect(getDartVersionComment('//@dart=2.9'), '//@dart=2.9');
      expect(
          getDartVersionComment('//  @dart  =  2.9  '), '//  @dart  =  2.9  ');
    });

    test('regardless of which line it appears on', () {
      expect(getDartVersionComment('\n\n//@dart=2.9\n\n'), '//@dart=2.9');
    });

    test(
        'ignores version comments that don\'t start at the beginning of the line',
        () {
      const wellFormedVersionComment = '//@dart=2.9';
      expect(getDartVersionComment(wellFormedVersionComment), isNotNull,
          reason: 'test setup check');

      expect(getDartVersionComment(' $wellFormedVersionComment'), isNull);
      expect(getDartVersionComment('"$wellFormedVersionComment"'), isNull);
    });

    test('ignores incomplete version comments', () {
      expect(getDartVersionComment('//@dart='), isNull);
    });
  });
}
