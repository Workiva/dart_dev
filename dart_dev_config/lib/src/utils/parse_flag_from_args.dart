bool parseFlagFromArgs(List<String> args, String name,
    {String abbr, bool defaultsTo, bool negatable}) {
  defaultsTo ??= false;
  negatable ??= false;

  for (var i = 0; i < args.length; i++) {
    // If an arg separator is encountered, stop processing args.
    if (args[i] == '--') {
      break;
    }

    // Return true if the flag is found.
    if (args[i] == '--$name') {
      return true;
    }

    // Return true if the abbreviated flag is found.
    if (abbr != null && abbr.isNotEmpty && args[i] == '-$abbr') {
      return true;
    }

    // Return false if the flag is negatable and the negated version is found.
    if (negatable && args[i] == '--no-$name') {
      return false;
    }
  }

  return defaultsTo;
}
