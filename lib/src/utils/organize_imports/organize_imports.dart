import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'import.dart';
import 'import_collector.dart';

/// Takes in a file as a string and organizes the imports.
/// Sorts imports and removes double quotes.
///
/// Throws an ArgumentError if [sourceFileContents] cannot be parsed.
String organizeImports(String sourceFileContents) {
  final imports =
      parseString(content: sourceFileContents).unit.accept(ImportCollector());
  if (imports.isEmpty) {
    return sourceFileContents;
  }

  _assignCommentsInFileToImport(sourceFileContents, imports);

  final firstImportStartIdx = imports.first.start();
  final lastImportEndIdx = imports.last.end();
  imports.sort(_importComparator);
  final sortedImportString =
      _getSortedImportString(sourceFileContents, imports);
  return sourceFileContents.replaceRange(
      firstImportStartIdx, lastImportEndIdx + 1, sortedImportString);
}

/// Puts comments in a source file with the correct import so they can be moved
/// with the import when sorted.
///
/// The parser puts "precedingComments" on each token. However, an import's
/// precedingComments shouldn't necessarily be the comments that move with the
/// import during a sort. If an import has a trailing comment on the same line
/// as an import, it will be attached to the next Token's "precedingComments".
///
/// For this reason, we go thru all imports (and the first token after the last
/// import), look at their precedingComments, and determine which import they
/// belong to.
void _assignCommentsInFileToImport(
    String sourceFileContents, List<Import> imports) {
  Import prevImport;
  for (var importIndex = 0; importIndex < imports.length; importIndex++) {
    final currImport = imports[importIndex];

    _assignCommentsBeforeTokenToImport(
      currImport.directive.beginToken,
      sourceFileContents,
      prevImport,
      currImport: currImport,
    );

    prevImport = currImport;
  }

  /// Assign comments after the last import to the last import if they are on
  /// the same line.
  _assignCommentsBeforeTokenToImport(
      prevImport.directive.endToken.next, sourceFileContents, prevImport);
}

/// Assigns comments before [token] to [prevImport] if on the same line as
/// [prevImport]. Else it assigns the comment to [currImport], if it exists.
void _assignCommentsBeforeTokenToImport(
  Token token,
  String sourceFileContents,
  Import prevImport, {
  Import currImport,
}) {
  // `precedingComments` returns the first comment before token.
  // Calling `comment.next` returns the next comment.
  // Returns null when there are no more comments left.
  for (Token comment = token.precedingComments;
      comment != null;
      comment = comment.next) {
    if (_commentIsOnSameLineAsImport(comment, prevImport, sourceFileContents)) {
      prevImport.afterComments.add(comment);
    } else if (currImport != null) {
      currImport.beforeComments.add(comment);
    }
  }
}

/// Checks if a given comment is on the same line as an import.
/// It's expected that import end is before comment start.
bool _commentIsOnSameLineAsImport(
    Token comment, Import import, String sourceFileContents) {
  return import != null &&
      !sourceFileContents
          .substring(import.directive.endToken.end, comment.charOffset)
          .contains('\n');
}

/// Converts a list of sorted imports into a plain text string.
String _getSortedImportString(String sourceFileContents, List<Import> imports) {
  final sortedReplacement = StringBuffer();
  final firstRelativeImportIdx =
      imports.indexWhere((import) => import.isRelativeImport);
  final firstPkgImportIdx =
      imports.indexWhere((import) => import.isExternalPkgImport);
  for (var importIndex = 0; importIndex < imports.length; importIndex++) {
    final import = imports[importIndex];
    if (importIndex != 0 &&
        (importIndex == firstRelativeImportIdx ||
            importIndex == firstPkgImportIdx)) {
      sortedReplacement.write('\n');
    }
    final importDirectiveWithQuotesReplaced = sourceFileContents
        .substring(import.statementStart, import.statementEnd)
        .replaceAll('"', "'");

    final source = sourceFileContents
        .replaceRange(
          import.statementStart,
          import.statementEnd,
          importDirectiveWithQuotesReplaced,
        )
        .substring(import.start(), import.end());
    sortedReplacement..write(source)..write('\n');
  }
  return sortedReplacement.toString();
}

/// A comparator that will sort dart imports first, then package imports, then
/// relative imports.
int _importComparator(Import first, Import second) {
  if (first.isDartImport && second.isDartImport) {
    return first.target.compareTo(second.target);
  }

  if (first.isDartImport && !second.isDartImport) {
    return -1;
  }

  if (!first.isDartImport && second.isDartImport) {
    return 1;
  }

  // Neither are dart imports
  final firstIsPkg = first.isExternalPkgImport;
  final secondIsPkg = second.isExternalPkgImport;
  if (firstIsPkg && secondIsPkg) {
    return first.target.compareTo(second.target);
  }

  if (firstIsPkg && !secondIsPkg) {
    return -1;
  }

  if (!firstIsPkg && secondIsPkg) {
    return 1;
  }

  // Neither are dart imports or pkg imports. Must be relative path imports...
  return first.target.compareTo(second.target);
}
