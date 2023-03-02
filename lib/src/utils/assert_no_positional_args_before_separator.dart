import 'package:args/args.dart';

import 'has_any_positional_args_before_separator.dart';

void assertNoPositionalArgs(
  String name,
  ArgResults argResults,
  void Function(String message) usageException, {
  bool? beforeSeparator,
}) {
  beforeSeparator ??= false;
  if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
    usageException('The "$name" command does not support positional args'
        '${beforeSeparator ? ' before the `--` separator' : ''}.\n');
  }
}
