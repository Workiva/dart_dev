import 'package:args/args.dart';

bool hasArgsAfterSeparator(ArgResults argResults) {
  final sepPos = argResults.arguments.indexOf('--');
  return sepPos != -1 && sepPos != argResults.arguments.length - 1;
}
