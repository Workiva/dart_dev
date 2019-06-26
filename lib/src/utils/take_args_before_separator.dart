Iterable<String> takeArgsBeforeSeparator(List<String> args, {int skip}) {
  skip ??= 0;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--') {
      if (skip-- == 0) {
        return args.take(i);
      }
    }
  }
  return args;
}
