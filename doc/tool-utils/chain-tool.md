# `chainTool()`

Sometimes it is useful to compose multiple units of functionality together into
a single target.

```dart
# tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'custom-build': chainTool(WebdevBuildTool(),
    before: [
      ProcessTool('npm', ['dist']),
    ],
    after: [
      DartFunctionTool(stageStaticAssets),
    ])
};

int stageStaticAssets(_) { ... }
```

With `chainTool`, there is one required tool, an optional list of tools to run
before it, and an optional list of tools to run after it. The required tool is
the only one that receives and parses args from the CLI. The tools will be run
sequentially and in order (before tools, required tool, after tools), and if any
of them return a non-zero code, the chain will exit immediately.

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
  - `chainTool()`
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
