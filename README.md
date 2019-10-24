# Dart Dev Tools

[![Pub](https://img.shields.io/pub/v/dart_dev.svg)](https://pub.dartlang.org/packages/dart_dev)
[![Build Status](https://travis-ci.org/Workiva/dart_dev.svg?branch=master)](https://travis-ci.org/Workiva/dart_dev)

Centralized tooling for Dart projects. Consistent interface across projects.
Easily configurable.

---

- [Quick Start](#quick-start)
- [Motivation & Goal](#motivation--goal)
- [Project-Level Configuration](#project-level-configuration)
- [Extending/Composing Functionality](#extendingcomposing-functionality)
- [Shared Configuration](#shared-configuration)
- [Additional Docs][docs]

## Quick Start

> Upgrading from v2? Check out the [upgrade guide][upgrade-guide].

> Looking for detailed guides on the available tools? Check out the
> [additional docs][docs].

Add `dart_dev` as a dev dependency in your project:

```yaml
# pubspec.yaml
dev_dependencies:
  dart_dev: ^3.0.0
```

By default, this provides three core tasks:

- `analyze`
- `format`
- `test`

Run any of these tools via the `dart_dev` command-line app:

```bash
$ pub run dart_dev analyze
[INFO] Running subprocess:
dartanalyzer .
--------------------------
Analyzing dart_dev...
No issues found!
```

> We recommend adding a `ddev` alias:
>
> ```bash
> alias ddev='pub run dart_dev'
> ```

Additional Dart developer tools can be added and every tool can be configured.
To do this, create a `tool/dart_dev/config.dart` file like so:

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  // See the "Shared Configuration" section for more info on this.
  ...coreConfig,

  // Override or add new tools and configure them as desired.
  'analyze': AnalyzeTool(),
  'format': FormatTool(),
  'test': TestTool(),
  'serve': WebdevServeTool()
    ..webdevArgs = ['example:8080'],
};
```

## Motivation & Goal

Most Dart projects eventually share a common set of development requirements
(e.g. static analysis, formatting, test running, serving, etc.). The Dart SDK
along with some core packages supply the necessary tooling for these developer
tasks (e.g. `dartanalyzer`, `dartfmt`, or `pub run test`).

While the core tooling gets us far, there are two areas in which we feel it
falls short:

1. Inconsistencies across projects in how these tools must be used in order to
   to accomplish common developer tasks.

2. Functionality gaps for more complex use cases.

With `dart_dev`, we attempt to address #1 by providing a way to configure all of
these common developer tasks at the project level, and #2 by composing
additional functionality around existing tools.

This package is built with configurability and extensiblity in mind, with the
hope that you and your teams will find value in creating your own tools and
shared configurations. Ideally, you or your team can settle on a shared
configuration that individual projects can consume; projects with unique
requirements can tweak the configuration as necessary; and developers can rely
on the convention of a simple, consistent command-line interface regardless of
the project they are in.

## Project-Level Configuration

Every task should be able to be configured at the project-level so that any
variance across projects becomes a configuration detail that need not be
memorized or referenced in order to run said task.

Consider formatting as an example. The default approach to formatting files is
to run `dartfmt -w .`. But, some projects may want to exclude certain files that
would otherwise be formatted by this command. Or, some projects may want to use
`pub run dart_style:format` instead of `dartfmt`. Currently, there is no
project-level configuration supported by the formatter, so these sorts of things
just have to be documented in a `README.md` or `CONTRIBUTING.md`.

With `dart_dev`, this can be accomplished like so:

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';
import 'pacakge:glob/glob.dart';

final config = {
  'format': FormatTool()
    ..exclude = [Glob('lib/src/**.g.dart')]
    ..formatter = Formatter.dartStyle,
};
```

```bash
$ ddev format
[INFO] Running subprocess:
pub run dart_style:format -w <3 paths>
--------------------------------------
Unchanged ./lib/foo.dart
Unchanged ./lib/src/bar.dart
Formatted ./lib/src/baz.dart
```

## Extending/Composing Functionality

Using existing tooling provided by (or conventionalized by) the Dart community
should always be the goal, but the reality is that there are gaps. Certain use
cases can be made more convenient and new use cases may arise.

Consider test running as an example. For simple projects, `pub run test` is
sufficient. In fact, the test package supports a huge amount of project-level
configuration via `dart_test.yaml`, which means that for projects that are
properly configured, `pub run test` just works.

Unfortunately, at this time, projects that rely on builders must run tests via
`pub run build_runner test`. Based on the project, you would need to know which
test command should be run.

With `dart_dev`, the `TestTool` handles this automatically by checking the
project's `pubspec.yaml` for a dependency on `build_test`. If present, tests
will be run via `pub run build_runner test`, otherwise it falls back to the
default of `pub run test`.

```bash
# In a project without a `build_test` dependency:
$ ddev test
[INFO] Running subprocess:
pub run test
----------------------------
00:01 +75: All tests passed!


# In a project with a `build_test` dependency:
$ ddev test
[INFO] Running subprocess:
pub run build_runner test
----------------------------
[INFO] Generating build script completed, took 425ms
[INFO] Creating build script snapshot... completed, took 13.6s
[INFO] Building new asset graph completed, took 960ms
[INFO] Checking for unexpected pre-existing outputs. completed, took 1ms
[INFO] Running build completed, took 12.4s
[INFO] Caching finalized dependency graph completed, took 71ms
[INFO] Creating merged output dir `/var/folders/vb/k8ccjw095q16jrwktw31ctmm0000gn/T/build_runner_testBkm6gS/` completed, took 260ms
[INFO] Writing asset manifest completed, took 3ms
[INFO] Succeeded after 12.8s with 1276 outputs (2525 actions)
Running tests...

00:00 +75: All tests passed!
```

Additionally, `TestTool` automatically applies [`--build-filter`][build-filter]
options to the `pub run build_runner test` command to help reduce build time and
speed up dev iteration when running a subset of the available tests.

Generally speaking, these dart tool abstractions provide a place to address
functionality gaps in the underlying tools or make certain use cases more
convenient or efficient.

## Shared Configuration

This package provides `coreConfig` as a minimal base configuration of `dart_dev`
tools. It is the default configuration if your project does not have a
`tool/dart_dev/config.dart`.

This shared config contains the following targets:

- `ddev analyze`
- `ddev format`
- `ddev test`

The actual configuration of each of these targets can be found here:
[`lib/src/core_config.dart`][core-config]

`coreConfig` is just a getter that returns a `Map<String, DevTool>` object, so
extending it or customizing it is as easy as creating your own `Map`, spreading
the shared config, and then adding your own entries:

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  ...coreConfig,

  // Override a target by including it after `...coreConfig`:
  'format': FormatTool()
    ..formatter = Formatter.dartStyle,

  // Add a custom target:
  'github': ProcessTool(
      'open', ['https://github.com/Workiva/dart_dev']),

  // etc.
};
```

[api-docs]: https://pub.dev/documentation/dart_dev/latest/dart_dev/dart_dev-library.html
[build-filter]: https://github.com/dart-lang/build/blob/master/build_runner/CHANGELOG.md#new-feature-build-filters
[core-config]: https://github.com/Workiva/dart_dev/blob/master/lib/src/core_config.dart
[docs]: https://github.com/Workiva/dart_dev/blob/master/doc/
[upgrade-guide]: https://github.com/Workiva/dart_dev/blob/master/doc/v3-upgrade-guide.md
