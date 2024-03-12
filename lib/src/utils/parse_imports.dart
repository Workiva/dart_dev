import 'package:collection/collection.dart';

/// Return the contents of the enquoted portion of the import statements in the
/// file. Not 100% accurate, since we use regular expressions instead of the
/// Dart AST to extract the imports.
Iterable<String> parseImports(String fileContents) =>
    RegExp(r'''^import ['"]([^'"]+)['"];?$''', multiLine: true)
        .allMatches(fileContents)
        .map((m) => m.group(1))
        .whereNotNull();
