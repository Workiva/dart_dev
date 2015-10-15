# Changelog

## 1.0.2

- **Improvement:** The copy-license task now trims empty leading and trailing lines when.
- **Bug Fix:** Coverage task no longer incorrectly ignores test files that don't end in `_test.dart`.

## 1.0.1

### New Task: `docs`

- `ddev docs` or `pub run dart_dev docs`
- Documentation generation via the [dartdoc](https://github.com/dart-lang/dartdoc)
  package.
  
### Changes

- **Improvement:** The `coverage` task now checks for the `lcov` dependency before trying to
  generate the HTML report. If missing, installation instructions are given.
- **Improvement:** The dependency range for the `dart_style` package has been widened to
  `>=0.1.8 <0.3.0` to avoid dependency version conflicts.
- **Bug Fix:** Fixed a bug that could prevent the HTML coverage report from being opened
  automatically.
- **Bug Fix:** When running the `examples` task, pub serve errors no longer cause the process
  to exit prematurely.

## 1.0.0
- Initial version of dart_dev
