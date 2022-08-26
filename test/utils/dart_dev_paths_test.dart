import 'package:dart_dev/src/utils/dart_dev_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DartDevPaths', () {
    group('posix', () {
      DartDevPaths paths;

      setUp(() {
        paths = DartDevPaths(context: p.posix);
      });

      test('cache', () {
        expect(paths.cache(), '.dart_tool/dart_dev');
      });

      test('cache with subpath', () {
        expect(paths.cache('sub/path'), '.dart_tool/dart_dev/sub/path');
      });

      test('config', () {
        expect(paths.config, 'tool/dart_dev/config.dart');
      });

      test('configFromRunScriptForDart', () {
        expect(paths.configFromRunScriptForDart,
            '../../tool/dart_dev/config.dart');
      });

      test('legacyConfig', () {
        expect(paths.legacyConfig, 'tool/dev.dart');
      });

      test('runScript', () {
        expect(paths.runScript, '.dart_tool/dart_dev/run.dart');
      });
    });

    group('windows', () {
      DartDevPaths paths;

      setUp(() {
        paths = DartDevPaths(context: p.windows);
      });

      test('cache', () {
        expect(paths.cache(), r'.dart_tool\dart_dev');
      });

      test('cache with subpath', () {
        expect(paths.cache('sub/path'), r'.dart_tool\dart_dev\sub\path');
      });

      test('config', () {
        expect(paths.config, r'tool\dart_dev\config.dart');
      });

      test('configFromRunScriptForDart', () {
        expect(paths.configFromRunScriptForDart,
            r'../../tool/dart_dev/config.dart');
      });

      test('legacyConfig', () {
        expect(paths.legacyConfig, r'tool\dev.dart');
      });

      test('runScript', () {
        expect(paths.runScript, r'.dart_tool\dart_dev\run.dart');
      });
    });
  });
}
