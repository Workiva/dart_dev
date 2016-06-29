# Dart Dev Tools
[![Pub](https://img.shields.io/pub/v/dart_dev.svg)](https://pub.dartlang.org/packages/dart_dev)
[![Build Status](https://travis-ci.org/Workiva/dart_dev.svg?branch=master)](https://travis-ci.org/Workiva/dart_dev)
[![codecov.io](http://codecov.io/github/Workiva/dart_dev/coverage.svg?branch=master)](http://codecov.io/github/Workiva/dart_dev?branch=master)
[![documentation](https://img.shields.io/badge/Documentation-dart_dev-blue.svg)](https://www.dartdocs.org/documentation/dart_dev/latest/)

> Centralized tooling for Dart projects. Consistent interface across projects.
> Easily configurable.

- [**Motivation**](#motivation)
- [**Supported Tasks**](#supported-tasks)
- [**Getting Started**](#getting-started)
- [**Project Configuration**](#project-configuration)
- [**CLI Usage**](#cli-usage)
- [**Programmatic Usage**](#programmatic-usage)
- [**BONUS: Functional Test Code Coverage**](#functional-test-code-coverage)

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

#### Separation of Concerns
Every task supported in `dart_dev` is separated into three pieces:

1. API - programmatic execution via Dart code.
2. CLI - script-based execution via the `dart_dev` executable.
3. Configuration - singleton configuration instances for simple per-project configuration.

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
- **Serving Examples:** uses [`pub serve`](https://www.dartlang.org/tools/pub/cmd/pub-serve.html) to serve the project examples.
- **Applying a License to Source Files:** copies a LICENSE file to all applicable files.
- **Generate a test runner file:** that allows for faster test execution.


### Local Tasks

A local task is a script or program that is discovered by `dart_dev`. By
default, dart dev will recursively look for files in the project level `tool`
directory that match the filename pattern `(task_name)_task.(executable_type)`.
Any file matching this pattern is parsed and registered as a task.  The task
discovery will not follow symlink directories by default. Symlink directory
expansion can be enabled using the `followSymlinks` property in the `local`
configuration field.

Any arguments specified after the local task name are passed to the underlying
task process as command line arguments. For instance, 
`pub run dart_dev exampleTask --example-argument 23` would pass the example
argument and value as additions to the underlying system command
`dart exampleTask_task.dart --example-argument 23`. This allows the task to
parse its arguments independently of dart_dev.

Executable types identify how a given task should execute. Dart and bash
scripts are supported out of the box. The set of available executable types can
be expanded in the configuration as documented below.

## Getting Started

#### Install `dart_dev`
Add the following to your `pubspec.yaml`:
```yaml
dev_dependencies:
  coverage: "^0.7.3"
  dart_dev: "^1.0.0"
  dart_style: ">=0.1.8 <0.3.0"
  dartdoc: "^0.4.0"
  test: "^0.12.0"
```

#### Create an Alias (optional)
Add the following to your bash or zsh profile for convenience:
```
alias ddev='pub run dart_dev'
```

#### Bash Completion

Bash command completion is available and easy to use. You'll want to install
dart_dev globally: `pub global activate dart_dev`.

Add the following to your `.bashrc`:

```
eval "$(pub global run dart_dev bash-completion)"
```

If you are using Bash installed through Homebrew, you'll also need to install
the completion machinery with `brew install bash-completion`. Then make sure
something like the following is in your `.bashrc` file:

```
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi
```

Next time you load a Bash session you'll have basic completions for the `ddev`
alias described above.

#### Zsh Completion

The Bash completion script will work for Zsh as well, but requires a little
configuration. The following lines must all be found somewhere (and in this
order, though they needn't be adjacent to one another) in your `.zshrc` file,
or a file sourced from it:

```
autoload -U compinit
compinit
autoload -U bashcompinit
bashcompinit
eval "$(pub global run dart_dev bash-completion)"
```

#### Fish Completion

Symlink or copy the file `tool/ddev.fish` into `~/.config/fish/completions/`
(or wherever your completion scripts live).

The completions expect a function called `ddev`. To meet this expectation create
a new file in `~/.config/fish/functions` called `ddev.fish` and add the
following content to the file.

```fish
function ddev
  pub run dart_dev $argv
end
```

#### Configuration
In order to configure `dart_dev` for a specific project, run `ddev init` or
`pub run dart_dev init` to generate the configuration file. This should create a
`tool/dev.dart` file where each task can be configured as needed.

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

  // Define overrides for local task discovery
  config.local
    ..taskPaths.add('bin')
    ..commandFilePattern = '([a-zA-Z0-9]+)_task.([a-zA-Z0-9]+)'
    ..executables['go'] = ['go', 'run'];

  // Define the location of your test suites.
  config.test
    ..unitTests = ['test/unit/']
    ..integrationTests = ['test/integration/']
    ..functionalTests = ['test/functional'];

  // Execute the dart_dev tooling.
  await dev(args);
}
```

[Full list of configuration options](#project-configuration).


#### Try It Out
The tooling in `dart_dev` works out of the box with happy defaults for each
task. Run `ddev` or `pub run dart_dev` to see the help usage. Try it out by
running any of the following tasks:

```
# with the alias
ddev analyze
ddev copy-license
ddev coverage
ddev docs
ddev examples
ddev format
ddev gen-test-runner
ddev test

# without the alias
pub run dart_dev analyze
pub run dart_dev copy-license
pub run dart_dev coverage
pub run dart_dev docs
pub run dart_dev examples
pub run dart_dev format
pub run dart_dev gen-test-runner
pub run dart_dev test
```

Add the `-h` flag to any of the above commands to receive additional help
information specific to that task.


## Project Configuration
Project configuration occurs in the `tool/dev.dart` file where the `config`
instance is imported from the `dart_dev` package. The bare minimum for this file
is:

```dart
import 'package:dart_dev/dart_dev.dart';

main(args) async {
  // Available config objects:
  config.analyze
  config.copyLicense
  config.coverage
  config.docs
  config.examples
  config.format
  config.genTestRunner
  config.init
  config.test

  await dev(args);
}
```

#### `analyze` Config
All configuration options for the `analyze` task are found on the
`config.analyze` object.

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>entryPoints</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>['lib/']</code></td>
            <td>Entry points to analyze. Items in this list can be directories and/or files. Directories will be expanded (depth=1) to find Dart files.</td>
        </tr>
        <tr>
            <td><code>fatalWarnings</code></td>
            <td><code>bool</code></td>
            <td><code>true</code></td>
            <td>Treat non-type warnings as fatal.</td>
        </tr>
        <tr>
            <td><code>hints</code></td>
            <td><code>bool</code></td>
            <td><code>true</code></td>
            <td>Show hint results.</td>
        </tr>
        <tr>
          	<td><code>fatalHints</code></td>
          	<td><code>bool</code></td>
          	<td><code>false</code></td>
          	<td>Fail on hints (requests hints to be true).</td>
        </tr>
        <tr>
            <td><code>strong</code></td>
            <td><code>bool</code></td>
            <td><code>false</code></td>
            <td><a href="https://goo.gl/DqcBsw">Enable strong static checks</a></td>
        </tr>
    </tbody>
</table>

#### `copy-license` Config
All configuration options for the `copy-license` task are found on the
`config.copyLicense` object.

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>directories</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>['lib/']</code></td>
            <td>All source files in these directories will have the LICENSE header applied.</td>
        </tr>
        <tr>
            <td><code>licensePath</code></td>
            <td><code>String</code></td>
            <td><code>'LICENSE'</code></td>
            <td>Path to the source LICENSE file that will be copied to all source files.</td>
        </tr>
    </tbody>
</table>

#### `coverage` config
All configuration options for the `coverage` task are found on the
`config.coverage` object. However, the `coverage` task also uses the test suite
configuration from the `config.test` object.

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>html</code></td>
            <td><code>bool</code></td>
            <td><code>true</code></td>
            <td>Whether or not to generate the HTML report.</td>
        </tr>
        <tr>
            <td><code>output</code></td>
            <td><code>String</code></td>
            <td><code>'coverage/'</code></td>
            <td>Output directory for coverage artifacts.</td>
        </tr>
        <tr>
            <td><code>reportOn</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>['lib/']</code></td>
            <td>List of paths to include in the generated coverage report (LCOV and HTML).</td>
        </tr>
        <tr>
            <td><code>pubServe</code></td>
            <td><code>bool</code></td>
            <td><code>false</code></td>
            <td>Whether or not to serve browser tests using a Pub server.<br>If <code>true</code>, make sure to follow the <code>test</code> package's <a href="https://github.com/dart-lang/test#testing-with-barback">setup instructions</a> and include the <code>test/pub_serve</code> transformer.</td>
        </tr>
        <tr>
            <td><code>seleniumCommand</code></td>
            <td><code>String</code></td>
            <td><code>"selenium-server"</code></td>
            <td>Command used to execute Selenium for functional testing.</td>
        </tr>
        <tr>
            <td><code>seleniumSuccess</code></td>
            <td><code>String</code></td>
            <td><code>"Selenium Server is up and running"</code></td>
            <td>Value used to verify that Selenium has been started successfully.  This value is accurate for v2.48.0 of Selenium Server.</td>
        </tr>
    </tbody>
</table>

> Note: "lcov" must be installed in order to generate the HTML report.
>
> If you're using brew, you can install it with:
>    `brew update && brew install lcov`
>
> Otherwise, visit http://ltp.sourceforge.net/coverage/lcov.php

#### `docs` config
There are currently no project-configuration settings for the `docs` task.

#### `examples` Config
All configuration options for the `examples` task are found on the
`config.examples` object.

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>hostname</code></td>
            <td><code>String</code></td>
            <td><code>'localhost'</code></td>
            <td>The host name to listen on.</td>
        </tr>
        <tr>
            <td><code>port</code></td>
            <td><code>int</code></td>
            <td><code>8080</code></td>
            <td>The base port to listen on.</td>
        </tr>
    </tbody>
</table>

#### `format` Config
All configuration options for the `format` task are found on the `config.format`
object.

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>check</code></td>
            <td><code>bool</code></td>
            <td><code>false</code></td>
            <td>Dry-run; checks if formatter needs to be run and sets exit code accordingly.</td>
        </tr>
        <tr>
            <td><code>directories</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>['lib/']</code></td>
            <td>Directories to run the formatter on. All files (any depth) in the given directories will be formatted.</td>
        </tr>
    </tbody>
</table>

#### `gen-test-runner` Config
All configuration options for the `gen-test-runner` task are found on the `config.genTestRunner`
object.

##### `GenTestRunner`

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>configs</code></td>
            <td><code>List&lt;TestRunnerConfig&gt;</code></td>
            <td><code>[TestRunnerConfig()]</code></td>
            <td>The list of runner configurations used to create individual test runners</td>
        </tr>
        <tr>
            <td><code>check</code></td>
            <td><code>bool/code></td>
            <td><code>false</code></td>
            <td>If true, will only check to ensure the runner is up-to-date</td>
        </tr>
    </tbody>
</table>

**Note:** if you plan to use the `--check` option, be sure to exclude
the `generated_runner_test.dart` file from formatting. This can be done
by adding it to the `config.format.exclude` list.

#### Local Config
All configuration options for the local task discovery are found on the
`config.local` object.

##### Local Discovery
<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>taskPaths</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>['tool']</code></td>
            <td>A list of project level paths to search for file matching the task pattern.</td>
        </tr>
        <tr>
            <td><code>followSymlinks</code></td>
            <td><code>bool</code></td>
            <td><code>false</code></td>
            <td>Should dart dev expand on symbolic links encountered in any <code>taskPath</code>?</td>
        </tr>
        <tr>
            <td><code>commandFilePattern</code></td>
            <td><code>String</code></td>
            <td><code>'([a-zA-Z0-9]+)_task.([a-zA-Z0-9]+)'</code></td>
            <td>A Regular Expression which matches two groups that represent the task name and executable type.</td>
        </tr>
        <tr>
            <td><code>executables</code></td>
            <td><code>Map&lt;String, List&lt;String&gt;&gt;</code></td>
            <td><code>'{'dart': ['dart'], 'sh': ['bash'] }'</code></td>
            <td>A lookup table that matches an executable type to a set of strings to prefix the execution of a task file with.</td>
        </tr>
    </tbody>
</table>

##### `TestRunnerConfig`

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>dartHeaders</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>[]</code></td>
            <td>Any lines of dart code that should exist between test file imports and the main method</td>
        </tr>      
        <tr>
            <td><code>preTestCommands</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>[]</code></td>
            <td>Commands to be executed in the generated file's main method before test execution</td>
        </tr>        
        <tr>
            <td><code>directory</code></td>
            <td><code>String</code></td>
            <td><code>'test/'</code></td>
            <td>The directory to search for test files in</td>
        </tr>
        <tr>
            <td><code>env</code></td>
            <td><code>Environment</code></td>
            <td><code>Environment.browser</code></td>
            <td>The environment to run tests in ('vm' or 'browser')</td>
        </tr>
        <tr>
            <td><code>filename</code></td>
            <td><code>String</code></td>
            <td><code>'generated_runner'</code></td>
            <td>The name of the generated test runner file</td>
        </tr>
        <tr>
            <td><code>genHtml</code></td>
            <td><code>bool</code></td>
            <td><code>false</code></td>
            <td>Whether or not a companion html file should be generated</td>
        </tr>
        <tr>
            <td><code>htmlHeaders</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>[]</code></td>
            <td>The list of custom html elements to include in the companion html file</td>
        </tr>
    </tbody>
</table>

#### `test` Config
All configuration options for the `test` task are found on the `config.test`
object.

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>concurrency</code></td>
            <td><code>int</code></td>
            <td><code>4</code></td>
            <td>Number of concurrent test suites run.</td>
        </tr>
        <tr>
            <td><code>functionalTests</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>[]</code></td>
            <td>Functional test locations. Items in this list can be directories and/or files.</td>
        </tr>
        <tr>
            <td><code>integrationTests</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>[]</code></td>
            <td>Integration test locations. Items in this list can be directories and/or files.</td>
        </tr>
        <tr>
            <td><code>platforms</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>[]</code></td>
            <td>Platforms on which to run the tests (handled by the Dart test runner). See https://github.com/dart-lang/test#platform-selector-syntax for a full list of supported platforms.
            <strong>* Not all platforms are supported by all continuous integration servers.  Please consult your CI server's documentation for more details.</strong>
            </td>
        </tr>
        <tr>
            <td><code>unitTests</code></td>
            <td><code>List&lt;String&gt;</code></td>
            <td><code>['test/']</code></td>
            <td>Unit test locations. Items in this list can be directories and/or files.</td>
        </tr>
        <tr>
            <td><code>pubServe</code></td>
            <td><code>bool</code></td>
            <td><code>false</code></td>
            <td>Whether or not to serve browser tests using a Pub server.<br>If <code>true</code>, make sure to follow the <code>test</code> package's <a href="https://github.com/dart-lang/test#testing-with-barback">setup instructions</a> and include the <code>test/pub_serve</code> transformer.</td>
        </tr>
        <tr>
            <td><code>pubServePort</code></td>
            <td><code>int</code></td>
            <td><code>0</code></td>
            <td>Port used by the Pub server for browser tests.  The default value will randomly select an open port to use.</td>
        </tr>
    </tbody>
</table>
* Individual test files can be executed by appending their path to the end of the command.
```
ddev test path/to/test_name path/to/another/test_name
```

* Individual tests can be executed by passing in a test name or regex pattern of a test that would be loaded by the test runner
```
ddev test -n 'run only this test'
```

* A new `pub serve` instance is created for every test run. To use a specific `pub serve` instance, pass `--pub-serve-port` to the CLI.
```
$ pub serve --port 56001 test
$ ddev test --pub-serve --pub-serve-port 56001
```

## CLI Usage
This package comes with a single executable: `dart_dev`. To run this executable:
`ddev` or `pub run dart_dev`. This usage will simply display the usage help text
along with a list of supported tasks:

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
    gen-test-runner
    init
    test
```

- Static analysis: `ddev analyze`
- Applying license to source files: `ddev copy-license`
- Code coverage: `ddev coverage`
- Documentation generation: `ddev docs`
- Serving examples: `ddev examples`
- Dart formatter: `ddev format`
- Generate test runner: `ddev gen-test-runner`
- Initialization: `ddev init`
- Tests: `ddev test`

Add the `-h` flag to any of the above commands to see task-specific flags and options.

> Any project configuration defined in the `tool/dev.dart` file should be
> reflected in the execution of the above commands. CLI flags and options will
> override said configuration.


## Programmatic Usage
The tooling facilitated by this package can also be executed via a programmatic
Dart API:

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

> In order to provide a clean API, these methods do not leverage the
> configuration instances that the command-line interfaces do. Because of this,
> the default usage may be different. You can access said configurations from
> the main `package:dart_dev/dart_dev.dart` import.

## Functional Test Code Coverage

If you're running functional tests with [Selenium](http://www.seleniumhq.org/)
and [webdriver.dart](https://github.com/google/webdriver.dart), dart_dev can
help you run the Selenium standalone server and collect coverage from those
functional tests.

As the webdriver.dart project documents, `selenium-server-standalone` and
`chromedriver` are required dependencies.

### `selenium-server-standalone`

```
brew install selenium-server-standalone
```

> If you need to use multiple versions of Selenium, you can create a local
> executable and store it in your project's `tool/` directory (and check it in
> to version control). You can then pass the path to this local executable to
> the Selenium helper (see [configuring dart_dev to run Selenium](#configuring-dart_dev-to-run-selenium)).
>
> ```
> cd tool/
> curl -o selenium-server-standalone.jar http://selenium-release.storage.googleapis.com/2.48/selenium-server-standalone-2.48.2.jar
> echo '#!/usr/bin/env bash' | tee -a selenium-server
> echo 'DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"' | tee -a selenium-server
> echo 'exec java -jar $DIR/selenium-server-standalone.jar "$@"' | tee -a selenium-server
> chmod +x selenium-server
> ```

### `chromedriver`

Normally, `chromedriver` could be installed with brew, but to collect coverage,
the functional tests need to be run in Dartium, which requires an older version
of `chromedriver` (currently 2.14).

Download `chromedriver` 2.14 here:
```
https://chromedriver.storage.googleapis.com/index.html?path=2.14/
```

Unzip and run the executable once to place it in `/usr/local/bin/`.

### Configuring dart_dev to run Selenium

**tool/dev.dart**
```dart
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/util.dart' show SeleniumHelper;

main() async {
  // By default, this helper assumes the `selenium-server` executable is in the path
  var selenium = new SeleniumHelper();

  // If you have a local executable, point to it like so:
  var selenium = new SeleniumHelper(executablePath: 'tool/selenium-server');

  config.test
    ..before = [selenium.start]
    ..after = [selenium.stop];
}
```

> **Note:** you may also want to spin up a pub instance here to serve the
> application that will be exercised in your functional tests.

### Example functional test

```dart
import 'package:test/test.dart';
import 'package:webdriver/io.dart';

WebDriver driver;

void main() {
  setUp(() async {
    var options = {
      'browserName': 'chrome',
      'chromeOptions': {
        'binary': 'path/to/dartium'
      }
    };
    driver = await createDriver(desired: options);
  });

  // Do not quit the webdriver because the test and coverage tasks will handle
  // closing the browser when complete.
  //tearDown(() => driver.quit());

  test('test', () async {
    // This requires that your application is being served at localhost:8080
    await driver.get('http://localhost:8080');
    // interact with application
  });
}
```

> The `coverage` and `test` tasks will both handle closing any Dartium instances
> that were opened via the `WebDriver` once the tests are complete. You will
> need to omit the standard `tearDown(() => driver.quit());` from your test
> setups or code coverage cannot be collected.
