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
  var rCursor = 0;
  for (var aCursor = 0; aCursor < args.length; aCursor++) {
    // Iterate through the original args until we hit the first separator.
    if (args[aCursor] == '--') break;
    // While doing so, move a cursor through the rest args list each time we
    // match up between the original list and the rest args list. This works
    // because the rest args list should be an ordered subset of the original
    // args list.
    if (args[aCursor] == rest[rCursor]) {
      rCursor++;
    }
  }

  // At this point, [rCursor] should be pointing to the spot where the first arg
  // separator should be restored.
  return [...rest.sublist(0, rCursor), '--', ...rest.sublist(rCursor)];
}
