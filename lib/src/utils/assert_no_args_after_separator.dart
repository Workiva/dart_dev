import 'package:args/args.dart';

import 'has_args_after_separator.dart';

void assertNoArgsAfterSeparator(
    ArgResults argResults, void Function(String msg) usageException,
    {String? commandName, String? usageFooter}) {
  if (hasArgsAfterSeparator(argResults)) {
    usageException('${commandName != null ? 'The "$commandName"' : 'This'} '
        'command does not support args after a separator.'
        '${usageFooter != null ? '\n$usageFooter' : ''}');
  }
}
