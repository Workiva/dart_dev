// Copyright 2019 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:w_common/sass.dart' as wc;

ConsumerPackageFixture consumerPackageFixtureInstance;

const String nonDefaultSourceDir = 'lib/';
const String nonDefaultOutputDir = 'lib/css/';
const String consumerPackageFixtureRoot = 'test_fixtures/sass';

class SassCompileResult {
  final int exitCode;
  final String stdErr;

  SassCompileResult(this.exitCode, [this.stdErr]);
}

/// Runs the sass task via dart_dev using the [additionalArgs]
/// provided in the [ConsumerPackageFixture.projectRoot] value of [consumerPackageFixtureInstance].
Future<SassCompileResult> compileConsumerSass(
    {List<String> additionalArgs: const <String>[]}) async {
  var args = ['run', 'dart_dev', 'sass']..addAll(additionalArgs);
  TaskProcess sassTaskProcess = new TaskProcess('pub', args,
      workingDirectory: consumerPackageFixtureInstance.projectRoot);
  String sassTaskStdErr = '';
  sassTaskProcess.stderr.listen((line) => sassTaskStdErr += '$line\n');

  await sassTaskProcess.done;
  final sassTaskExitCode = await sassTaskProcess.exitCode;
  return new SassCompileResult(sassTaskExitCode, sassTaskStdErr);
}

/// Generates a test fixture for use by `sass_test.dart` consisting of a fake consumer package
/// that depends on dart_dev, and has some .scss source files for the dart_dev sass task to compile into CSS.
class ConsumerPackageFixture {
  String get sourceDir => _sourceDir;
  String _sourceDir;

  String get sourceDirConfigValue => _sourceDirConfigValue;
  String _sourceDirConfigValue;

  String get outputDir => _outputDir;
  String _outputDir;

  String get outputDirConfigValue => _outputDirConfigValue;
  String _outputDirConfigValue;

  String get projectRoot => _projectRoot;
  String _projectRoot;

  String get projectName => 'fake_consumer_package';

  ConsumerPackageFixture({
    String sourceDir: wc.sourceDirDefaultValue,
    String sourceDirConfigValue,
    String outputDir: wc.outputDirDefaultValue,
    String outputDirConfigValue,
  }) {
    _sourceDir = sourceDir;
    _sourceDirConfigValue = sourceDirConfigValue;
    _outputDir = outputDir;
    _outputDirConfigValue = outputDirConfigValue;
    _projectRoot = '$consumerPackageFixtureRoot/$projectName';
  }

  void generate({bool includePubspec: true}) {
    if (includePubspec) {
      _createPubspecFile();
    }
    _createDevFile();
    _createSassEntryPointFile();
    _createSassRelativeImportFile();
    _createSassPackageImportFile();
  }

  void regenerate(
      {String newSourceDir = wc.sourceDirDefaultValue,
      String newSourceDirConfigValue,
      String newOutputDir = wc.outputDirDefaultValue,
      String newOutputDirConfigValue}) {
    final cssFilesPreviouslyGenerated =
        new Glob('${projectRoot}/**.css', recursive: true).listSync();
    for (var generatedCssFile in cssFilesPreviouslyGenerated) {
      generatedCssFile.deleteSync();
    }
    final cssMapFilesPreviouslyGenerated =
        new Glob('${projectRoot}/**.css.map', recursive: true).listSync();
    for (var generatedCssMapFile in cssMapFilesPreviouslyGenerated) {
      generatedCssMapFile.deleteSync();
    }

    _sourceDir = newSourceDir;
    _sourceDirConfigValue = newSourceDirConfigValue;
    _outputDir = newOutputDir;
    _outputDirConfigValue = newOutputDirConfigValue;
    generate(includePubspec: false);
  }

  void destroy() {
    final projectRootDir = new Directory(_projectRoot);
    if (projectRootDir.existsSync()) {
      projectRootDir.deleteSync(recursive: true);
    }
  }

  void _createDevFile() {
    final devFile =
        new File(path.join(path.join(_projectRoot, 'tool'), 'dev.dart'));
    if (!devFile.existsSync()) {
      devFile.createSync(recursive: true);
    }

    String configValues = '';
    if (sourceDirConfigValue != null) {
      configValues += 'config.sass.sourceDir = \'${sourceDirConfigValue}\';';
    }

    if (outputDirConfigValue != null) {
      configValues +=
          '\n  config.sass.outputDir = \'${outputDirConfigValue}\';';
    }

    devFile.writeAsStringSync('''
library tool.dev;

import 'package:dart_dev/dart_dev.dart';

main(args) async {
  $configValues
  await dev(args);
}
    ''');
  }

