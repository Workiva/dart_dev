# Dart Dev Tooling

> Note: this is a WIP branch of version 3.0.0 of dart_dev.

## Installation

Add a dependency_override for dart_dev v3 to your `pubspec.yaml`:

```yaml
dependency_overrides:
  dart_dev:
    git:
      url: git@github.com:Workiva/dart_dev.git
      ref: v3_rework
```

## Running

```bash
$ pub run dart_dev
Dart tool runner.

Usage: dart_dev <command> [arguments]

Global options:
-h, --help       Print this usage information.
-v, --verbose    Enables verbose logging.

Available commands:
  analyze   Run static analysis on dart files in this package.
  format    Format dart files in this package.
  help      Display help information for dart_dev.
  serve     Run a local web development server and a file system watcher that rebuilds on changes.
  test      Run dart tests in this package.

Run "dart_dev help <command>" for more information about a command.
```

We recommend creating an alias to make this easier to run:

```bash
alias ddev="pub run dart_dev"
```

## Configuration

Add the following to your `tool/dev.dart`:

```dart
import 'package:dart_dev/configs/workiva.dart';
import 'package:dart_dev/dart_dev.dart';

final config = {
  // This is a base configuration created by the Workiva organization.
  ...workivaConfig,
};
```

If you'd like to add tools or configure existing ones, you can do so by adding
to the `config` map after including the workiva base config:

```dart
import 'package:dart_dev/configs/workiva.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...workivaConfig,
  'format': FormatTool()
    ..exclude = [Glob('lib/src/generated/**.dart')],
  'hello': DartFunctionTool(hello),
};

void hello({bool verbose}) {
  print('Hello world!');
}
```

You can also add before and after hooks to tools if certain setup/teardown logic
is desired:

```dart
import 'package:dart_dev/configs/workiva.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/utils.dart';

final config = {
  ...workivaConfig,

  'test': addHooks(
    TestTool(),
    before: [startTestServerTool],
    after: [stopTestServerTool],
  ),
};

void startTestServer({bool verbose}) { ... }
final startTestServerTool = DartFunctionTool(startTestServer);

void stopTestServer({bool verbose}) { ... }
final stopTestServerTool = DartFunctionTool(stopTestServer);
```
