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
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import 'package:dart_dev/src/config/dart_dev_config.dart';
import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/utils/apply_license_utils.dart' as utils;
import 'package:dart_dev/src/utils/text_utils.dart' as text;

class ApplyLicenseTask extends Task {
  static const Iterable<String> supportedFileTypes = const [
    '.css',
    '.dart',
    '.html',
    '.js',
    '.sass',
    '.scss',
  ];

  @override
  final ArgParser argParser = new ArgParser()
    ..addOption('update-from',
        abbr: 'u',
        help:
            'Path to the old license file to update from. New license will be read from the configured location.');

  @override
  final String command = 'apply-license';

  @override
  Future<Null> help(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) async {
    reporter.important('Usage: pub run dart_dev apply-license [options...]');
    reporter.writeln();

    _packageConfig(config, reporter, verbose: verbose);

    reporter.h1('Command Line Options');
    reporter.writeln();
    reporter.indent();
    reporter.writeln(argParser.usage);
    reporter.dedent();
  }

  @override
  Future<int> run(DartDevConfig config, LenientArgResults parsedArgs,
      text.Reporter reporter) async {
    _packageConfig(config, reporter);

    reporter.h1('Applying License to Source Files');
    reporter.indent();

    if (config.applyLicense.license == null ||
        config.applyLicense.license.isEmpty) {
      reporter.error('License file not specified in dart_dev.yaml.');
      return 1;
    }

    final licenseFile = new File(config.applyLicense.license);
    if (!licenseFile.existsSync()) {
      reporter
          .error('License file does not exist: ${config.applyLicense.license}');
      return 1;
    }

    final license = licenseFile.readAsStringSync();

    final List<Glob> includeGlobs = [];
    if (config.applyLicense.includes.isNotEmpty) {
      includeGlobs.addAll(
          config.applyLicense.includes.map((pattern) => new Glob(pattern)));
    } else {
      includeGlobs.add(new Glob('lib/**'));
    }

    final List<Glob> excludeGlobs = [];
    if (config.applyLicense.excludes.isNotEmpty) {
      excludeGlobs.addAll(
          config.applyLicense.excludes.map((pattern) => new Glob(pattern)));
    }

    int alreadyApplied = 0;
    bool newLicensesApplied = false;
    reporter.writeln();
    await for (final file
        in getFiles(includeGlobs, excludeGlobs: excludeGlobs)) {
      try {
        if (utils.applyLicense(file, license)) {
          newLicensesApplied = true;
          reporter.writeln('√  ${file.path}');
        } else {
          alreadyApplied++;
        }
      } on utils.NonUtf8EncodedFileException {
        reporter
            .warning('Non-UTF8 file, could not apply license: ${file.path}');
      }
    }
    if (!newLicensesApplied) {
      reporter.writeln('All files already licensed.');
    } else {
      reporter.writeln('$alreadyApplied files already licensed.');
    }

    return 0;
  }

  void _packageConfig(DartDevConfig config, text.Reporter reporter,
      {bool verbose}) {
    reporter.h1('Package Configuration');
    reporter.writeln();
    reporter.indent();
    reporter.h2('License File (from dart_dev.yaml)');
    if (config.applyLicense.license == null ||
        config.applyLicense.license.isEmpty) {
      reporter.writeln('[not specified]');
    } else {
      reporter.writeln(config.applyLicense.license);
    }
    reporter.writeln();

    if (config.applyLicense.includes.isNotEmpty) {
      reporter.h2('Included Files (from dart_dev.yaml)');
      for (final include in config.applyLicense.includes) {
        reporter.writeln('- $include');
      }
      reporter.writeln();
    }

    if (config.applyLicense.excludes.isNotEmpty) {
      reporter.h2('Excluded Files (from dart_dev.yaml)');
      for (final exclude in config.applyLicense.excludes) {
        reporter.writeln('- $exclude');
      }
      reporter.writeln();
    }
    reporter.dedent();
  }
}

Stream<File> getFiles(Iterable<Glob> includeGlobs,
    {Iterable<Glob> excludeGlobs}) {
  final sc = new StreamController<File>();
  final includeGlobFutures = <Future>[];
  for (final includeGlob in includeGlobs) {
    final c = new Completer();
    includeGlobFutures.add(c.future);

    includeGlob.list().listen((entity) {
      // Only include files.
      if (entity is! File) return;
      final File file = entity;

      // Exclude /packages/ files.
      if (Uri.parse(entity.path).pathSegments.contains('packages')) {
        return;
      }

      // Exclude unsupported file types.
      if (!ApplyLicenseTask.supportedFileTypes
          .contains(path.extension(file.path))) {
        return;
      }

      // Check against the explicit excludes.
      if (excludeGlobs != null) {
        for (final excludeGlob in excludeGlobs) {
          if (excludeGlob.matches(file.path)) return;
        }
      }

      sc.add(file);
    }, onDone: () => c.complete());
  }

  // Close the StreamController when all include glob streams have completed.
  Future.wait(includeGlobFutures).then((_) => sc.close());

  return sc.stream;
}
