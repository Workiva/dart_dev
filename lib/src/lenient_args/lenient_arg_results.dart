import 'dart:collection';

import 'package:args/args.dart';

ArgResults newLenientArgResults(
    ArgParser parser,
    Map<String, dynamic> parsed,
    List<String> unknown,
    String name,
    ArgResults command,
    List<String> rest,
    List<String> arguments) {
  return new LenientArgResults._(
      parser, parsed, unknown, name, command, rest, arguments);
}

class LenientArgResults implements ArgResults {
  /// The [ArgParser] whose options were parsed for these results.
  final ArgParser _parser;

  /// The option values that were parsed from arguments.
  final Map<String, dynamic> _parsed;

  /// The options that were unknown but still parsed.
  final List<String> _unknown;

  /// If these are the results for parsing a command's options, this will be the
  /// name of the command. For top-level results, this returns `null`.
  final String name;

  /// The command that was selected, or `null` if none was.
  ///
  /// This will contain the options that were selected for that command.
  final ArgResults command;

  /// The remaining command-line arguments that were not parsed as options or
  /// flags.
  ///
  /// If `--` was used to separate the options from the remaining arguments,
  /// it will not be included in this list unless parsing stopped before the
  /// `--` was reached.
  final List<String> rest;

  /// The original list of arguments that were parsed.
  final List<String> arguments;

  /// Creates a new [LenientArgResults].
  LenientArgResults._(this._parser, this._parsed, this._unknown, this.name,
      this.command, List<String> rest, List<String> arguments)
      : this.rest = new UnmodifiableListView(rest),
        this.arguments = new UnmodifiableListView(arguments);

  /// Gets the parsed command-line option named [name].
  operator [](String name) {
    if (!_parser.options.containsKey(name)) {
      throw new ArgumentError('Could not find an option named "$name".');
    }

    return _parser.options[name].getOrDefault(_parsed[name]);
  }

  /// Get the names of the available options as an [Iterable].
  ///
  /// This includes the options whose values were parsed or that have defaults.
  /// Options that weren't present and have no default will be omitted.
  Iterable<String> get options {
    var result = new Set<String>.from(_parsed.keys);

    // Include the options that have defaults.
    _parser.options.forEach((name, option) {
      if (option.defaultValue != null) result.add(name);
    });

    return result;
  }

  Iterable<String> get unknownOptions => new Set<String>.from(_unknown);

  /// Returns `true` if the option with [name] was parsed from an actual
  /// argument.
  ///
  /// Returns `false` if it wasn't provided and the default value or no default
  /// value would be used instead.
  bool wasParsed(String name) {
    var option = _parser.options[name];
    if (option == null) {
      throw new ArgumentError('Could not find an option named "$name".');
    }

    return _parsed.containsKey(name);
  }
}