  void _createPubspecFile() {
    final pubspecFile = new File(path.join(_projectRoot, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      pubspecFile.createSync(recursive: true);
    }

    pubspecFile.writeAsStringSync('''
name: $projectName
version: 0.0.0
dev_dependencies:
  dart_dev:
    path: ../../..
    ''');
  }

  void _createSassEntryPointFile() {
    final sassEntryPointFile =
        new File(path.join(path.join(_projectRoot, sourceDir), 'test.scss'));
    if (!sassEntryPointFile.existsSync()) {
      sassEntryPointFile.createSync(recursive: true);
    }
    String packageLocation = sourceDir;
    if (sourceDir.startsWith('lib/')) {
      packageLocation = sourceDir.substring(4);
    }

    sassEntryPointFile.writeAsStringSync('''
.selector1 {
  color: black;
}

@import 'package:$projectName/${packageLocation}package_import';
@import 'relative_import';
    ''');
  }

  void _createSassRelativeImportFile() {
    final sassRelativeImportFile = new File(
        path.join(path.join(_projectRoot, sourceDir), '_relative_import.scss'));
    if (!sassRelativeImportFile.existsSync()) {
      sassRelativeImportFile.createSync(recursive: true);
    }

    sassRelativeImportFile.writeAsStringSync('''
.relative-import {
  color: blue;
}
    ''');
  }

  void _createSassPackageImportFile() {
    final sassPackageImportFile = new File(
        path.join(path.join(_projectRoot, sourceDir), '_package_import.scss'));
    if (!sassPackageImportFile.existsSync()) {
      sassPackageImportFile.createSync(recursive: true);
    }

    sassPackageImportFile.writeAsStringSync('''
.package-import {
  color: blue;
}
    ''');
  }
}

const String expectedUnMinifiedSource = '''.selector1 {
  color: black;
}

.package-import {
  color: blue;
}

.relative-import {
  color: blue;
}

/*# sourceMappingURL=test.css.map */''';

const String expectedMinifiedSource =
    '.selector1{color:#000}.package-import{color:blue}.relative-import{color:blue}\n\n/*# sourceMappingURL=test.css.map */';

void sharedCssOutputExpectations(String expectedCssDirectoryPath) {
  final expectedCssDir = new Directory(expectedCssDirectoryPath);
  expect(expectedCssDir.existsSync(), isTrue,
      reason: '$expectedCssDir does not exist.');
  expect(new Glob('${expectedCssDir.path}**.css', recursive: true).listSync(),
      isNotEmpty,
      reason: '$expectedCssDir does not have any CSS files in it.');
}

void createNonDefaultOutputDir(String dir) {
  final nonDefaultOutputDir = new Directory(dir);
  if (!nonDefaultOutputDir.existsSync()) {
    nonDefaultOutputDir.createSync(recursive: true);
  }

  addTearDown(() {
    nonDefaultOutputDir.deleteSync(recursive: true);
  });
}

void simulatePkgWithNoSassConfig() {
  consumerPackageFixtureInstance.regenerate();
}

void simulatePkgWithCustomSourceDirWithoutSassConfig() {
  consumerPackageFixtureInstance.regenerate(newSourceDir: nonDefaultSourceDir);
}

void simulatePkgWithCustomSourceDirWithSassConfig() {
  consumerPackageFixtureInstance.regenerate(
      newSourceDir: nonDefaultSourceDir,
      newSourceDirConfigValue: nonDefaultSourceDir);
}

void simulatePkgWithCustomSourceDirWithOverriddenSassConfig() {
  consumerPackageFixtureInstance.regenerate(
      newSourceDir: nonDefaultSourceDir,
      newSourceDirConfigValue: 'something_that_should_be_overridden/');
}

void simulatePkgWithCustomOutputDirWithSassConfig() {
  consumerPackageFixtureInstance.regenerate(
      newOutputDir: nonDefaultOutputDir,
      newOutputDirConfigValue: nonDefaultOutputDir);
}

void simulatePkgWithCustomOutputDirWithOverriddenSassConfig() {
  consumerPackageFixtureInstance.regenerate(
      newOutputDir: nonDefaultOutputDir,
      newOutputDirConfigValue: 'something_that_should_be_overridden/');
}

void simulatePkgWithCustomSourceAndOutputDirWithoutSassConfig() {
  consumerPackageFixtureInstance.regenerate(
      newSourceDir: nonDefaultSourceDir, newOutputDir: nonDefaultOutputDir);
}

void simulatePkgWithCustomSourceAndOutputDirWithSassConfig() {
  consumerPackageFixtureInstance.regenerate(
      newSourceDir: nonDefaultSourceDir,
      newOutputDir: nonDefaultOutputDir,
      newSourceDirConfigValue: nonDefaultSourceDir,
      newOutputDirConfigValue: nonDefaultOutputDir);
}

void simulatePkgWithCustomSourceAndOutputDirWithOverriddenSassConfig() {
  consumerPackageFixtureInstance.regenerate(
      newSourceDir: nonDefaultSourceDir,
      newOutputDir: nonDefaultOutputDir,
      newSourceDirConfigValue: 'some_source_dir_that_should_be_overridden/',
      newOutputDirConfigValue: 'some_output_dir_that_should_be_overridden/');
}
