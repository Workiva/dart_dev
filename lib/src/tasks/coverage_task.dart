// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import 'package:dart_dev/src/config/dart_dev_config.dart';
import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/utils/platform_utils.dart' as platform;
import 'package:dart_dev/src/utils/process_utils.dart';
import 'package:dart_dev/src/utils/pub_serve_utils.dart';
import 'package:dart_dev/src/utils/text_utils.dart' as text;

const missingLcovMessage = '''
The "lcov" dependency is missing. It's required for generating the HTML report.

If using brew, you can install it with:
    brew update
    brew install lcov

Otherwise, visit http://ltp.sourceforge.net/coverage/lcov.php''';

class CoverageTask extends Task {
  @override
  final ArgParser argParser = null;

  @override
  final String command = 'coverage';

  /// JSON formatted coverage. Output from the coverage package.
  File _collection;

  /// Whether or not one or more tests failed while collecting coverage.
  bool _hasFailingTest = false;

  /// List of test files to run and collect coverage from. This list is
  /// generated from the given list of test paths by adding all files and
  /// searching all directories for valid test files.
  List<File> _files;

  /// File created to run the test in a browser. Need to store it so it can be
  /// cleaned up after the test finishes.
  File _lastHtmlFile;

  /// Process used to run the tests. Need to store it so it can be killed after
  /// the coverage collection has completed.
  ProcessHelper _lastTestProcess;

  /// LCOV formatted coverage.
  File _lcov;

  /// Directory to output all coverage related artifacts.
  Directory _outputDirectory;

  /// Path to the directory where collections will be temporarily stored.
  Directory _collectionsDir;

  @override
  Future<Null> help(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) async {
    reporter.important('Usage: pub run dart_dev coverage [options...]');
    reporter.writeln();
    reporter.writeln(
        'The dart_dev coverage task runs individual test files and '
        'then runs the coverage executable to collect and format coverage.');
    reporter.writeln();

    _packageConfig(config, reporter, verbose: verbose);

    reporter.h1('Command Line Options (pub run test)');
    reporter.writeln();
    reporter.indent();
    reporter.writeln(await _getTestHelp());
    reporter.dedent();
  }

  @override
  Future<int> run(DartDevConfig config, LenientArgResults parsedArgs,
      text.Reporter reporter) async {
    _packageConfig(config, reporter);

    if (!(await platform.hasImmediateDependency('test'))) {
      reporter.writeln();
      reporter.error('Package "test" must be an immediate dependency in order '
          'to run its executables.');
      reporter.error('Please add "test" to your pubspec.yaml.');
      reporter.dedent();
      return 1;
    }

    if (!(await platform.hasImmediateDependency('coverage'))) {
      reporter.writeln();
      reporter.error('Package "coverage" must be an immediate dependency in '
          'order to run its executables.');
      reporter.error('Please add "coverage" to your pubspec.yaml.');
      reporter.dedent();
      return 1;
    }

    if (config.coverage.generateHtml &&
        !(await platform.isExecutableInstalled('lcov'))) {
      reporter.error(missingLcovMessage);
      reporter.dedent();
      return 1;
    }

    reporter.h1('Pub Server');
    reporter.indent();

    PubServe pubServe = PubServe
        .start(port: config.test.pubServePort, additionalArgs: ['test']);
    PubServeInfo pubServeInfo;
    reporter.important('command: ${pubServe.command}');

    try {
      pubServeInfo = await pubServe.onServe.first;
    } on StateError {
      reporter.writeln();
      reporter.error('Failed to start pub server:');
      reporter.indent();
      await pubServe.done;
      reporter.writeln(await pubServe.stdErr.join('\n'));
      reporter.dedent();
      reporter.dedent();
      return 1;
    }

    reporter.writeln('Serving on port ${pubServeInfo.port}');
    reporter.writeln();
    reporter.dedent();

    Future<Null> cleanUp() async {
      await pubServe?.kill();
      reporter.dedent();
    }

    reporter.h1('Running Tests and Collecting Coverage');
    reporter.indent();

    // TODO: fail on unsupported args

    _outputDirectory = new Directory(config.coverage.output);
    _collectionsDir =
        new Directory(path.join(_outputDirectory.path, 'collection/'));

    _files =
        _getTestFiles(config.coverage.paths, config.coverage.filenamePattern);

    if (!(await _collect(pubServeInfo, reporter))) {
      await cleanUp();
      return 1;
    }

    if (!(await _format(config.coverage.reportOn, reporter))) {
      await cleanUp();
      return 1;
    }

    if (config.coverage.generateHtml) {
      if (!(await _generateReport(reporter))) {
        reporter.error('Failed to generate HTML coverage report.');
        await cleanUp();
        return 1;
      }

      await _openReport();
    }

    if (_hasFailingTest) {
      reporter.warning('At least one test failed while collecting coverage.');
      await cleanUp();
      return 1;
    }

    await cleanUp();
    return 0;
  }

