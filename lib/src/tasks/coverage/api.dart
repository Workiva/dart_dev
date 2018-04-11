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

library dart_dev.src.tasks.coverage.api;

import 'dart:async';
import 'dart:io';

import 'package:dart2_constant/convert.dart' as convert;
import 'package:dart_dev/util.dart' show TaskProcess, getOpenPort;
import 'package:path/path.dart' as path;

import 'package:dart_dev/src/platform_util/api.dart' as platform_util;
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/coverage/config.dart';
import 'package:dart_dev/src/tasks/coverage/exceptions.dart';
import 'package:dart_dev/src/tasks/serve/api.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/tasks/test/config.dart';
import 'package:dart_dev/src/tools/selenium.dart';

const String _dartFilePattern = '.dart';
const String _testFilePattern = '_test.dart';

class CoverageResult extends TaskResult {
  final File collection;
  final Directory report;
  final File reportIndex;
  final File lcov;
  final Iterable<String> tests;

  CoverageResult.fail(
      Iterable<String> this.tests, File this.collection, File this.lcov,
      {Directory report})
      : this.report = report,
        reportIndex = report != null
            ? new File(path.join(report.path, 'index.html'))
            : null,
        super.fail();

  CoverageResult.success(
      Iterable<String> this.tests, File this.collection, File this.lcov,
      {Directory report})
      : this.report = report,
        reportIndex = report != null
            ? new File(path.join(report.path, 'index.html'))
            : null,
        super.success();
}

class CoverageTask extends Task {
  static const String _observatoryFailPattern =
      'Could not start Observatory HTTP server';
  static const String _testsFailedPattern = 'Some tests failed.';
  static const String _testsPassedPattern = 'All tests passed!';

  /// Collect and format coverage for the given suite of [tests]. The result of
  /// the coverage task will be returned once it has completed.
  ///
  /// Each file path in [tests] will be run as a test. Each directory path in
  /// [tests] will be searched (recursively) for all files ending in
  /// "_test.dart" and all matching files will be run as tests.
  ///
  /// If [html] is true, `genhtml` will be used to generate an HTML report of
  /// the collected coverage and the report will be opened.
  static Future<CoverageResult> run(List<String> tests,
      {bool html: defaultHtml,
      String output: defaultOutput,
      List<String> reportOn: defaultReportOn}) async {
    CoverageTask coverage =
        new CoverageTask._(tests, reportOn, html: html, output: output);
    await coverage._run();
    return coverage.done;
  }

  /// Collect and format coverage for the given suite of [tests]. The
  /// [CoverageTask] instance will be returned as soon as it is started. Output
  /// from the sub tasks will be available in stream format so that immediate
  /// progress can be monitored. The result of the coverage task will be
  /// available from the `done` Future on the task.
  ///
  /// Each file path in [tests] will be run as a test. Each directory path in
  /// [tests] will be searched (recursively) for all files ending in
  /// "_test.dart" and all matching files will be run as tests.
  ///
  /// If [pubServe] is true, a Pub server will be automatically started and
  /// used to run any browser tests.
  ///
  /// If [html] is true, `genhtml` will be used to generate an HTML report of
  /// the collected coverage and the report will be opened.
  static CoverageTask start(List<String> tests,
      {bool html: defaultHtml,
      bool pubServe: defaultPubServe,
      String output: defaultOutput,
      List<String> reportOn: defaultReportOn}) {
    CoverageTask coverage = new CoverageTask._(tests, reportOn,
        html: html, output: output, pubServe: pubServe);
    coverage._run();
    return coverage;
  }

  /// JSON formatted coverage. Output from the coverage package.
  File _collection;

  /// Combination of the underlying process stdouts.
  StreamController<String> _coverageOutput = new StreamController();

  /// Combination of the underlying process stderrs.
  StreamController<String> _coverageErrorOutput = new StreamController();

  /// Completes when collection, formatting, and report generation is finished.
  Completer<CoverageResult> _done = new Completer();

  /// LCOV formatted coverage.
  File _lcov;

  /// List of test files to run and collect coverage from. This list is
  /// generated from the given list of test paths by adding all files and
  /// searching all directories for valid test files.
  List<File> _files = [];

  bool _failingTest = false;

  /// Whether or not to generate the HTML report.
  bool _html = defaultHtml;

  /// Whether to automatically start and use a Pub server when running
  /// browser tests.
  final bool pubServe;

  /// File created to run the test in a browser. Need to store it so it can be
  /// cleaned up after the test finishes.
  File _lastHtmlFile;

  /// Process used to run the tests. Need to store it so it can be killed after
  /// the coverage collection has completed.
  TaskProcess _lastTestProcess;

  /// Directory to output all coverage related artifacts.
  Directory _outputDirectory;

