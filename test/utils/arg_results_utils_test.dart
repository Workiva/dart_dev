@TestOn('vm')
import 'package:args/args.dart';
import 'package:dart_dev/src/utils/arg_results_utils.dart';
import 'package:test/test.dart';

void main() {
  group('flagValue', () {
    final flag = 'flag';
    final argParser = ArgParser()..addFlag(flag, defaultsTo: null);

    test('null argResults', () {
      expect(flagValue(null, flag), isNull);
    });

    test('null value', () {
      final argResults = argParser.parse([]);
      expect(flagValue(argResults, flag), isNull);
    });

    test('throws ArgumentError on non-flag value', () {
      final argResults = (ArgParser()..addOption(flag)).parse(['--$flag=foo']);
      expect(() => flagValue(argResults, flag), throwsArgumentError);
    });

    test('returns value as bool', () {
      final argResults = argParser.parse(['--$flag']);
      expect(flagValue(argResults, flag), isTrue);
    });
  });

  group('multiOptionValue', () {
    final opt = 'opt';
    final argParser = ArgParser()..addMultiOption(opt);

    test('null argResults', () {
      expect(multiOptionValue(null, opt), isNull);
    });

    test('throws ArgumentError on non-multi-option value', () {
      final argResults = (ArgParser()..addFlag(opt)).parse(['--$opt']);
      expect(() => multiOptionValue(argResults, opt), throwsArgumentError);
    });

    test('returns value as Iterable<String>', () {
      final argResults = argParser.parse(['--$opt=foo', '--$opt=bar']);
      expect(multiOptionValue(argResults, opt), ['foo', 'bar']);
    });
  });

  group('singleOptionValue', () {
    final opt = 'opt';
    final argParser = ArgParser()..addOption(opt);

    test('null argResults', () {
      expect(singleOptionValue(null, opt), isNull);
    });

    test('null value', () {
      final argResults = argParser.parse([]);
      expect(singleOptionValue(argResults, opt), isNull);
    });

    test('throws ArgumentError on non-single-option value', () {
      final argResults = (ArgParser()..addFlag(opt)).parse(['--$opt']);
      expect(() => singleOptionValue(argResults, opt), throwsArgumentError);
    });

    test('returns value as String', () {
      final argResults = argParser.parse(['--$opt=foo']);
      expect(singleOptionValue(argResults, opt), 'foo');
    });
  });

  group('splitSingleOptionValue', () {
    final opt = 'opt';
    final argParser = ArgParser()..addOption(opt);

    test('null argResults', () {
      expect(splitSingleOptionValue(null, opt), isNull);
    });

    test('null value', () {
      final argResults = argParser.parse([]);
      expect(splitSingleOptionValue(argResults, opt), isNull);
    });

    test('throws ArgumentError on non-single-option value', () {
      final argResults = (ArgParser()..addFlag(opt)).parse(['--$opt']);
      expect(
          () => splitSingleOptionValue(argResults, opt), throwsArgumentError);
    });

    test('returns value as Iterable<String>', () {
      final argResults = argParser.parse(['--$opt=foo bar']);
      expect(splitSingleOptionValue(argResults, opt), ['foo', 'bar']);
    });
  });
}
