# `TestTool`

Runs dart tests for the current project.

## Usage

> _This tool is included in the [`coreConfig`][core-config] and is runnable by
> default via `ddev test`._

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'test': TestTool() // configure as necessary
};
```

## `test` vs `build_runner test`

Historically, `dart run test` has been the canonical way to run Dart tests.
With the introduction of the [build system][build-system], there is now a second
way to run tests. Projects that rely on builder outputs must run tests via
`dart run build_runner test`.

The `TestTool` will make this choice for you. If the current project has a
dependency on `build_test`, it will run `dart run build_runner test`. Otherwise
it will default to running `dart run test`.

> It [appears][test-future] as though the long term goal is to integrate the
> build system into the test runner so that `dart run test` is once again the
> canonical way to run tests.

## Default behavior

By default this tool will run `dart run test`, unless there is a dependency on
`build_test`, in which case it will run `dart run build_runner test`.

## Running a subset of tests

When developing it is common to want to run a targeted subset of tests. The test
runner supports targeting tests by path(s), preset(s), or by matching
against the test descriptions. These common command-line options are available
when running the `TestTool` via `ddev test`, as well.

```bash
$ ddev help test
Run dart tests in this package.

Usage: dart_dev test [files or directories...]
======== Selecting Tests
-n, --name              A substring of the name of the test to run.
                        Regular expression syntax is supported.
                        If passed multiple times, tests must match all substrings.

-N, --plain-name        A plain-text substring of the name of the test to run.
                        If passed multiple times, tests must match all substrings.

======== Running Tests
-P, --preset            The configuration preset(s) to use.
    --[no-]release      Build with release mode defaults for builders.
                        This only applies in projects that run tests with build_runner.

======== Output
    --reporter          The runner used to print test results.

          [compact]     A single line, updated continuously.
          [expanded]    A separate line for each update.
          [json]        A machine-readable format (see https://goo.gl/gBsV1a).

======== Other Options
    --test-stdout       Write the test process stdout to this file path.
    --test-args         Args to pass to the test runner process.
                        Run "dart run test -h -v" to see all available options.

    --build-args        Args to pass to the build runner process.
                        Run "dart run build_runner test -h -v" to see all available options.
                        Note: these args are only applicable if the current project depends on "build_test".

-h, --help              Print this usage information.
```

Additionally, in projects that use `build_runner` to run tests, the `TestTool`
will automatically apply [build filters][build-filters] so that the build system
_only_ builds the set of outputs necessary for running the targeted test paths.
In large projects, this can significantly reduce the build time which makes
iterating on tests much more efficient.

```bash
$ ddev test test/foo/bar/ test/baz_test.dart
[INFO] Running subprocess:
dart run build_runner test --build-filter=test/foo/bar/** --build-filter=test/baz_test.dart.*_test.dart.js --build-filter=test/baz_test.html -- test/foo/bar/ test/baz_test.dart
----------------------------------------------------------------------------
```

## Collecting coverage

The test package now has partial support for [coverage collection][coverage]
built-in. As of now, it is only supported for tests run on the Dart VM. Follow
[this issue][coverage-issue] for updates on implementing coverage collection for
tests run in Chrome.

There are plans to add a "coverage" mode to the `TestTool` that will pass the
coverage directory to the test command and handle formatting the coverage output
to a more consumable format like lcov. It will optionally generate and open an
HTML report using the `genhtml` tool.

## Configuration

> Always prefer configuring the test runner via
> [`dart_test.yaml`][dart-test-yaml] when possible. This ensures that other
> tools that leverage the test runner benefit from the configuration, as well.

### Passing args to the test process

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'test': TestTool()
    ..testArgs = ['--no-chain-stack-traces']
};
```

### Passing args to the build_runner process

_Note that this is only applicable in projects that run tests via
`build_runner`._

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'test': TestTool()
    ..buildArgs = ['--delete-conflicting-outputs']
};
```

## Command-line options

```bash
$ ddev help test
```

[build-filters]: https://github.com/dart-lang/build/blob/master/build_runner/CHANGELOG.md#new-feature-build-filters
[build-system]: https://github.com/dart-lang/build
[core-config]: /lib/src/core_config.dart
[coverage]: https://github.com/dart-lang/test/blob/master/pkgs/test/README.md#collecting-code-coverage
[coverage-issue]: https://github.com/dart-lang/test/issues/36
[dart-test-yaml]: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md
[test-future]: https://github.com/dart-lang/build/pull/2415#issuecomment-530114943

---
---

<!-- Table of Contents -->

- Tools
  - [`AnalyzeTool`][analyze-tool]
  - [`FormatTool`][format-tool]
  - [`TestTool`][test-tool]
  - [`TuneupCheckTool`][tuneup-check-tool]
  - [`WebdevServeTool`][webdev-serve-tool]
- [Creating, Extending, and Composing Tools][tool-composition]
- [v3 upgrade guide][v3-upgrade-guide]

<!-- Table of Contents Links -->
[analyze-tool]: /doc/tools/analyze-tool.md
[tuneup-check-tool]: /doc/tools/tuneup-check-tool.md
[dart-function-tool]: /doc/tools/dart-function-tool.md
[format-tool]: /doc/tools/format-tool.md
[process-tool]: /doc/tools/process-tool.md
[test-tool]: /doc/tools/test-tool.md
[webdev-build-tool]: /doc/tools/webdev-build-tool.md
[webdev-serve-tool]: /doc/tools/webdev-serve-tool.md
[tool-composition]: /doc/tool-composition.md
[v3-upgrade-guide]: /doc/v3-upgrade-guide.md
