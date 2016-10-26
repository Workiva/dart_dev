// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:args/args.dart';
import 'package:args/src/parser.dart';

import 'package:dart_dev/src/lenient_args/lenient_arg_results.dart';

class LenientParser extends Parser {
  static LenientArgResults parseArgs(ArgParser argParser, List<String> args) =>
      new LenientParser(null, argParser, args.toList(), null, null).parse();

  List<String> _unknownOptions = [];

  LenientParser(commandName, grammar, args, parent, rest)
      : super(commandName, grammar, args, parent, rest);

  /// Parses the arguments. This can only be called once.
  ///
  /// Instead of throwing when an unrecognized option/flag is found (like
  /// [Parser] does), this will store them and continue parsing.
  @override
  LenientArgResults parse() {
    var arguments = args.toList();
    LenientArgResults commandResults = null;

    // Parse the args.
    while (args.length > 0) {
      if (current == '--') {
        // Reached the argument terminator, so stop here.
        args.removeAt(0);
        break;
      }

      // Try to parse the current argument as a command. This happens before
      // options so that commands can have option-like names.
      var command = grammar.commands[current];
      if (command != null) {
        validate(rest.isEmpty, 'Cannot specify arguments before a command.');
        var commandName = args.removeAt(0);
        var commandParser =
            new LenientParser(commandName, command, args, this, rest);
        commandResults = commandParser.parse();

        // All remaining arguments were passed to command so clear them here.
        rest.clear();
        break;
      }

      // Try to parse the current argument as an option. Note that the order
      // here matters.
      try {
        if (parseSoloOption()) continue;
      } on FormatException {
        // Unknown solo option. Need to try to determine if this is a flag or an
        // option with a value.
        var unknownSoloOpt = args.removeAt(0);

        // If there are no more args, then it must be a flag.
        if (args.isEmpty) {
          _unknownOptions.add(unknownSoloOpt);
          continue;
        }

        // If there is another arg and it does not appear to be a new option,
        // then assume it is a value for this solo option.
        if (!args[0].startsWith('-')) {
          _unknownOptions.addAll([unknownSoloOpt, args.removeAt(0)]);
          continue;
        }

        // Otherwise, assume it is a flag.
        _unknownOptions.add(unknownSoloOpt);
        continue;
      }

      try {
        if (parseAbbreviation(this)) continue;
      } on FormatException {
        // Unknown abbreviation option. Abbreviations can either be a series of
        // collapsed abbreviations (like "-abc") or a single abbreviation with
        // the value directly attached to it (like "-mrelease"). Without the
        // option being defined, it's impossible to know which is correct.
        // Instead of guessing, store the entire arg as an unknown flag.
        _unknownOptions.add(args.removeAt(0));
        continue;
      }

      try {
        if (parseLongOption()) continue;
      } on FormatException {
        // Unknown long option.

        // If it contains "=", it's in the form "--mode=release".
        if (args[0].contains('=')) {
          _unknownOptions.add(args.removeAt(0));
          continue;
        }

        // Otherwise, it's either the long name for a flag ("--enable") or it's
        // an option in the form "--mode release". Unfortunately, there's no way
        // to know which it is. We can't assume the latter because the value
        // could also be a plain arg. Because of this, we'll assume it's a flag.

        // Otherwise, it must be in the form "--mode release".
        _unknownOptions.add(args.removeAt(0));
        continue;
      }

      // This argument is neither option nor command, so stop parsing unless
      // the [allowTrailingOptions] option is set.
      if (!grammar.allowTrailingOptions) break;
      rest.add(args.removeAt(0));
    }

    // Invoke the callbacks.
    grammar.options.forEach((name, option) {
      if (option.callback == null) return;
      option.callback(option.getOrDefault(results[name]));
    });

    // Add in the leftover arguments we didn't parse to the innermost command.
    rest.addAll(args);
    args.clear();
    return newLenientArgResults(grammar, results, _unknownOptions, commandName,
        commandResults, rest, arguments);
  }
}