  Future<bool> _collect(
      PubServeInfo pubServeInfo, text.Reporter reporter) async {
    List<File> collections = [];
    for (int i = 0; i < _files.length; i++) {
      List<int> observatoryPorts;
      ProcessHelper process;

      // Run the test and obtain the observatory port for coverage collection.
      try {
        observatoryPorts = await _test(_files[i], pubServeInfo, reporter);
      } on CoverageTestSuiteException {
        reporter.error('Tests failed: ${_files[i].path}');
        continue;
      }

      for (int j = 0; j < observatoryPorts.length; j++) {
        // Collect the coverage from observatory located at this port.
        File collection = new File(
            path.join(_collectionsDir.path, '${_files[i].path}$j.json'));
        String executable = 'pub';
        List args = [
          'run',
          'coverage:collect_coverage',
          '--port=${observatoryPorts[j]}',
          '-o',
          collection.path
        ];

        reporter.writeln();
        reporter.h2('Collecting Coverage');
        reporter.indent();
        reporter.writeln('file: ${_files[i].path}');
        reporter.important('command: $executable ${args.join(' ')}\n');

        process = ProcessHelper.start(executable, args);
        process.stdout.listen(reporter.writeln);
        process.stderr.listen(reporter.warning);

        await process.done;
        reporter.dedent();

        collections.add(collection);
      }

      _killTest();
    }

    // Merge all individual coverage collection files into one.
    try {
      _collection = _merge(collections);
    } on ArgumentError {
      reporter.error('No coverage could be collected.');
      return false;
    }
    return true;
  }

  Future<bool> _format(
      Iterable<String> reportOn, text.Reporter reporter) async {
    _lcov = new File(path.join(_outputDirectory.path, 'coverage.lcov'));

    String executable = 'pub';
    List args = [
      'run',
      'coverage:format_coverage',
      '-l',
      '--package-root=packages',
      '-i',
      _collection.path,
      '-o',
      _lcov.path,
      '--verbose'
    ];
    args.addAll(reportOn.map((p) => '--report-on=$p'));

    reporter.writeln();
    reporter.h2('Formatting Coverage');
    reporter.indent();
    reporter.important('command: $executable ${args.join(' ')}\n');

    final process = ProcessHelper.start(executable, args);
    process.stdout.listen(reporter.writeln);
    process.stderr.listen(reporter.warning);
    await process.done;

    if (_lcov.existsSync()) {
      reporter.writeln();
      reporter.success('Coverage formatted to LCOV: ${_lcov.path}');
      reporter.writeln();
      reporter.dedent();
      return true;
    } else {
      reporter.error('Coverage formatting failed. Could not generate '
          '${_lcov.path}');
      reporter.writeln();
      reporter.dedent();
      return false;
    }
  }

  Future<bool> _generateReport(text.Reporter reporter) async {
    String executable = 'genhtml';
    List args = ['-o', _outputDirectory.path, _lcov.path];

    reporter.h2('Generating HTML report');
    reporter.indent();
    reporter.important('command: $executable ${args.join(' ')}\n');

    final process = ProcessHelper.start(executable, args);
    process.stdout.listen(reporter.writeln);
    process.stderr.listen(reporter.warning);
    await process.done;
    reporter.writeln();
    reporter.dedent();
    return (await process.exitCode) == 0;
  }

  List<File> _getTestFiles(Iterable<String> testPaths, String filenamePattern) {
    final testFiles = <File>[];
    for (final testPath in testPaths) {
      if (FileSystemEntity.isFileSync(testPath)) {
        testFiles.add(new File(testPath));
      } else if (FileSystemEntity.isDirectorySync(testPath)) {
        if (Uri.parse(testPath).pathSegments.contains('packages')) continue;

        final pathWithoutTrailiingSlash = testPath.endsWith('/')
            ? testPath.substring(0, testPath.length - 1)
            : testPath;
        final testFileGlob =
            new Glob(pathWithoutTrailiingSlash + '/' + filenamePattern);
        for (final testFile in testFileGlob.listSync()) {
          if (testFile is File) {
            testFiles.add(testFile);
          }
        }
      }
    }

    return testFiles;
  }

