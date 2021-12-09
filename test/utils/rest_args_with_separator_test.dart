import 'package:args/args.dart';
import 'package:dart_dev/src/utils/rest_args_with_separator.dart';
import 'package:test/test.dart';

void main() {
  group('restArgsWithSeparator', () {
    ArgParser parser;

    setUp(() {
      parser = ArgParser()
        ..addOption('output', abbr: 'o')
        ..addFlag('verbose', abbr: 'v');
    });

    test('with no args', () {
      final results = parser.parse([]);
      expect(restArgsWithSeparator(results), <String>[]);
    });

    test('restores the separator to the correct spot', () {
      final results = parser.parse([
        'a',
        '-o',
        'out',
        '-v',
        'b',
        '--',
        'c',
        '-d',
      ]);
      expect(restArgsWithSeparator(results), [
        'a',
        'b',
        '--',
        'c',
        '-d',
      ]);
    });

    test('with multiple separators', () {
      final results = parser
          .parse(['a', '-o', 'out', '-v', 'b', '--', 'c', '-d', '--', 'e']);
      expect(restArgsWithSeparator(results), [
        'a',
        'b',
        '--',
        'c',
        '-d',
        '--',
        'e',
      ]);
    });
  });
}
