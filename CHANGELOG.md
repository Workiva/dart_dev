# Changelog

## [2.0.0](https://github.com/Workiva/dart_dev/compare/1.10.1...2.0.0)
_October 9, 2018_

- **BREAKING CHANGE:** `docs`, `examples`, and `saucelabs` tasks have been removed.

- **BREAKING CHANGE:** `ExamplesTask` and `serveExamples` have been removed from
  the `package:dart_dev/api.dart` entry point.

- **BREAKING CHANGE:** `SaucePlatform` and the constant platform instances have
  been removed from the `package:dart_dev/dart_dev.dart` entry point.

- **Improvement:** Dart 2 compatible!

  _Notable change to the `test` task:_ Pub serve functionality is now ignored when
  running the `test` task, as that functionality was removed from the pub executable
  as a part of the Dart 2.0.0 SDK release. To accommodate this change, the `test`
  task will now run tests via `build_runner test` when on Dart 2 and when `build_test`
  is found in your package's `pubspec.yaml`.

  _Caveat:_ The `coverage` task exits with a non-zero exit code immediately when
  run on Dart2, as there is not yet any support for collecting coverage from browser
  tests.

## [1.10.1](https://github.com/Workiva/dart_dev/compare/1.10.0...1.10.1)
_October 9, 2018_

- **Deprecations:** The following members of the `package:dart_dev/dart_dev.dart`
  entry point have been deprecated and will be removed in 2.0.0:

    * `SaucePlatform`
    * `const SaucePlatform chrome`
    * `const SaucePlatform chromeWindows`
    * `const SaucePlatform chromeOsx`
    * `const SaucePlatform firefoxWindows`
    * `const SaucePlatform firefoxOsx`
    * `const SaucePlatform safari`
    * `const SaucePlatform ie10`
    * `const SaucePlatform ie11`

## [1.10.0](https://github.com/Workiva/dart_dev/compare/1.9.6...1.10.0)
_October 8, 2018_

- **New Tasks:** `dart1-only` and `dart2-only`

    Use these tasks to conditionally run another dart_dev task or an arbitrary
    shell command _only_ when running on Dart1 or Dart2.

    ```bash
    # Run a dart_dev task only on Dart1:
    $ ddev dart1-only test

    # Run a dart_dev task with additional args only on Dart1:
    $ ddev dart1-only -- format --check

    # Run an shell script only on Dart1:
    $ ddev dart1-only ./example.sh

    # Run an executable with additional args only on Dart1:
    $ ddev dart1-only -- pub serve web --port 8080

    # The `dart2-only` task works exactly the same, but only runs on Dart2:
    $ ddev dart2-only test
    $ ddev dart2-only -- format --check
    $ ddev dart2-only ./example.sh
    $ ddev dart2-only -- pub run build_runner serve web:8080
    ```

- **Deprecated Tasks:** `docs`, `examples`, and `saucelabs`.

    These three tasks have been deprecated and will be removed in 2.0.0.

## [1.1.2](https://github.com/Workiva/dart_dev/compare/1.1.1...1.1.2)
_March 22, 2016_

- **Bug fix:** The test reporter output now respects the `--no-color` flag.

- **Bug fix:** The test task was previously running the unit test suite even
  when it was disabled. This has been fixed. Additionally, passing in individual
  test files/directories overrides the unit and integration suites.

## [1.1.1](https://github.com/Workiva/dart_dev/compare/1.1.0...1.1.1)
_February 24, 2016_

- **Bug fix:** 1.1.0 introduced a regression that caused the test task to no
  longer default to running the unit test suite and instead run all tests in the
  `test/` directory when the `--unit` flag was not explicitly set. This has been
  fixed and should match the behavior from before 1.1.0.

## [1.1.0](https://github.com/Workiva/dart_dev/compare/1.0.6...1.1.0)
_February 23, 2016_

- **Improvement:** Set the coverage task's exit code to non-zero when a test
  fails.

- **Improvement:** Add support for the `-n, --name` arg for the test task.

- **Bug fix:** Catch and silence exception when reading a non-utf8 file during
  the copy-license task.

- **Bug fix:** Make sure the test task observes the `--no-unit` flag.


## [1.0.6](https://github.com/Workiva/dart_dev/compare/1.0.5...1.0.6)
_December 16, 2015_

- **Improvement:** `--strong` flag added to the Analyze task.

- **Improvement:** The Analyze task's `--fatal-hints` flag is now implemented
   by utilizing the `--fatal-hints` flag on `dartanalyzer` instead of parsing
   the output.

- **Documentation:** Add zsh completion instructions to the README.

## [1.0.5](https://github.com/Workiva/dart_dev/compare/1.0.4...1.0.5)
_November 25, 2015_

### New Feature: pub server support for tests and coverage

- The Test and Coverage tasks now take a `--pub-serve` flag that will
  automatically spin up a pub server that is used to run the tests.

- Tests that require a pub transformer can now be run by passing in this flag!

### Changes

- **Improvement:** `--fatal-hints` flag added to the Analyze task.

## [1.0.4](https://github.com/Workiva/dart_dev/compare/1.0.3...1.0.4)
_November 20, 2015_

- **Tooling:** Bash completions are available in the `tool/` directory! See the
  README for installation instructions.

- **Bug Fix:** Dart 1.13 introduced a change to the `dart2js` output on which
  the coverage task relied for `dart:html` detection. This has been fixed.

## [1.0.3](https://github.com/Workiva/dart_dev/compare/1.0.2...1.0.3)
_November 12, 2015_

- **Improvement:** The test task can now run individual test files:

    ```
    ddev test test/path/to/test.dart
    ```

- **Improvement:** Widen the `dartdoc` dependency range.

## [1.0.2](https://github.com/Workiva/dart_dev/compare/1.0.1...1.0.2)
_October 15, 2015_

- **Improvement:** The copy-license task now trims empty leading and trailing
  lines.

- **Bug Fix:** Coverage task no longer incorrectly ignores test files that don't
  end in `_test.dart`.

## [1.0.1](https://github.com/Workiva/dart_dev/compare/1.0.0...1.0.1)
_September 8, 2015_

### New Task: `docs`

- `ddev docs` or `pub run dart_dev docs`

- Documentation generation via the
  [dartdoc](https://github.com/dart-lang/dartdoc) package.
  
### Changes

- **Improvement:** The `coverage` task now checks for the `lcov` dependency
  before trying to generate the HTML report. If missing, installation
  instructions are given.

- **Improvement:** The dependency range for the `dart_style` package has been
  widened to `>=0.1.8 <0.3.0` to avoid dependency version conflicts.

- **Bug Fix:** Fixed a bug that could prevent the HTML coverage report from
  being opened automatically.

- **Bug Fix:** When running the `examples` task, pub serve errors no longer
  cause the process to exit prematurely.

## [1.0.0](https://github.com/Workiva/dart_dev/compare/cce304913325701f9a1058d63ba4a55f877a3baa...1.0.0)
_August 20, 2015_

- Initial version of dart_dev