  /// List of directories on which coverage should be reported.
  List<String> _reportOn;

  CoverageTask._(List<String> tests, List<String> reportOn,
      {bool html: defaultHtml,
      String output: defaultOutput,
      bool this.pubServe: defaultPubServe})
      : _html = html,
        _outputDirectory = new Directory(output),
        _reportOn = reportOn {
    // Build the list of test files.
    tests.forEach((path) {
      if (path.endsWith(_dartFilePattern) &&
          FileSystemEntity.isFileSync(path)) {
        _files.add(new File(path));
      } else if (FileSystemEntity.isDirectorySync(path)) {
        Directory dir = new Directory(path);
        List<FileSystemEntity> children = dir.listSync(recursive: true);
        Iterable<FileSystemEntity> validTests =
            children.where((FileSystemEntity e) {
          return (
              // Is a file, not a directory.
              e is File &&
                  // Is not a package dependency file.
                  !(Uri.parse(e.path).pathSegments.contains('packages')) &&
                  // Is a valid test file.
                  e.path.endsWith(_testFilePattern));
        });
        _files.addAll(validTests);
      }
    });
  }

  /// Generated file with the coverage collection information in JSON format.
  File get collection => _collection;

  /// Completes when the coverage collection, formatting, and optional report
  /// generation has finished. Completes with a [CoverageResult] instance.
  @override
  Future<CoverageResult> get done => _done.future;

  /// Combination of the underlying process stderrs, including individual test
  /// runs and the collection of coverage from each, the formatting of the
  /// complete coverage data set, and the generation of an HTML report if
  /// applicable. Each item in the stream is a line.
  Stream<String> get errorOutput => _coverageErrorOutput.stream;

  /// Generated file with the coverage collection information in LCOV format.
  File get lcov => _lcov;

  /// Combination of the underlying process stdouts, including individual test
  /// runs and the collection of coverage from each, the formatting of the
  /// complete coverage data set, and the generation of an HTML report if
  /// applicable. Each item in the stream is a line.
  Stream<String> get output => _coverageOutput.stream;

  /// Directory containing the generated coverage report.
  Directory get report => _outputDirectory;

  /// Path to the directory where collections will be temporarily stored.
  Directory get _collections =>
      new Directory(path.join(_outputDirectory.path, 'collection/'));

  /// All test files (expanded from the given list of test paths).
  /// This is the exact list of tests that were run for coverage collection.
  Iterable<String> get tests => _files.map((f) => f.path);

  Future _collect() async {
    List<File> collections = [];
    PubServeTask pubServeTask;
    PubServeInfo serveInfo;

    if (pubServe) {
      pubServeTask = _startServeForCoverage();
      serveInfo = await pubServeTask.serveInfos.first;
    }

    for (int i = 0; i < _files.length; i++) {
      List<int> observatoryPorts;
      TaskProcess process;

      // Run the test and obtain the observatory port for coverage collection.
      try {
        // Look for a correlating HTML file.
        File customHtmlFile = _correspondingHtmlForTest(_files[i]);

        // Determine if this is a VM test or a browser test.
        bool isBrowserTest =
            customHtmlFile.existsSync() || await _usesHtmlOrJsLib(_files[i]);

        if (isBrowserTest) {
          // Build or modify the HTML file to properly load the test.
          File htmlFile = _createOrModifyHtmlForTest(_files[i], customHtmlFile);

          String testPath;
          if (pubServe) {
            var relativeHtmlPath =
                path.relative(htmlFile.path, from: serveInfo.directory);
            testPath = 'http://localhost:${serveInfo.port}/$relativeHtmlPath';
          } else {
            testPath = htmlFile.path;
          }

          observatoryPorts = await _runTestInBrowser(testPath);
        } else {
          observatoryPorts = await _runTestOnVm(_files[i].path);
        }
      } on CoverageTestSuiteException {
        _coverageErrorOutput.add('Tests failed: ${_files[i].path}');
        continue;
      }

      for (int j = 0; j < observatoryPorts.length; j++) {
        // Collect the coverage from observatory located at this port.
        File collection =
            new File(path.join(_collections.path, '${_files[i].path}$j.json'));
        String executable = 'pub';
        List args = [
          'run',
          'coverage:collect_coverage',
          '--port=${observatoryPorts[j]}',
          '-o',
          collection.path
        ];

        _coverageOutput.add('');
        _coverageOutput.add('Collecting coverage for ${_files[i].path}');
        _coverageOutput.add('$executable ${args.join(' ')}\n');

        process = new TaskProcess(executable, args);
        process.stdout.listen((l) => _coverageOutput.add('    $l'));
        process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));

        await process.done;

        collections.add(collection);
      }

      _killTest();

