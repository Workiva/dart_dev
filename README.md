# Dart Dev Tools
[![Pub](https://img.shields.io/pub/v/dart_dev.svg)](https://pub.dartlang.org/packages/dart_dev)

> Centralized tooling for Dart projects. Consistent interface across projects.
> Easily configurable.

- [**Motivation**](#motivation)
- [**Supported Tasks**](#supported-tasks)
- [**Getting Started**](#getting-started)

## Motivation

All Dart (https://dartlang.org) projects eventually share a common set of
development requirements:

- Tests (unit, integration, and functional)
- Code coverage
- Consistent code formatting
- Static analysis to detect issues
- Documentation generation
- Examples for manual testing/exploration
- Applying a LICENSE file to all source files
- Running dart unit tests on Sauce Labs

Together, the Dart SDK and a couple of packages from the Dart team supply the
necessary tooling to support the above requirements. But, the usage is
inconsistent, configuration is limited to command-line arguments, and you
inevitably end up with a slew of shell scripts in the `tool/` directory. While
this works, it lacks a consistent usage pattern across multiple projects and
requires an unnecessary amount of error-prone work to set up.

This package improves on the above process by providing a number of benefits:

#### Centralized Tooling
By housing the APIs and CLIs for these various dev workflows in a single
location, you no longer have to worry about keeping scripts in parity across
multiple projects. Simply add the `dart_dev` package as a dependency, and you're
ready to go.

#### Versioned Tooling
Any breaking changes to the APIs or CLIs within this package will be reflected
by an appropriate version bump according to semver. You can safely upgrade your
tooling to take advantage of continuous improvements and new features with
minimal maintenance.

#### Consistent Interface
By providing a single executable (`dart_dev`) that supports multiple tasks with
standardized options, project developers have a consistent interface for
development across all projects that utilize this package. Configuration is
handled on a per-project basis via a single Dart file, meaning that you don't
have to know anything about a project to run tests or static analysis - you just
need to know how to use the `dart_dev` tool.

> **Note:** This is __not__ a replacement for the tooling provided by the Dart
> SDK and packages like `test` or `dart_style`. Rather, `dart_dev` is a unified
> interface for interacting with said tooling in a simplified manner.


## Tasks

A task is a single unit of execution within `dart_dev`. They are identified by
a name and may or may not take arguments. Several supported tasks are provided
by default. Consumers can supplement the supported tasks with project specific
local tasks.

### Supported Tasks

- **Tests:** runs test suites (unit, integration, and functional) via the [`test` package test runner](https://github.com/dart-lang/test).
- **Coverage:** collects coverage over test suites (unit, integration, and functional) and generates a report. Uses the [`coverage` package](https://github.com/dart-lang/coverage).
- **Code Formatting:** runs the [`dartfmt` tool from the `dart_style` package](https://github.com/dart-lang/dart_style) over source code.
- **Static Analysis:** runs the [`dartanalyzer`](https://www.dartlang.org/tools/analyzer/) over source code.
- **Documentation Generation:** runs the tool from [the `dartdoc` package](https://github.com/dart-lang/dartdoc) to generate docs.
- **Applying a License to Source Files:** copies a LICENSE file to all applicable files.

## Getting Started

#### Install `dart_dev`
Add the following to your `pubspec.yaml`:
```yaml
dev_dependencies:
  coverage: ^0.8.0
  dart_dev: 2.0.0-alpha
  dart_style: ^0.2.0
  dartdoc: ^0.9.0
  test: ^0.12.0
```

#### Create an Alias (optional)
Add the following to your bash or zsh profile for convenience:
```
alias ddev='pub run dart_dev'
```

#### Configuration
In order to configure `dart_dev` for a specific project, you create a
`dart_dev.yaml` file in the root of your project.

```yaml
analyze:
  libraries:
    - bin/dart_dev.dart
    - lib/executable.dart
    - lib/hooks.dart

apply-license:
  license: LICENSE
  include:
    - bin/
    - lib/
  exclude:
    - lib/src/generated/

coverage:
  report_on:
    - bin/
    - lib/

format:
  include:
    - bin/
    - lib/
  exclude:
    - lib/src/generated/
```

#### Help

The executable has help output for the entire tool as well as each individual
task. Run `ddev --help` or `ddev [task] --help` to get more information!
