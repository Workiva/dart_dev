# Upgrading from v2 to v3

Nothing fundamental has changed in terms of the goal of this package. However,
v3 _is_ a breaking release and as a consumer, your project configuration file
will need to be updated in order to consume it.

The updated [readme] is a good place to start. It provides a refreshed overview
of dart_dev and how it works. Once you've read that, this guide will hopefully
help draw connections from the old to the new with some examples.

## Configuration File & Syntax

With v2, the `package:dart_dev/dart_dev.dart` entrypoint exported a mutable
`config` object with sub-objects for each configurable task. The `tool/dev.dart`
file would feature a `main()` block that configured the `config` object as
needed.

```dart
// tool/dev.dart -- v2
import 'package:dart_dev/dart_dev.dart';

void main(args) async {
  config
    ..format.paths = ['lib/', 'test/']
    ..test.unitTests = ['test/unit/'];
  await dev(args);
}
```

In v3, dart_dev now expects a top-level `Map<String, DevTool> config` getter to
exist in `tool/dart_dev/config.dart`. The keys in this map are the command names
(i.e. a key of `format` means that it is runnable via `ddev format`), and the
values are the implementations of the tool.

```dart
// tool/dart_dev/config.dart -- v3
import 'package:dart_dev/dart_dev.dart';

final config = {
  'analyze': AnalyzeTool()..analyzerArgs = ['--fatal-hints'],
  'format': FormatTool(),
  'serve': WebdevServeTool()..webdevArgs = ['web:9000'],
  'test': TestTool(),
};
```

This updated config pattern has a couple of important differences:

- The available commands are completely configurable. With v2, we were pretty
  much locked into the commands defined in this package. There was some
  rudimentary support for "local tasks" defined in the `tool/` directory, but
  those were not then easily shared. In v3 you have complete control, which
  makes it much easier to extend or compose functionality.

- There is no `main()` block, which makes the setup a bit simpler (you don't
  have to call `dev(args)`). Any runtime logic that previously lived in this
  `main()` block can be moved either to top-level variable declarations or
  functions that are then called by one or more `DevTool`s.

## v2 Tasks

The core tasks supported in v2 are still available in v3, but some have been
intentionally left behind.

### Analyze, Format, and Test

These are the core developer tasks and they are still available by default via
`ddev analyze`, `ddev format`, and `ddev test`. If you are using the shared
`coreConfig`, they are included there, as well. If you would like to configure
these tools further, you can do so:

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  // Construct the tool instances and configure their fields as desired.
  'analyze': AnalyzeTool(),
  'format': FormatTool(),
  'test': TestTool(),
};
```

### `ddev copy-license`

This task is not specific to Dart development and would be more useful as a
separate, general-purpose tool. In fact, some already exist. At this time, there
are no plans to add this functionality back to v3.

### `ddev coverage`

Coverage collection facilitated by the `test` package is [planned and partially
in progress][coverage]. As soon as the `--coverage` option is available, we have
plans to complement the coverage collection with automatic coverage formatting
and HTML report generation.

Instead of this being a separate task, it will likely just be a flag:

```bash
$ ddev test --coverage
```

### `ddev dart1-only / dart2-only`

These tasks were provided as a convenience for the migration from dart 1 to dart
2 and are no longer provided as v3 only supports dart 2.

### `ddev gen-test-runner`

Generating aggregated test suites/runners is no longer supported. The original
impetus behind these generated runners was to speed up full test runs by only
having to load one (or a few) test suites, but the startup time for individual
test files has improved since then (probably ~3 years ago) and this is no longer
as much of a concern. Additionally, treating every test file as its own suite
has the advantage of being able to run each test file on its own (IDEs now
support doing this directly from the test file) and allows us to leverage
features like build_runner's `--build-filter` for large projects to speed up
rebuild time when iterating on a subset of tests.

There was one particularly useful feature of generated test runners, which was
being able to share an HTML file – you wouldn't have to litter your `test/`
directory with an HTML file for every test that requires it (common with
over_react consumers). The [`test_html_builder` package][test-html-builder] was
created to serve this specific use case.

### `ddev init`

In v3, the boilerplate for `tool/dart_dev/config.dart` is pretty minimal and if
omitted altogether the shared `coreConfig` will be used by default. For projects
that do want to configure, it is easy to copy & paste from other projects or the
readme.

### `ddev task-runner`

This is not specific to dart development and has been removed from dart_dev. We
recommend using the [GNU Parallel tool][parallel] as a replacement. It can be
installed with pretty much any package manager (e.g. `brew install parallel`)
and is much more fully-featured.

### `ddev sass`

There now exists a [`sass_builder` package][sass-builder] that can handle automatically
compiling your SASS files via the dart 2 build system.

> Workiva developers: for the time being, a `ddev sass` target is still
> available via the `dart_dev_workiva` package and should be used. Once we
> address the root cause of slow compilation of our shared SASS libraries via
> `sass_builder`, we will switch.

[coverage]: https://github.com/dart-lang/test/issues/36
[parallel]: https://www.gnu.org/software/parallel/
[readme]: /README.md
[sass-builder]: https://pub.dev/packages/sass_builder
[test-html-builder]: https://pub.dev/packages/test_html_builder

---
---

<!-- Table of Contents -->

- Tools
  - [`AnalyzeTool`][analyze-tool]
  - [`DartFunctionTool`][dart-function-tool]
  - [`FormatTool`][format-tool]
  - [`ProcessTool`][process-tool]
  - [`TestTool`][test-tool]
  - [`TuneupCheckTool`][tuneup-check-tool]
  - [`WebdevBuildTool`][webdev-build-tool]
  - [`WebdevServeTool`][webdev-serve-tool]
- Tool utilities
  - [`chainTool()`][chain-tool]
  - [`setUpTool()`][set-up-tool]
- Other
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
[chain-tool]: /doc/tool-utils/chain-tool.md
[set-up-tool]: /doc/tool-utils/set-up-tool.md
[v3-upgrade-guide]: /doc/v3-upgrade-guide.md
