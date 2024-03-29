import 'package:dart_dev/src/dart_dev_tool.dart';
import 'package:test/test.dart';

void sharedDevToolTests(DevTool Function() factory) {
  group('toCommand', () {
    test('should return a command with the given name', () {
      expect(factory().toCommand('custom_command').name, 'custom_command');
    });

    test('should return a command with a customizable description', () {
      expect((factory()..description = 'desc').toCommand('test').description,
          'desc');
    });

    test('should return a command with a customizable hidden value', () {
      expect((factory()..hidden = false).toCommand('test').hidden, isFalse);
      expect((factory()..hidden = true).toCommand('test').hidden, isTrue);
    });
  });
}
