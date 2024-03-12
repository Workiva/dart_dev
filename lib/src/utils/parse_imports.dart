import 'package:collection/collection.dart';

/// Return the contents of the enquoted portion of the import statements in the
/// file. Not 100% accurate, since we use regular expressions instead of the
/// Dart AST to extract the imports.
Iterable<String> parseImports(String fileContents) =>
    _importRegex.allMatches(fileContents).map((m) => m.group(1)).whereNotNull();

final _importRegex =
    RegExp(r'''^import ['"]([^'"]+)['"];?$''', multiLine: true);

/// Return a set of package names given a list of imports.
Set<String> computePackageNamesFromImports(Iterable<String> imports) => imports
    .map((i) => _packageNameFromImportRegex.matchAsPrefix(i)?.group(1))
    .whereNotNull()
    .toSet();

final _packageNameFromImportRegex = RegExp(r'package:([^/]+)/.+');
