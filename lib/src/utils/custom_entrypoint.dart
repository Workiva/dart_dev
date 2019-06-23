import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dart_dev/src/utils/dart_tool_cache.dart';

const _devDartPath = 'tool/dev.dart';
final _customEntrypointPath = p.join(cacheDirPath, 'custom_executable.dart');
final _customEntrypoint = File(_customEntrypointPath);
final _relativeDevDartPath = p.relative(
  p.absolute(_devDartPath),
  from: p.absolute(p.dirname(_customEntrypointPath)),
);
final _customEntrypointContents = '''
import 'dart:io';

import 'package:dart_dev/src/executable.dart' as executable;
import '$_relativeDevDartPath' as custom_dev;

void main(List<String> args) async {
  exit(await executable.runWithConfig(args, () => custom_dev.config));
}
''';

void _generateCustomEntrypoint() {
  if (_shouldWriteCustomEntrypoint()) {
    createCacheDir();
    _customEntrypoint.writeAsStringSync(_customEntrypointContents);
  }
}

bool _shouldWriteCustomEntrypoint() {
  return !_customEntrypoint.existsSync() ||
      _customEntrypoint.readAsStringSync() != _customEntrypointContents;
}

Future<int> runViaCustomEntrypoint(List<String> args) async {
  _generateCustomEntrypoint();
  final process = await Process.start(
      Platform.executable,
      [
        _customEntrypointPath,
        ...args,
      ],
      mode: ProcessStartMode.inheritStdio);
  return process.exitCode;
}
