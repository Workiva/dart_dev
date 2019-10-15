import 'dart:async';
import 'dart:io';

import 'package:matcher/matcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<DevToolFunctionalTestResult> runDevToolFunctionalTest(
    String command, String projectTemplatePath,
    {List<String> args, bool verbose}) async {
  // Setup a temporary directory on which this tool will be run, using the given
  // project template as a starting point.
  final templateDir = Directory(projectTemplatePath);
  if (!templateDir.existsSync()) {
    throw ArgumentError(
        'projectTemplatePath does not exist: $projectTemplatePath');
  }
  final tempDir =
      Directory.systemTemp.createTempSync('func_dev_tool_test_').absolute;
  addTearDown(() => tempDir.delete(recursive: true));
  final templateFiles = templateDir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.absolute);
  for (final file in templateFiles) {
    final target =
        p.join(tempDir.path, p.relative(file.path, from: templateDir.path));
    Directory(p.dirname(target)).createSync(recursive: true);
    file.copySync(target);
  }
  final pubspecs = tempDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => p.basename(f.path) == 'pubspec.yaml')
      .map((f) => f.absolute);
  final pathDepPattern = RegExp(r'path: (.*)');
  for (final pubspec in pubspecs) {
    final updated =
        pubspec.readAsStringSync().replaceAllMapped(pathDepPattern, (match) {
      final relDepPath = match.group(1);
      final relPubspecPath = p.relative(pubspec.path, from: tempDir.path);
      final absPath = p.absolute(p.normalize(
          p.join(templateDir.path, relPubspecPath, relDepPath, '..')));
      return 'path: $absPath';
    });
    pubspec.writeAsStringSync(updated);

    final result =
        Process.runSync('pub', ['get'], workingDirectory: pubspec.parent.path);
    if (result.exitCode != 0) {
      final origPath = p.join(p.relative(templateDir.absolute.path),
          p.relative(pubspec.absolute.path, from: tempDir.absolute.path));
      throw StateError('pub get failed on: $origPath\n'
          'STDOUT:\n${result.stdout}\n'
          'STDERR:\n${result.stderr}\n');
    }
  }

  final args = <String>['run', 'dart_dev', ...command.split(' ')];
  final result =
      await Process.run('pub', args, workingDirectory: tempDir.absolute.path);
  printOnFailure('COMMAND: pub ${args.join(' ')}');
  printOnFailure('EXIT CODE: ${result.exitCode}');
  printOnFailure('STDOUT:\n${result.stdout}');
  printOnFailure('STDERR:\n${result.stderr}');
  return DevToolFunctionalTestResult._(
      tempDir,
      result.exitCode,
      (result.stderr as String).split('\n'),
      (result.stdout as String).split('\n'));
}

class DevToolFunctionalTestResult {
  DevToolFunctionalTestResult._(
      this._tempDir, this.exitCode, this.stderr, this.stdout);
  final Directory _tempDir;
  final int exitCode;
  final List<String> stderr;
  final List<String> stdout;
  Directory directoryAt(String path) =>
      Directory(p.join(_tempDir.absolute.path, path));
  File fileAt(String path) => File(p.join(_tempDir.absolute.path, path));
}

Matcher exitsWith(dynamic matcher) => _ExitsWith(matcher);

class _ExitsWith extends CustomMatcher {
  _ExitsWith(dynamic matcher)
      : super('DevTool that exits with a code that is', 'exit code', matcher);

  @override
  Object featureValueOf(dynamic actual) {
    return (actual as DevToolFunctionalTestResult).exitCode;
  }
}

Matcher printsToStderr(dynamic matcher) => _PrintsToStderr(matcher);

class _PrintsToStderr extends CustomMatcher {
  _PrintsToStderr(dynamic matcher)
      : super('DevTool that prints stderr lines that', 'stderr lines', matcher);

  @override
  Object featureValueOf(dynamic actual) {
    return (actual as DevToolFunctionalTestResult).stderr;
  }
}

Matcher printsToStdout(dynamic matcher) => _PrintsToStdout(matcher);

class _PrintsToStdout extends CustomMatcher {
  _PrintsToStdout(dynamic matcher)
      : super('DevTool that prints stdout lines that', 'stdout lines', matcher);

  @override
  Object featureValueOf(dynamic actual) {
    return (actual as DevToolFunctionalTestResult).stdout;
  }
}

Matcher producesFile(String path, [dynamic matcher]) =>
    _ProducesFile(path, matcher ?? _FileSystemEntityExists());

class _ProducesFile extends CustomMatcher {
  _ProducesFile(this.path, dynamic matcher)
      : super('DevTool that produces file at $path that', 'file', matcher);

  final String path;

  @override
  Object featureValueOf(dynamic actual) {
    return (actual as DevToolFunctionalTestResult).fileAt(path);
  }
}

Matcher producesDirectory(String path, [dynamic matcher]) =>
    _ProducesDirectory(path, matcher ?? _FileSystemEntityExists());

class _ProducesDirectory extends CustomMatcher {
  _ProducesDirectory(this.path, dynamic matcher)
      : super('DevTool that produces directory at $path that', 'directory',
            matcher);

  final String path;

  @override
  Object featureValueOf(dynamic actual) {
    return (actual as DevToolFunctionalTestResult).directoryAt(path);
  }
}

class _FileSystemEntityExists extends CustomMatcher {
  _FileSystemEntityExists() : super('exists', 'exists', isTrue);

  @override
  Object featureValueOf(actual) {
    return (actual as FileSystemEntity).existsSync();
  }
}
