# Creating, Extending, and Composing Tools

## Create a tool from a function

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';
import 'package:io/io.dart';

int hello([DevToolExecutionContext context]) {
  print('Hello!');
  return ExitCode.success.code;
}

final config = {
  'hello': DevTool.fromFunction(hello),
};
```

```bash
$ ddev hello
Hello!
```

### Handling command-line args

```dart
// tool/dart_dev/config.dart
import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:io/io.dart';

final helloArgParser = ArgParser()
  ..addOption('name', help: 'Your name.');

int hello([DevToolExecutionContext context]) {
  var name;
  if (context?.argResults != null) {
    name = context.argResults['name'];
  }
  print('Hello${name != null ? ', $name' : ''}!');
  return ExitCode.success.code;
}

final config = {
  'hello': DevTool.fromFunction(hello, argParser: helloArgParser),
};
```

```bash
$ ddev hello --name Dart
Hello, Dart!
```

## Create a tool that runs a subprocess

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'github': DevTool.fromProcess(
      'open', ['https://github.com/Workiva/dart_dev']),
};
```

### Using command-line args with a subprocess tool

If you want to dynamically build a subprocess or run it conditionally based on
command-line args, you can compose the function and process tools like so:

```dart
// tool/dart_dev/config.dart
import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:io/io.dart';

final githubArgParser = ArgParser()..addFlag('open');

FutureOr<int> github([DevToolExecutionContext context]) async {
  final url = 'https://github.com/Workiva/dart_dev';
  final shouldOpen = context?.argResults != null && context.argResults['open'];
  if (shouldOpen) {
    return DevTool.fromProcess('open', [url]).run();
  }
  print(url);
  return ExitCode.success.code;
}

final config = {
  'github': DevTool.fromFunction(github, argParser: githubArgParser),
};
```

```bash
$ ddev github
https://github.com/Workiva/dart_dev

$ ddev github --open
# opens https://github.com/Workiva/dart_dev in browser
```

## `CompoundTool`

`CompoundTool` is designed to make it easy to compose multiple tools into a
single tool that can be run via a single `ddev` target.

Additionally, each tool added to a `CompoundTool` can be configured with one of
two possible run conditions:

1. When passing: run only when all previous tools have succeeded (**default**)
2. Always: run regardless of the success/failure of previous tools

Configuring a tool to always run is useful for set-up and tear-down tools, like
starting and stopping a test server before and after running tests,
respectively.

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';
import 'package:io/io.dart';

int startServer([DevToolExecutionContext context]) {
  // Start server and wait for it to be ready...
  return ExitCode.success.code;
}

int stopServer([DevToolExecutionContext context]) {
  // Stop server...
  return ExitCode.success.code;
}

final config = {
  'test': CompoundTool()
    ..addTool(DevTool.fromFunction(startServer), alwaysRun: true)
    ..addTool(TestTool())
    ..addTool(DevTool.fromFunction(stopServer), alwaysRun: true),
};
```

### Sharing state across tools

With more complex use cases, it may be necessary to share or use state across
the individual tools that make up a compound tool. To accomplish this, you can
either create a closure or a class within which to share said state.

```dart
// tool/dart_dev/config.dart
import 'package:args/args.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:io/io.dart';

class NewAnalyzeTool extends AnalyzeTool with CompoundToolMixin {
  NewAnalyzeTool() {
    addTool(
      DevTool.fromFunction(
        _parseStrictMode,
        argParser: _strictModeArgParser,
      ),
    );
    addTool(
      DevTool.fromFunction(
        _runAnalyzeTool,
        argParser: AnalyzeTool().argParser,
      ),
    );
  }

  bool _strictModeEnabled;

  final _strictModeArgParser = ArgParser()..addFlag('strict');

  int _parseStrictMode([DevToolExecutionContext context]) {
    _strictModeEnabled = context?.argResults != null &&
        context.argResults['strict'] ?? false;
    return ExitCode.success.code;
  }

  Future<int> _runAnalyzeTool([DevToolExecutionContext context]) {
    // Build an AnalyzeTool instance using this "NewAnalyzeTool"
    // instance as the base config.
    final analyzeTool = AnalyzeTool()
      ..analyzerArgs = analyzerArgs
      ..include = include;

    // Augment the configuration if strict mode is enabled.
    if (_strictModeEnabled) {
      (analyzeTool.analyzerArgs ??= []).addAll([
        '--fatal-lints',
        '--fatal-infos',
        '--fatal-warnings',
      ]);
    }

    return analyzeTool.run(context);
  }
}

// Consume and configure the NewAnalyzeTool as if it were an instance of
// the AnalyzeTool, when in reality it is a compound tool.
final config = {
  'analyze': NewAnalyzeTool()
    ..analyzerArgs = ['--no-implicit-dynamic'],
};
```

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
