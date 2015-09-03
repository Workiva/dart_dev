# Dart Dev Tools
[![Pub](https://img.shields.io/pub/v/dart_dev.svg)](https://pub.dartlang.org/packages/dart_dev) [![Build Status](https://travis-ci.org/Workiva/dart_dev.svg?branch=master)](https://travis-ci.org/Workiva/dart_dev) [![codecov.io](http://codecov.io/github/Workiva/dart_dev/coverage.svg?branch=master)](http://codecov.io/github/Workiva/dart_dev?branch=master)

> Centralized tooling for Dart projects. Consistent interface across projects. Easily configurable.

- [**Motivation**](#motivation)
- [**Supported Tasks**](#supported-tasks)
- [**Getting Started**](#getting-started)
- [**Project Configuration**](#project-configuration)
- [**CLI Usage**](#cli-usage)
- [**Programmatic Usage**](#programmatic-usage)

## Motivation

All Dart (https://dartlang.org) projects eventually share a common set of development requirements:

- Tests (unit, integration, and functional)
- Code coverage
- Consistent code formatting
- Static analysis to detect issues
- Documentation generation
- Examples for manual testing/exploration
- Applying a LICENSE file to all source files

Together, the Dart SDK and a couple of packages from the Dart team supply the necessary tooling to support the above
requirements. But, the usage is inconsistent, configuration is limited to command-line arguments, and you inevitably end
up with a slew of shell scripts in the `tool/` directory. While this works, it lacks a consistent usage pattern across
multiple projects and requires an unnecessary amount of error-prone work to set up.

This package improves on the above process by providing a number of benefits:

#### Centralized Tooling
By housing the APIs and CLIs for these various dev workflows in a single location, you no longer have to worry about
keeping scripts in parity across multiple projects. Simply add the `dart_dev` package as a dependency, and you're ready
to go.

#### Versioned Tooling
Any breaking changes to the APIs or CLIs within this package will be reflected by an appropriate version bump according
to semver. You can safely upgrade your tooling to take advantage of continuous improvements and new features with
minimal maintenance.

#### Separation of Concerns
Every task supported in `dart_dev` is separated into three pieces:

1. API - programmatic execution via Dart code.
2. CLI - script-based execution via the `dart_dev` executable.
3. Configuration - singleton configuration instances for simple per-project configuration.

#### Consistent Interface
By providing a single executable (`dart_dev`) that supports multiple tasks with standardized options, project developers
have a consistent interface for development across all projects that utilize this package. Configuration is handled on a
per-project basis via a single Dart file, meaning that you don't have to know anything about a project to run tests or
static analysis - you just need to know how to use the `dart_dev` tool.


> **Note:** This is __not__ a replacement for the tooling provided by the Dart SDK and packages like `test` or
`dart_style`. Rather, `dart_dev` is a unified interface for interacting with said tooling in a simplified manner.


## Supported Tasks

- **Tests:** runs test suites (unit, integration, and functional) via the [`test` package test runner](https://github.com/dart-lang/test).
- **Coverage:** collects coverage over test suites (unit, integration, and functional) and generates a report. Uses the [`coverage` package](https://github.com/dart-lang/coverage).
- **Code Formatting:** runs the [`dartfmt` tool from the `dart_style` package](https://github.com/dart-lang/dart_style) over source code.
- **Static Analysis:** runs the [`dartanalyzer`](https://www.dartlang.org/tools/analyzer/) over source code.
- **Documentation Generation:** runs the tool from [the `dartdoc` package](https://github.com/dart-lang/dartdoc) to generate docs. 
- **Serving Examples:** uses [`pub serve`](https://www.dartlang.org/tools/pub/cmd/pub-serve.html) to serve the project examples.
- **Applying a License to Source Files:** copies a LICENSE file to all applicable files.


## Getting Started

###### Install `dart_dev`
Add the following to your `pubspec.yaml`:
```yaml
dev_dependencies:
  coverage: "^0.7.2"
  dart_dev: "^1.0.0"
  dart_style: ">=0.1.8 <0.3.0"
  dartdoc: "^0.4.0"
  test: "^0.12.0"
```

###### Create an Alias (optional)
Add the following to your bash or zsh profile for convenience:
```
alias ddev='pub run dart_dev'
```

###### Configuration
In order to configure `dart_dev` for a specific project, run `ddev init` or `pub run dart_dev init` to generate the
configuration file. This should create a `tool/dev.dart` file where each task can be configured as needed.

```dart
import 'package:dart_dev/dart_dev.dart';

main(args) async {
  // Define the entry points for static analysis.
  config.analyze.entryPoints = ['lib/', 'test/', 'tool/'];
  
  // Define the directories where the LICENSE should be applied.
  config.copyLicense.directories = ['example/', 'lib/'];

  // Configure whether or not the HTML coverage report should be generated.
  config.coverage.html = false;
  
  // Configure the port on which examples should be served.
  config.examples.port = 9000;
  
  // Define the directories to include when running the
  // Dart formatter.
  config.format.directories = ['lib/', 'test/', 'tool/'];
  
  // Define the location of your test suites.
  config.test
    ..unitTests = ['test/unit/']
    ..integrationTests = ['test/integration/'];

  // Execute the dart_dev tooling.
  await dev(args);
}
```

[Full list of configuration options](#project-configuration).


###### Try It Out
The tooling in `dart_dev` works out of the box with happy defaults for each task. Run `ddev` or `pub run dart_dev` to
see the help usage. Try it out by running any of the following tasks:

```
# with the alias
ddev analyze
ddev copy-license
ddev coverage
ddev docs
ddev examples
ddev format
ddev test

# without the alias
pub run dart_dev analyze
pub run dart_dev copy-license
pub run dart_dev coverage
pub run dart_dev docs
pub run dart_dev examples
pub run dart_dev format
pub run dart_dev test
```

Add the `-h` flag to any of the above commands to receive additional help information specific to that task.


## Project Configuration
Project configuration occurs in the `tool/dev.dart` file where the `config` instance is imported from the `dart_dev`
package. The bare minimum for this file is:

```dart
import 'package:dart_dev/dart_dev.dart';

main(args) async {
  // Available config objects:
  //   config.analyze
  //   config.copyLicense
  //   config.coverage
  //   config.docs
  //   config.examples
  //   config.format
  //   config.init
  //   config.test
  
  await dev(args);
}
```

### `analyze` Config
All configuration options for the `analyze` task are found on the `config.analyze` object.

Name            | Type           | Default    | Description
--------------- | -------------- | ---------- | -----------
`entryPoints`   | `List<String>` | `['lib/']` | Entry points to analyze. Items in this list can be directories and/or files. Directories will be expanded (depth=1) to find Dart files.
`fatalWarnings` | `bool`         | `true`     | Treat non-type warnings as fatal.
`hints`         | `bool`         | `true`     | Show hint results.

### `copy-license` Config
All configuration options for the `copy-license` task are found on the `config.copyLicense` object.

Name          | Type           | Default    | Description
------------- | -------------- | ---------- | -----------
`directories` | `List<String>` | `['lib/']` | All source files in these directories will have the LICENSE header applied.
`licensePath` | `String`       | `LICENSE`  | Path to the source LICENSE file that will be copied to all source files.

### `coverage` config
All configuration options for the `coverage` task are found on the `config.coverage` object.
However, the `coverage` task also uses the test suite configuration from the `config.test` object.

Name       | Type           | Default     | Description
---------- | -------------- | ----------- | -----------
`html`     | `bool`         | `true`      | Whether or not to generate the HTML report.
`output`   | `String`       | `coverage/` | Output directory for coverage artifacts.
`reportOn` | `List<String>` | `['lib/']`  | List of paths to include in the generated coverage report (LCOV and HTML).

> Note: "lcov" must be installed in order to generate the HTML report.
>
> If you're using brew, you can install it with:
>    `brew update && brew install lcov`
>
> Otherwise, visit http://ltp.sourceforge.net/coverage/lcov.php

### `docs` config
There are currently no project-configuration settings for the `docs` task.

### `examples` Config
All configuration options for the `examples` task are found on the `config.examples` object.

Name       | Type     | Default       | Description
---------- | -------- | ------------- | -----------
`hostname` | `String` | `'localhost'` | The host name to listen on.
`port`     | `int`    | `8080`        | The base port to listen on.

### `format` Config
All configuration options for the `format` task are found on the `config.format` object.

Name          | Type           | Default     | Description
------------- | -------------- | ----------- | -----------
`check`       | `bool`         | `false`     | Dry-run; checks if formatter needs to be run and sets exit code accordingly.
`directories` | `List<String>` | `['lib/']`  | Directories to run the formatter on. All files (any depth) in the given directories will be formatted.

### `test` Config
All configuration options for the `test` task are found on the `config.test` object.

Name               | Type           | Default     | Description
------------------ | -------------- | ----------- | -----------
`concurrency`      | `int`          | `4`         | Number of concurrent test suites run.
`integrationTests` | `List<String>` | `[]`        | Integration test locations. Items in this list can be directories and/or files.
`platforms`        | `List<String>` | `[]`        | Platforms on which to run the tests (handled by the Dart test runner). See https://github.com/dart-lang/test#platform-selector-syntax for a full list of supported platforms.
`unitTests`        | `List<String>` | `['test/']` | Unit test locations. Items in this list can be directories and/or files.


## CLI Usage
This package comes with a single executable: `dart_dev`. To run this executable: `ddev` or `pub run dart_dev`. This
usage will simply display the usage help text along with a list of supported tasks:

```
$ ddev
Standardized tooling for Dart projects.

Usage: pub run dart_dev [task] [options]

    --[no-]color    Colorize the output.
                    (defaults to on)

-h, --help          Shows this usage.
-q, --quiet         Minimizes the logging output.
    --version       Shows the dart_dev package version.

Supported tasks:

    analyze
    copy-license
    coverage
    docs
    examples
    format
    init
    test
```

- Static analysis: `ddev analyze`
- Applying license to source files: `ddev copy-license`
- Code coverage: `ddev coverage`
- Documentation generation: `ddev docs`
- Serving examples: `ddev examples`
- Dart formatter: `ddev format`
- Initialization: `ddev init`
- Tests: `ddev test`

Add the `-h` flag to any of the above commands to see task-specific flags and options.

> Any project configuration defined in the `tool/dev.dart` file should be reflected in the execution of the above
commands. CLI flags and options will override said configuration.


## Programmatic Usage
The tooling facilitated by this package can also be executed via a programmatic Dart API:

```dart
import 'package:dart_dev/api.dart' as api;

main() async {
  await api.analyze();
  await api.serveExamples();
  await api.format();
  await api.init();
  await api.test();
}
```

Check out the source of these API methods for additional documentation.

> In order to provide a clean API, these methods do not leverage the configuration instances that the command-line
interfaces do. Because of this, the default usage may be different. You can access said configurations from the main
`package:dart_dev/dart_dev.dart` import.