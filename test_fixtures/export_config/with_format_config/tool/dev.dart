import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.format
    ..lineLength = 1234
    ..exclude = [
      'foo',
      'bar',
    ];
  await dev(args);
}
