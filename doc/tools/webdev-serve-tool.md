# `WebdevServeTool`

Runs a local web development server for the current project using the `webdev`
package.

## Usage

> _This tool is included in the [`coreConfig`][core-config] and is runnable by
> default via `ddev serve`._

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'serve': WebdevServeTool() // configure as necessary
};
```

## Default behavior

By default this tool will run `pub global run webdev serve` which will build the
`web/` directory using the Dart Dev Compiler and serve it on port 8080.

## Configuration

### Passing args to the webdev process

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'serve': WebdevServeTool()
    ..webdevArgs = ['--auto=refresh']
};
```

### Passing args to the underlying build_runner process

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'format': TestTool()
    ..buildArgs = ['--delete-conflicting-outputs']
};
```

## Command-line options

```bash
$ ddev help serve
```

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
  - `WebdevServeTool`
- Tool utilities
  - [`chainTool()`][chain-tool]
  - [`setUpTool()`][set-up-tool]
- Configs
  - [`coreConfig`][core-config]
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
[core-config]: /doc/configs/core-config.md
[v3-upgrade-guide]: /doc/v3-upgrade-guide.md
