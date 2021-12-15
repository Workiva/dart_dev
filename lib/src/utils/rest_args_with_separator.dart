import 'package:args/args.dart';

/// Returns the "rest" args from [argResults], but with the arg separator "--"
/// restored to its original position if it was included.
///
/// This is necessary because [ArgResults.rest] will _not_ include the separator
/// unless it stopped parsing before it reached the separator.
///
/// The use case for this is a [CompoundTool] that uses the [takeAllArgs] arg
/// mapper, because the goal there is to forward on the original args minus the
/// consumed options and flags. If the separator has also been removed, you may
/// hit an error when trying to parse those args.
///
///     var parser = ArgParser()..addFlag('verbose', abbr: 'v');
///     var results = parser.parse(['a', '-v', 'b', '--', '--unknown', 'c']);
///     print(results.rest);
///     // ['a', 'b', '--unknown', 'c']
///     print(restArgsWithSeparator(results));
///     // ['a', 'b', '--', '--unknown', 'c']
List<String> restArgsWithSeparator(ArgResults argResults) {
  // If no separator was used, return the rest args as is.
  if (!argResults.arguments.contains('--')) {
    return argResults.rest;
  }

  final args = argResults.arguments;
  final rest = argResults.rest;
  var restIndex = 0;
  for (var argsIndex = 0; argsIndex < args.length; argsIndex++) {
    // Iterate through the original args until we hit the first separator.
    if (args[argsIndex] == '--') break;
    // While doing so, move a cursor through the rest args list each time we
    // match up between the original list and the rest args list. This works
    // because the rest args list should be an ordered subset of the original
    // args list.
    if (args[argsIndex] == rest[restIndex]) {
      restIndex++;
    }
  }

  // At this point, [restIndex] should be pointing to the spot where the first
  // arg separator should be restored.
  return [...rest.sublist(0, restIndex), '--', ...rest.sublist(restIndex)];
}
