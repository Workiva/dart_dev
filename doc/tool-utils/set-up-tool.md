# `setUpTool()`

Sometimes it is useful to augment a tool with set-up and/or tear-down steps that
always run regardless of the outcome of that tool.

```dart
# tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'test': setUpTool(TestTool(),
    setUp: [DartFunctionTool(startTestServer)],
    tearDown: [DartFunctionTool(stopTestServer)],
  ),
};

Future<int> startTestServer(_) async { ... }
Future<int> stopTestServer(_) async { ... }
```

With `setUpTool`, there is one required tool, an optional list of tools to run
before it, and an optional list of tools to run after it. The required tool is
the only one that receives and parses args from the CLI. The tools will be run
sequentially and in order (setup tools, required tool, teardown tools). If any
of the tools return a non-zero exit code, that code will be returned at the end,
but all tools will run.

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
  - `setUpTool()`
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
