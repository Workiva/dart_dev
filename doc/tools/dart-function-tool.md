# `DartFunctionTool`

Runs a Dart function callback.

## Usage

This tool is intended to be used as an easy way to integrate Dart code into the
dart_dev executable. Common usages include executing setup or teardown logic or
logging some information and this tool is often used in tandem with the
[`chainTool()`][chain-tool] and [`setUpTool()`][set-up-tool] utilities.

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'test': setUpTool(TestTool(),
    setUp: DartFunctionTool(setUpServer),
    tearDown: DartFunctionTool(tearDownServer))
};

int setUpServer(_) { ... };
int tearDownServer(_) { ... };
```

---
---

<!-- Table of Contents -->

- Tools
  - [`AnalyzeTool`][analyze-tool]
  - `DartFunctionTool`
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
