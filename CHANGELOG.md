# Changelog

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
