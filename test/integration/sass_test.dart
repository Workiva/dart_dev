@TestOn('vm')
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

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:w_common/sass.dart' as wc;

import '../utils/sass_task_test_utils.dart';

void main() {
  group('sass task', () {
    setUpAll(() async {
      consumerPackageFixtureInstance = new ConsumerPackageFixture();
      consumerPackageFixtureInstance.generate();
      final ProcessResult initialPubGetProcess = await Process.run(
          'pub', ['get'],
          workingDirectory: consumerPackageFixtureInstance.projectRoot);
      expect(initialPubGetProcess.exitCode, 0,
          reason:
              '\nInitial pub get failed in the ${consumerPackageFixtureInstance.projectRoot} directory: \n${initialPubGetProcess.stderr}');
    });

    tearDownAll(() {
      consumerPackageFixtureInstance.destroy();
      consumerPackageFixtureInstance = null;
    });

    test(
        'should compile sass using the default sourceDir when no config is present',
        () async {
      simulatePkgWithNoSassConfig();
      final expectedCssDirectoryPath = path.join(
          consumerPackageFixtureInstance.projectRoot, wc.outputDirDefaultValue);
      expect(
          new File(path.join(expectedCssDirectoryPath, 'test.scss'))
              .existsSync(),
          isTrue,
          reason:
              'test.scss must exist within $expectedCssDirectoryPath for this test to be valid');

      final result = await compileConsumerSass();
      expect(result.exitCode, 0, reason: result.stdErr);
      sharedCssOutputExpectations(expectedCssDirectoryPath);
    });

    group('should compile sass as expected when a sourceDir is specified', () {
      setUp(() {
        expect(wc.sourceDirDefaultValue, isNot(nonDefaultSourceDir),
            reason:
                'This test has no point if the sourceDir is being set to the same path as what the script defaults to');
      });

      test('via the `config.sass.sourceDir` value in dev.dart', () async {
        simulatePkgWithCustomSourceDirWithSassConfig();
        final expectedCssDirectoryPath = path.join(
            consumerPackageFixtureInstance.projectRoot, nonDefaultSourceDir);
        expect(
            new File(path.join(expectedCssDirectoryPath, 'test.scss'))
                .existsSync(),
            isTrue,
            reason:
                'test.scss must exist within $expectedCssDirectoryPath for this test to be valid');

        final result = await compileConsumerSass();
        expect(result.exitCode, 0, reason: result.stdErr);
        sharedCssOutputExpectations(expectedCssDirectoryPath);
      });

      group('via CLI argument', () {
        test('when there is no `config.sass.sourceDir` value in dev.dart',
            () async {
          simulatePkgWithCustomSourceDirWithoutSassConfig();
          final expectedCssDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultSourceDir);
          expect(
              new File(path.join(expectedCssDirectoryPath, 'test.scss'))
                  .existsSync(),
              isTrue,
              reason:
                  'test.scss must exist within $expectedCssDirectoryPath for this test to be valid');

          final result = await compileConsumerSass(
              additionalArgs: ['--sourceDir=$nonDefaultSourceDir']);
          expect(result.exitCode, 0, reason: result.stdErr);
          sharedCssOutputExpectations(expectedCssDirectoryPath);
        });

        test(
            'when there is a different `config.sass.sourceDir` value in dev.dart',
            () async {
          simulatePkgWithCustomSourceDirWithOverriddenSassConfig();
          final expectedCssDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultSourceDir);
          expect(
              new File(path.join(expectedCssDirectoryPath, 'test.scss'))
                  .existsSync(),
              isTrue,
              reason:
                  'test.scss must exist within $expectedCssDirectoryPath for this test to be valid');

          final result = await compileConsumerSass(
              additionalArgs: ['--sourceDir=$nonDefaultSourceDir']);
          expect(result.exitCode, 0, reason: result.stdErr);
          sharedCssOutputExpectations(expectedCssDirectoryPath);
        });
      });
    });

    group('should compile sass as expected when an outputDir is specified', () {
      setUp(() {
        expect(wc.outputDirDefaultValue, isNot(nonDefaultOutputDir),
            reason:
                'This test has no point if the outputDir is being set to the same path as what the script defaults to');
      });

      test('via the `config.sass.outputDir` value in dev.dart', () async {
        simulatePkgWithCustomOutputDirWithSassConfig();
        final expectedCssDirectoryPath = path.join(
            consumerPackageFixtureInstance.projectRoot, nonDefaultOutputDir);
        final expectedSourceDirectoryPath = path.join(
            consumerPackageFixtureInstance.projectRoot,
            wc.sourceDirDefaultValue);
        expect(
            new File(path.join(expectedSourceDirectoryPath, 'test.scss'))
                .existsSync(),
            isTrue,
            reason:
                'test.scss must exist within $expectedSourceDirectoryPath for this test to be valid');
        createNonDefaultOutputDir(expectedCssDirectoryPath);

        final result = await compileConsumerSass();
        expect(result.exitCode, 0, reason: result.stdErr);
        sharedCssOutputExpectations(expectedCssDirectoryPath);
      });

      group('via CLI argument', () {
        test('when there is no `config.sass.outputDir` value in dev.dart',
            () async {
          simulatePkgWithNoSassConfig();
          final expectedCssDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultOutputDir);
          final expectedSourceDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot,
              wc.sourceDirDefaultValue);
          expect(
              new File(path.join(expectedSourceDirectoryPath, 'test.scss'))
                  .existsSync(),
              isTrue,
              reason:
                  'test.scss must exist within $expectedSourceDirectoryPath for this test to be valid');
          createNonDefaultOutputDir(expectedCssDirectoryPath);

          final result = await compileConsumerSass(
              additionalArgs: ['--outputDir=$nonDefaultOutputDir']);
          expect(result.exitCode, 0, reason: result.stdErr);
          sharedCssOutputExpectations(expectedCssDirectoryPath);
        });

        test(
            'when there is a different `config.sass.sourceDir` value in dev.dart',
            () async {
          simulatePkgWithCustomOutputDirWithOverriddenSassConfig();
          final expectedCssDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultOutputDir);
          final expectedSourceDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot,
              wc.sourceDirDefaultValue);
          expect(
              new File(path.join(expectedSourceDirectoryPath, 'test.scss'))
                  .existsSync(),
              isTrue,
              reason:
                  'test.scss must exist within $expectedSourceDirectoryPath for this test to be valid');
          createNonDefaultOutputDir(expectedCssDirectoryPath);

          final result = await compileConsumerSass(
              additionalArgs: ['--outputDir=$nonDefaultOutputDir']);
          expect(result.exitCode, 0, reason: result.stdErr);
          sharedCssOutputExpectations(expectedCssDirectoryPath);
        });
      });
    });

    group(
        'should compile sass as expected when sourceDir and outputDir are both specified',
        () {
      setUp(() {
        expect(wc.sourceDirDefaultValue, isNot(nonDefaultSourceDir),
            reason:
                'This test has no point if the sourceDir is being set to the same path as what the script defaults to');
        expect(wc.outputDirDefaultValue, isNot(nonDefaultOutputDir),
            reason:
                'This test has no point if the outputDir is being set to the same path as what the script defaults to');
      });

      test('via the `config.sass` values in dev.dart', () async {
        simulatePkgWithCustomSourceAndOutputDirWithSassConfig();
        final expectedCssDirectoryPath = path.join(
            consumerPackageFixtureInstance.projectRoot, nonDefaultOutputDir);
        final expectedSourceDirectoryPath = path.join(
            consumerPackageFixtureInstance.projectRoot, nonDefaultSourceDir);
        expect(
            new File(path.join(expectedSourceDirectoryPath, 'test.scss'))
                .existsSync(),
            isTrue,
            reason:
                'test.scss must exist within $expectedSourceDirectoryPath for this test to be valid');
        createNonDefaultOutputDir(expectedCssDirectoryPath);

        final result = await compileConsumerSass();
        expect(result.exitCode, 0, reason: result.stdErr);
        sharedCssOutputExpectations(expectedCssDirectoryPath);
      });

      group('via CLI argument', () {
        test('when there is no `config.sass.sourceDir` value in dev.dart',
            () async {
          simulatePkgWithCustomSourceAndOutputDirWithoutSassConfig();
          final expectedCssDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultOutputDir);
          final expectedSourceDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultSourceDir);
          expect(
              new File(path.join(expectedSourceDirectoryPath, 'test.scss'))
                  .existsSync(),
              isTrue,
              reason:
                  'test.scss must exist within $expectedSourceDirectoryPath for this test to be valid');
          createNonDefaultOutputDir(expectedCssDirectoryPath);

          final result = await compileConsumerSass(additionalArgs: [
            '--sourceDir=$nonDefaultSourceDir',
            '--outputDir=$nonDefaultOutputDir',
          ]);
          expect(result.exitCode, 0, reason: result.stdErr);
          sharedCssOutputExpectations(expectedCssDirectoryPath);
        });

        test(
            'when there is a different `config.sass.sourceDir` value in dev.dart',
            () async {
          simulatePkgWithCustomSourceAndOutputDirWithOverriddenSassConfig();
          final expectedCssDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultOutputDir);
          final expectedSourceDirectoryPath = path.join(
              consumerPackageFixtureInstance.projectRoot, nonDefaultSourceDir);
          expect(
              new File(path.join(expectedSourceDirectoryPath, 'test.scss'))
                  .existsSync(),
              isTrue,
              reason:
                  'test.scss must exist within $expectedSourceDirectoryPath for this test to be valid');
          createNonDefaultOutputDir(expectedCssDirectoryPath);

          final result = await compileConsumerSass(additionalArgs: [
            '--sourceDir=$nonDefaultSourceDir',
            '--outputDir=$nonDefaultOutputDir',
          ]);
          expect(result.exitCode, 0, reason: result.stdErr);
          sharedCssOutputExpectations(expectedCssDirectoryPath);
        });
      });
    });

    group('when the -r flag is set', () {
      group('should verify that the checked-in unminified source is up-to-date',
          () {
        String generatedCssFilePath;
        String scssSourceFilePath;
        File generatedCssFile;

        setUp(() {
          simulatePkgWithNoSassConfig();
        });

        group('and compile a minified version of the file if it is', () {
          setUp(() async {
            final sourceDir = path.join(
                consumerPackageFixtureInstance.projectRoot,
                consumerPackageFixtureInstance.sourceDir);
            scssSourceFilePath = path.join(sourceDir, 'test.scss');
            generatedCssFilePath = path.join(sourceDir, 'test.css');
            await compileConsumerSass();
            generatedCssFile = new File(generatedCssFilePath);
            expect(generatedCssFile.existsSync(), isTrue,
                reason: '$generatedCssFilePath should have been generated');
            expect(
                generatedCssFile.readAsStringSync(), expectedUnMinifiedSource,
                reason:
                    'The unminified CSS source is different than what these tests will expect');
          });

          test('', () async {
            final result = await compileConsumerSass(additionalArgs: ['-r']);
            expect(result.exitCode, 0, reason: result.stdErr);

            generatedCssFile = new File(generatedCssFilePath);
            expect(generatedCssFile.existsSync(), isTrue,
                reason: '$generatedCssFilePath should have been generated');
            expect(generatedCssFile.readAsStringSync(), expectedMinifiedSource,
                reason: 'The CSS source should have been minified');
          });
        });

        test('and fail the build if it is not', () async {
          new File(scssSourceFilePath)
              .writeAsStringSync('.modified { display: none; }');
          final result = await compileConsumerSass(additionalArgs: ['-r']);
          expect(result.exitCode, isNot(0));
        });
      });
    });
  });
}
