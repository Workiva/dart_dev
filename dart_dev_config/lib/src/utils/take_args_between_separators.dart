Iterable<String> takeArgsBetweenSeparators(List<String> args, {int skip}) {
  List<String> result;
  skip ??= 0;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--') {
      if (skip-- == 0) {
        result = args.skip(i + 1).toList();
        break;
      }
    }
  }
  result ??= [];
  return result.contains('--') ? result.take(result.indexOf('--')) : result;
}
