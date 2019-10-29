# `TuneupCheckTool`

Statically analyzes the current project via the `tuneup` package.

## Usage

This is intended to be used as a drop-in replacement to the
[`AnalyzeTool`][analyze-tool] to workaround an
[open issue with `dartanalyzer` and excluding files][analyzer-exclude-issue] via
`analysis_options.yaml`.

Add `tuneup` as a dev dependency to your project:

```yaml
# pubspec.yaml
dev_dependencies:
  tuneup: ^0.3.6
```

Use it in your dart_dev config:

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'analyze': TuneupCheckTool()
};
```

## Default behavior

By default this tool will run `pub run tuneup check` which will analyze all dart
files in the current project.

## Ignoring info outputs

By default, `pub run tuneup check` will include "info"-level analysis messages
in its output and fail if there are any. You can tell tuneup to ignore these:

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'analyze': TuneupCheckTool()
    ..ignoreInfos = true,
};
```

## Excluding files from analysis

The `analysis_options.yaml` configuration file
[supports excluding files][analysis-exclude].

## Command-line options

```bash
$ ddev help analyze
```

[analyzer-exclude-issue]: https://github.com/dart-lang/sdk/issues/25551
[analysis-exclude]: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

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
