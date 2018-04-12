import 'package:test/test.dart';

final bool wasTransformed = false;

void main() {
  test('passes', () {
    expect(wasTransformed, isTrue);
  });
}
