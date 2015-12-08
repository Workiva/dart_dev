# Changelog

## 1.0.6

- **Improvement:** `--strong` flag added to the Analyze task.
- **Improvement:** The Analyze task's `--fatal-hints` flag is now implemented
   by utilizing the `--fatal-hints` flag on `dartanalyzer` instead of parsing
   the output.
- **Documentation:** Add zsh completion instructions to the README.

## 1.0.5

### New Feature: pub server support for tests and coverage

- The Test and Coverage tasks now take a `--pub-serve` flag that will
  automatically spin up a pub server that is used to run the tests.
- Tests that require a pub transformer can now be run by passing in this flag!

### Changes

- **Improvement:** `--fatal-hints` flag added to the Analyze task.

## 1.0.4

- **Tooling:** Bash completions are available in the `tool/` directory! See the
  README for installation instructions.
- **Bug Fix:** Dart 1.13 introduced a change to the `dart2js` output on which
  the coverage task relied for `dart:html` detection. This has been fixed.

## 1.0.3

- **Improvement:** The test task can now run individual test files:
  - `ddev test test/path/to/test.dart`
- **Improvement:** Widen the `dartdoc` dependency range.

## 1.0.2

- **Improvement:** The copy-license task now trims empty leading and trailing
  lines.
- **Bug Fix:** Coverage task no longer incorrectly ignores test files that don't
  end in `_test.dart`.

## 1.0.1

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

## 1.0.0
- Initial version of dart_dev
