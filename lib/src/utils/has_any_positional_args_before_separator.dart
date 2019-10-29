// The utility in this file was originally modeled after:
// https://github.com/dart-lang/build/blob/14747dbf8c2f1bb44f89e2cb0726744278a23685/build_runner/lib/src/entrypoint/run_script.dart#L35-L63

import 'package:args/args.dart';

/// Returns `true` if any positional args are found in [argResults] before the
/// `--` separator, and `false` otherise.
bool hasAnyPositionalArgsBeforeSeparator(ArgResults argResults) {
  if (argResults.rest.isEmpty) {
    return false;
  }

  final separatorPos = argResults.arguments.indexOf('--');
  if (separatorPos < 0) {
    // `argResults.rest` is _not_ empty, but there is no `--` separator, so
    // there must be positional args before the (nonexistant) separator.
    return true;
  }

  final expectedRest = argResults.arguments.skip(separatorPos + 1).toList();
  if (argResults.rest.length != expectedRest.length) {
    // There number of args in the raw arguments list after the `--` separator
    // does not match the number of args in `argResults.rest`, which means there
    // must be some before the `--` separator.
    return true;
  }
  for (var i = 0; i < argResults.rest.length; i++) {
    if (expectedRest[i] != argResults.rest[i]) {
      // The expected arguments from the raw arguments list after the `--`
      // separator did not match exactly those found in `argResults.rest`.
      return true;
    }
  }

  return false;
}