  Future<String> _getTestHelp() {
    final process = ProcessHelper.start('pub', ['run', 'test', '--help']);
    return process.stdout.join('\n');
  }

  void _killTest() {
    if (_lastTestProcess != null) {
//      _lastTestProcess.killAllChildren();
      _lastTestProcess.kill();
    }
    _lastTestProcess = null;
    if (_lastHtmlFile != null && _lastHtmlFile.existsSync()) {
      _lastHtmlFile.deleteSync();
    }
  }

  File _merge(List<File> collections) {
    if (collections.isEmpty)
      throw new ArgumentError('Cannot merge an empty list of coverages.');

    Map mergedJson = JSON.decode(collections.first.readAsStringSync());
    for (int i = 1; i < collections.length; i++) {
      if (!collections[i].existsSync()) continue;
      String coverage = collections[i].readAsStringSync();
      if (coverage.isNotEmpty) {
        Map coverageJson = JSON.decode(coverage);
        mergedJson['coverage'].addAll(coverageJson['coverage']);
      }
    }
    _collectionsDir.deleteSync(recursive: true);

    File coverage = new File(path.join(_outputDirectory.path, 'coverage.json'));
    if (coverage.existsSync()) {
      coverage.deleteSync();
    }
    coverage.createSync();
    coverage.writeAsStringSync(JSON.encode(mergedJson));
    return coverage;
  }

  Future<Null> _openReport() async {
    final indexPath = path.join(_outputDirectory.path, 'index.html');
    final process = ProcessHelper.start('open', [indexPath]);
    await process.done;
  }

  void _packageConfig(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) {
    String pubServePortValue = '${config.test.pubServePort}';
    if (config.test.pubServePort == 0) {
      pubServePortValue += ' (automatic)';
    }

    reporter.h1('Package Configuration');
    reporter.writeln();
    reporter.indent();

    reporter.h2('Pub Serve (from dart_dev.yaml)');
    reporter.writeln('- Enabled: true (required for coverage)');
    if (config.test.pubServe) {
      reporter.writeln('- Port: $pubServePortValue');
    }
    reporter.writeln();

    reporter.h2('Tests (from dart_test.yaml)');
    reporter.writeln('- Paths:');
    reporter.indent();
    for (final testPath in config.coverage.paths) {
      reporter.writeln('- $testPath');
    }
    reporter.dedent();
    reporter.writeln('- Test file pattern: ${config.coverage.filenamePattern}');
    reporter.writeln();

    reporter.h2('Coverage Report (from dart_dev.yaml)');
    reporter.writeln('- Generate HTML: ${config.coverage.generateHtml}');
    reporter.writeln('- Output directory: ${config.coverage.output}');
    reporter.writeln();

    reporter.dedent();
  }

