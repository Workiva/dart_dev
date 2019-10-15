# `FormatTool`

Formats dart files in the current project by running `dartfmt`.

## Usage

> _This tool is included in the [`coreConfig`][core-config] and is runnable by
> default via `ddev format`._

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'format': FormatTool() // configure as necessary
};
```

## Default behavior

By default this tool will run `dartfmt -w .` which will format all dart files in
the current project.

## Configuration

### Default mode

`FormatTool` can be run in 3 modes:

1. `FormatMode.overwrite`(default)
2. `FormatMode.dryRun` (lists files that would be changed)
3. `FormatMode.check` (dry-run _and_ sets the exit code if changes are needed)

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'format': FormatTool()
    ..defaultMode = FormatMode.check
};
```

### Using the `dart_style` package instead of `dartfmt`

Some projects like to depend on a specific version of the `dart_style` package
and use its `format` executable rather than the `dartfmt` provided by the Dart
SDK.

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'format': FormatTool()
    ..formatter = Formatter.dartStyle
};
```

### Passing args to the formatter process

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'format': FormatTool()
    ..formatterArgs = ['--fix']
};
```

```bash
$ ddev format
[INFO] Running subprocess...
dartfmt -w --fix .
----------------------------
```

### Excluding files from formatting

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  'format': FormatTool()
    ..exclude = [Glob('test_fixtures/**'), Glob('**.g.dart')]
};
```

## Command-line options

```bash
$ ddev help format
```

---
---

<!-- Table of Contents -->

- Tools
  - [`AnalyzeTool`][analyze-tool]
  - [`DartFunctionTool`][dart-function-tool]
  - `FormatTool`
  - [`ProcessTool`][process-tool]
  - [`TestTool`][test-tool]
  - [`TuneupCheckTool`][tuneup-check-tool]
  - [`WebdevBuildTool`][webdev-build-tool]
  - [`WebdevServeTool`][webdev-serve-tool]
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
