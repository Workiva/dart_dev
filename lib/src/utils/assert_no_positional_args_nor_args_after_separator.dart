import 'package:args/args.dart';

import 'has_args_after_separator.dart';

void assertNoPositionalArgsNorArgsAfterSeparator(
    ArgResults argResults, void Function(String msg) usageException,
    {String? commandName, String? usageFooter, bool allowRest = false}) {
  if ((argResults.rest.isNotEmpty && !allowRest) ||
      hasArgsAfterSeparator(argResults)) {
    usageException('${commandName != null ? 'The "$commandName"' : 'This'} '
        'command does not support positional args nor args after a separator.'
        '${usageFooter != null ? '\n$usageFooter' : ''}');
  }
}
