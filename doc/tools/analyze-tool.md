# `AnalyzeTool`

Statically analyzes the current project by running the `dartanalyzer`.

## Usage

> _This tool is included in the [`coreConfig`][core-config] and is runnable by
> default via `ddev analyze`._

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'analyze': AnalyzeTool() // configure as necessary
};
```

## Default behavior

By default this tool will run `dartanalyzer .` which will analyze all dart files
in the current project.

## Configuration

`AnalyzeTool` supports one configuration option which is the list of args to
pass to the `dartanalyzer` process:

```dart
// tool/dart_dev/config.dart
import 'package:dart_dev/dart_dev.dart';

final config = {
  'analyze': AnalyzeTool()
    ..analyzerArgs = ['--fatal-infos', '--fatal-warnings']
};
```

> _Always prefer configuring the analyzer via `analysis_options.yaml` when
> possible. This ensures that other tools that leverage the analyzer or the
> analysis server benefit from the configuration, as well._

## Excluding files from analysis

The `analysis_options.yaml` configuration file
[supports excluding files][analysis-exclude]. However, there is an
[open issue with the `dartanalyzer` CLI][analyzer-exclude-issue] because it does
not respect this list.

If your project has files that need to be excluded from analysis (e.g. generated
files), use the [`TuneupCheckTool`][tuneup-check-tool]. It uses the
`tuneup` package to run analysis instead of `dartanalyzer` and it properly
respects the exclude rules defined in `analysis_options.yaml`.

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
  - `AnalyzeTool`
  - [`DartFunctionTool`][dart-function-tool]
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
