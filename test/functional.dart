import 'dart:async';
import 'dart:io';

import 'package:dart_dev/src/utils/executables.dart' as exe;
import 'package:path/path.dart' as p;
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

Future<TestProcess> runDevToolFunctionalTest(
    String command, String projectTemplatePath,
    {List<String> args, bool verbose}) async {
  // Setup a temporary directory on which this tool will be run, using the given
  // project template as a starting point.
  final templateDir = Directory(projectTemplatePath);
  if (!templateDir.existsSync()) {
    throw ArgumentError(
        'projectTemplatePath does not exist: $projectTemplatePath');
  }

  final templateFiles = templateDir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.absolute);
  for (final file in templateFiles) {
    final target =
        p.join(d.sandbox, p.relative(file.path, from: templateDir.path));
    Directory(p.dirname(target)).createSync(recursive: true);
    file.copySync(target);
  }

  final pubspecs = Directory(d.sandbox)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => p.basename(f.path) == 'pubspec.yaml')
      .map((f) => f.absolute);
  final pathDepPattern = RegExp(r'path: (.*)');
  // pubspec paths are always posix style
  var context = p.Context(style: p.Style.posix);
  for (final pubspec in pubspecs) {
    final updated =
        pubspec.readAsStringSync().replaceAllMapped(pathDepPattern, (match) {
      final relDepPath = match.group(1);
      final relPubspecPath = context.relative(pubspec.path, from: d.sandbox);
      final absPath = context.absolute(context.normalize(
          context.join(templateDir.path, relPubspecPath, relDepPath, '..')));
      return 'path: $absPath';
    });
    pubspec.writeAsStringSync(updated);

    final result = Process.runSync(exe.dart, ['pub', 'get'],
        workingDirectory: pubspec.parent.path);
    if (result.exitCode != 0) {
      final origPath = p.join(p.relative(templateDir.absolute.path),
          p.relative(pubspec.absolute.path, from: d.sandbox));
      throw StateError('dart pub get failed on: $origPath\n'
          'STDOUT:\n${result.stdout}\n'
          'STDERR:\n${result.stderr}\n');
    }
  }

  final allArgs = <String>['run', 'dart_dev', command, ...?args];
  return TestProcess.start(exe.dart, allArgs, workingDirectory: d.sandbox);
}