  Future<List<int>> _test(
      File file, PubServeInfo pubServeInfo, text.Reporter reporter) async {
    // Look for a correlating HTML file.
    String htmlPath = file.absolute.path;
    htmlPath = htmlPath.substring(0, htmlPath.length - '.dart'.length);
    htmlPath = '$htmlPath.html';
    final customHtmlFile = new File(htmlPath);

    // Build or modify the HTML file to properly load the test.
    File htmlFile;
    if (customHtmlFile.existsSync()) {
      // A custom HTML file exists, but is designed for the test package's
      // test runner. A slightly modified version of that file is needed.
      htmlFile = _lastHtmlFile = new File('${customHtmlFile.path}.temp.html');
      file.createSync();
      String contents = customHtmlFile.readAsStringSync();
      String testFile = file.uri.pathSegments.last;
      final linkP1 =
          new RegExp(r'<link .*rel="x-dart-test" .*href="([\w/]+\.dart)"');
      final linkP2 =
          new RegExp(r'<link .*href="([\w/]+\.dart)" .*rel="x-dart-test"');
      if (linkP1.hasMatch(contents)) {
        final match = linkP1.firstMatch(contents);
        testFile = match.group(1);
      } else if (linkP2.hasMatch(contents)) {
        Match match = linkP2.firstMatch(contents);
        testFile = match.group(1);
      }

      String dartJsScript = '<script src="packages/test/dart.js"></script>';
      String testScript =
          '<script type="application/dart" src="$testFile"></script>';
      contents = contents.replaceFirst(dartJsScript, testScript);
      htmlFile.writeAsStringSync(contents);
    } else {
      // Create an HTML file that simply loads the test file.
      htmlFile = _lastHtmlFile = new File('${file.path}.temp.html');
      htmlFile.createSync();
      final testFile = file.uri.pathSegments.last;
      htmlFile.writeAsStringSync(
          '<script type="application/dart" src="$testFile"></script>');
    }

    // Determine if this is a VM test or a browser test.
    bool isBrowserTest;
    if (customHtmlFile.existsSync()) {
      isBrowserTest = true;
    } else {
      // Run analysis on file in "Server" category and look for "Library not
      // found" errors, which indicates a `dart:html` import.
      ProcessResult pr = await Process.run(
          'dart2js',
          [
            '--analyze-only',
            '--categories=Server',
            '--package-root=packages',
            file.path
          ],
          runInShell: true);
      // TODO: When dart2js has fixed the issue with their exitcode we should
      //       rely on the exitcode instead of the stdout.
      isBrowserTest = pr.stdout != null &&
          (pr.stdout as String)
              .contains(new RegExp(r'Error: Library not (found|supported)'));
    }

    String _observatoryFailPattern = 'Could not start Observatory HTTP server';
    RegExp _observatoryPortPattern = new RegExp(
        r'Observatory listening (at|on) http:\/\/127\.0\.0\.1:(\d+)');

    String _testsFailedPattern = 'Some tests failed.';
    String _testsPassedPattern = 'All tests passed!';

    if (isBrowserTest) {
      var relativeHtmlPath =
          path.relative(htmlFile.path, from: pubServeInfo.directory);
      final testPath =
          'http://localhost:${pubServeInfo.port}/$relativeHtmlPath';

      // Run the test in content-shell.
      String executable = 'content_shell';
      List args = [testPath];
      reporter.writeln();
      reporter.h2('Running Test Suite');
      reporter.indent();
      reporter.writeln('platform: content-shell');
      reporter.writeln('file: ${file.path}');
      reporter.important('command: $executable ${args.join(' ')}');
      reporter.writeln();

      ProcessHelper process =
          _lastTestProcess = ProcessHelper.start('content_shell', args);

      // Content-shell dumps render tree to stderr, which is where the test
      // results will be. The observatory port should be output to stderr as
      // well, but it is sometimes malformed. In those cases, the correct
      // observatory port is output to stdout. So we listen to both.
      int observatoryPort;
      process.stdout.listen((line) {
        reporter.writeln(line);
        if (line.contains(_observatoryPortPattern)) {
          Match m = _observatoryPortPattern.firstMatch(line);
          observatoryPort = int.parse(m.group(2));
        }
      });
      await for (String line in process.stderr) {
        reporter.writeln(line);
        if (line.contains(_observatoryFailPattern)) {
          throw new CoverageTestSuiteException(file.path);
        }
        if (line.contains(_observatoryPortPattern)) {
          Match m = _observatoryPortPattern.firstMatch(line);
          observatoryPort = int.parse(m.group(2));
        }
        if (line.contains(_testsFailedPattern)) {
          _hasFailingTest = true;
          throw new CoverageTestSuiteException(file.path);
        }
        if (line.contains(_testsPassedPattern)) {
          break;
        }
      }

      reporter.dedent();

      return [observatoryPort];
    } else {
      // Find an open port to observe the Dart VM on.
      int port = await platform.getOpenPort();

      // Run the test on the Dart VM.
      String executable = 'dart';
      List args = ['--observe=$port', file.path];
      reporter.writeln();
      reporter.h2('Running Test Suite');
      reporter.indent();
      reporter.writeln('platform: dart VM');
      reporter.writeln('file: ${file.path}');
      reporter.important('command: $executable ${args.join(' ')}');
      reporter.writeln();

      ProcessHelper process =
          _lastTestProcess = ProcessHelper.start(executable, args);
      process.stderr.listen(reporter.writeln);

      await for (String line in process.stdout) {
        reporter.writeln(line);
        if (line.contains(_observatoryFailPattern)) {
          throw new CoverageTestSuiteException(file.path);
        }
        if (line.contains(_testsFailedPattern)) {
          _hasFailingTest = true;
          throw new CoverageTestSuiteException(file.path);
        }
        if (line.contains(_testsPassedPattern)) {
          break;
        }
      }

      reporter.dedent();

//      var observatoryPorts = await SeleniumHelper.getActiveObservatoryPorts();
//      SeleniumHelper.clearObservatoryPorts();
      return [port]; //..addAll(observatoryPorts);
    }
  }
}

/// Thrown when collecting coverage on a test suite that has failing tests.
class CoverageTestSuiteException implements Exception {
  final String message;

  CoverageTestSuiteException(String testSuite)
      : this.message = 'Test suite has failing tests: $testSuite';

  String toString() => 'CoverageTestSuiteException: $message';
}
