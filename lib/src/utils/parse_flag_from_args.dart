bool parseFlagFromArgs(List<String> args, String name,
    {String? abbr, bool? defaultsTo, bool? negatable}) {
  defaultsTo ??= false;
  negatable ??= false;

  // Ignore all args after a separator.
  final argsBeforeSep = args.takeWhile((arg) => arg != '--').toList();

  // Iterate in reverse so that in the event of multiple instances of the flag,
  // the last one wins.
  for (var i = argsBeforeSep.length - 1; i >= 0; i--) {
    // Return true if the flag is found.
    if (argsBeforeSep[i] == '--$name') {
      return true;
    }

    // Return true if the abbreviated flag is found.
    if (abbr != null && abbr.isNotEmpty && argsBeforeSep[i] == '-$abbr') {
      return true;
    }

    // Return false if the flag is negatable and the negated version is found.
    if (negatable && argsBeforeSep[i] == '--no-$name') {
      return false;
    }
  }

  return defaultsTo;
}