      // Kill off any child selenium processes that may have been spawned for
      // functional tests.
      await SeleniumHelper.killChildrenProcesses();
    }
    pubServeTask?.stop();
    // Merge all individual coverage collection files into one.
    _collection = _merge(collections);
  }

  Future _format() async {
    _lcov = new File(path.join(_outputDirectory.path, 'coverage.lcov'));

    String executable = 'pub';
    List args = [
      'run',
      'coverage:format_coverage',
      '-l',
      '--packages=.packages',
      '-i',
      collection.path,
      '-o',
      lcov.path,
      '--verbose'
    ];
    args.addAll(_reportOn.map((p) => '--report-on=$p'));

    _coverageOutput.add('');
    _coverageOutput.add('Formatting coverage');
    _coverageOutput.add('$executable ${args.join(' ')}\n');

    TaskProcess process = new TaskProcess(executable, args);
    process.stdout.listen((l) => _coverageOutput.add('    $l'));
    process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));
    await process.done;

    if (lcov.existsSync()) {
      _coverageOutput.add('');
      _coverageOutput.add('Coverage formatted to LCOV: ${lcov.path}');
    } else {
      String error =
          'Coverage formatting failed. Could not generate ${lcov.path}';
      _coverageErrorOutput.add(error);
      throw new Exception(error);
    }
  }

  Future _generateReport() async {
    String executable = 'genhtml';
    List args = ['-o', _outputDirectory.path, lcov.path];

    _coverageOutput.add('');
    _coverageOutput.add('Generating HTML report...');
    _coverageOutput.add('$executable ${args.join(' ')}\n');

    TaskProcess process = new TaskProcess(executable, args);
    process.stdout.listen((l) => _coverageOutput.add('    $l'));
    process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));
    await process.done;
  }

  void _killTest() {
    if (_lastTestProcess != null) {
      _lastTestProcess.killAllChildren();
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

    Map mergedJson = convert.json.decode(collections.first.readAsStringSync());
    for (int i = 1; i < collections.length; i++) {
      if (!collections[i].existsSync()) continue;
      String coverage = collections[i].readAsStringSync();
      if (coverage.isNotEmpty) {
        Map coverageJson = convert.json.decode(coverage);
        mergedJson['coverage'].addAll(coverageJson['coverage']);
      }
    }
    _collections.deleteSync(recursive: true);

    File coverage = new File(path.join(_outputDirectory.path, 'coverage.json'));
    if (coverage.existsSync()) {
      coverage.deleteSync();
    }
    coverage.createSync();
    coverage.writeAsStringSync(convert.json.encode(mergedJson));
    return coverage;
  }

  Future _run() async {
    if (_html && !(await platform_util.isExecutableInstalled('lcov'))) {
      _done.completeError(new MissingLcovException());
      return;
    }

    await _collect();
    await _format();

    if (_html) {
      await _generateReport();
    }

    if (_failingTest) {
      _done.complete(
          new CoverageResult.fail(tests, collection, lcov, report: report));
    } else {
      _done.complete(
          new CoverageResult.success(tests, collection, lcov, report: report));
    }
  }

  File _correspondingHtmlForTest(File test) {
    String htmlPath = test.absolute.path;
    htmlPath = htmlPath.substring(0, htmlPath.length - '.dart'.length);
    htmlPath = '$htmlPath.html';
    return new File(htmlPath);
  }

  File _createOrModifyHtmlForTest(File test, File customHtml) {
    File htmlFile;
    if (customHtml.existsSync()) {
      // A custom HTML file exists, but is designed for the test package's
      // test runner. A slightly modified version of that file is needed.
      htmlFile = _lastHtmlFile = new File('${customHtml.path}.temp.html');
      test.createSync();
      String contents = customHtml.readAsStringSync();
      String testFile = test.uri.pathSegments.last;
      var linkP1 =
          new RegExp(r'<link .*rel="x-dart-test" .*href="([\w/]+\.dart)"');
      var linkP2 =
          new RegExp(r'<link .*href="([\w/]+\.dart)" .*rel="x-dart-test"');
      if (linkP1.hasMatch(contents)) {
        Match match = linkP1.firstMatch(contents);
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
      htmlFile = _lastHtmlFile = new File('${test.path}.temp.html');
      htmlFile.createSync();
      String testFile = test.uri.pathSegments.last;
      htmlFile.writeAsStringSync(
          '<script type="application/dart" src="$testFile"></script>');
    }

    return htmlFile;
  }

  Future<bool> _usesHtmlOrJsLib(File test) async {
    // Run analysis on file in "Server" category and look for "Library not
    // found" errors, which indicates a `dart:html` import.
    ProcessResult pr = await Process.run(
        'dart2js',
        [
          '--analyze-only',
          '--categories=Server',
          '--packages=.packages',
          test.path
        ],
        runInShell: true);
    // TODO: When dart2js has fixed the issue with their exitcode we should
    //       rely on the exitcode instead of the stdout.
    return pr.stdout != null &&
        (pr.stdout as String)
            .contains(new RegExp(r'Error: Library not (found|supported)'));
  }

  PubServeTask _startServeForCoverage() {
    PubServeTask pubServeTask;
    _coverageOutput.add('Starting Pub server...');

    // Start `pub serve` on the `test` directory.
    pubServeTask =
        startPubServe(port: config.test.pubServePort, additionalArgs: ['test']);

    _coverageOutput.add('::: ${pubServeTask.command}');
    String indentLine(String line) => '    $line';

    var startupLogFinished = new Completer();
    pubServeTask.stdOut
        .transform(until(startupLogFinished.future))
        .map(indentLine)
        .listen(_coverageOutput.add);
    pubServeTask.stdErr
        .transform(until(startupLogFinished.future))
        .map(indentLine)
        .listen(_coverageErrorOutput.add);

    startupLogFinished.complete();
    pubServeTask.stdOut.map(indentLine).join('\n').then((stdOut) {
      if (stdOut.isNotEmpty) {
        _coverageOutput.add('`${pubServeTask.command}` (buffered stdout)');
        _coverageOutput.add(stdOut);
      }
    });
    pubServeTask.stdErr.map(indentLine).join('\n').then((stdErr) {
      if (stdErr.isNotEmpty) {
        _coverageOutput.add('`${pubServeTask.command}` (buffered stdout)');
        _coverageOutput.add(stdErr);
      }
    });

    return pubServeTask;
  }

  Future<List<int>> _runTestOnVm(String testPath) async {
    // Find an open port to observe the Dart VM on.
    int port = await getOpenPort();

    // Run the test on the Dart VM.
    String executable = 'dart';
    List args = ['--observe=$port', testPath];
    _coverageOutput.add('');
    _coverageOutput.add('Running VM test suite ${testPath}');
    _coverageOutput.add('$executable ${args.join(' ')}\n');
    TaskProcess process = _lastTestProcess = new TaskProcess(executable, args);
    process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));

    await for (String line in process.stdout) {
      _coverageOutput.add('    $line');
      if (line.contains(_observatoryFailPattern)) {
        throw new CoverageTestSuiteException(testPath);
      }
      if (line.contains(_testsFailedPattern)) {
        _failingTest = true;
        throw new CoverageTestSuiteException(testPath);
      }
      if (line.contains(_testsPassedPattern)) {
        break;
      }
    }
    var observatoryPorts = await SeleniumHelper.getActiveObservatoryPorts();
    SeleniumHelper.clearObservatoryPorts();
    return [port]..addAll(observatoryPorts);
  }

  Future<List<int>> _runTestInBrowser(String testPath) async {
    final RegExp _observatoryPortPattern = new RegExp(
        r'Observatory listening (at|on) http:\/\/127\.0\.0\.1:(\d+)');

    // Run the test in content-shell.
    String executable = 'content_shell';
    // The window size is specified to correspond to the size of the window in the
    // dart test package, https://github.com/dart-lang/test/blob/ec1b57647df74293d7a71316020e39702735b3f7/CHANGELOG.md#012201
    List args = ['--content-shell-host-window-size=1024x768', testPath];
    _coverageOutput.add('');
    _coverageOutput.add('Running test suite ${testPath}');
    _coverageOutput.add('$executable ${args.join(' ')}\n');
    TaskProcess process =
        _lastTestProcess = new TaskProcess('content_shell', args);

    // Content-shell dumps render tree to stderr, which is where the test
    // results will be. The observatory port should be output to stderr as
    // well, but it is sometimes malformed. In those cases, the correct
    // observatory port is output to stdout. So we listen to both.
    int observatoryPort;
    process.stdout.listen((line) {
      _coverageOutput.add('    $line');
      if (line.contains(_observatoryPortPattern)) {
        Match m = _observatoryPortPattern.firstMatch(line);
        observatoryPort = int.parse(m.group(2));
      }
    });
    await for (String line in process.stderr) {
      _coverageOutput.add('    $line');
      if (line.contains(_observatoryFailPattern)) {
        throw new CoverageTestSuiteException(testPath);
      }
      if (line.contains(_observatoryPortPattern)) {
        Match m = _observatoryPortPattern.firstMatch(line);
        observatoryPort = int.parse(m.group(2));
      }
      if (line.contains(_testsFailedPattern)) {
        _failingTest = true;
        throw new CoverageTestSuiteException(testPath);
      }
      if (line.contains(_testsPassedPattern)) {
        break;
      }
    }
    return [observatoryPort];
  }
}
