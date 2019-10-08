import 'package:args/args.dart';

import 'has_any_positional_args_before_separator.dart';

void assertNoPositionalArgs(
  String name,
  ArgResults argResults,
  void usageException(String message), {
  bool beforeSeparator,
}) {
  beforeSeparator ??= false;
  if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
    usageException('The "$name" command does not support positional args'
        '${beforeSeparator ? ' before the `--` separator' : ''}.\n');
  }
}
