@TestOn('vm')
import 'package:args/args.dart';
import 'package:dart_dev/src/utils/assert_no_positional_args_before_separator.dart';
import 'package:test/test.dart';

void main() {
  final commandName = 'test';
  bool beforeSeparator = false;
  late bool usageExceptionCalled;
  void usageException(String msg) {
    usageExceptionCalled = true;
    expect(msg, contains('The "$commandName" command'));
    if (beforeSeparator) {
      expect(msg, contains('before the `--` separator'));
    } else {
      expect(msg, isNot(contains('before the `--` separator')));
    }
  }

  setUp(() {
    beforeSeparator = false;
    usageExceptionCalled = false;
  });

  test('calls usageException callback if assertion fails', () {
    final argResults = ArgParser().parse(['positional', 'args']);
    assertNoPositionalArgs(commandName, argResults, usageException);
    expect(usageExceptionCalled, isTrue);
  });

  test(
      'calls usageException callback if assertion fails (beforeSeparator=true)',
      () {
    final argResults = ArgParser().parse(['positional', 'args']);
    beforeSeparator = true;
    assertNoPositionalArgs(commandName, argResults, usageException,
        beforeSeparator: true);
    expect(usageExceptionCalled, isTrue);
  });

  test('does not call usageException callback if assertion passes', () {
    final argResults = ArgParser().parse([]);
    assertNoPositionalArgs(commandName, argResults, usageException);
    expect(usageExceptionCalled, isFalse);
  });
}
