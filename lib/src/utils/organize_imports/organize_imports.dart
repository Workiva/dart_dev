import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'namespace.dart';
import 'namespace_collector.dart';

/// Takes in a file as a string and organizes the imports and exports.
/// Sorts imports/exports and removes double quotes.
///
/// Throws an ArgumentError if [sourceFileContents] cannot be parsed.
String organizeImports(String sourceFileContents) {
  final namespaces = parseString(content: sourceFileContents)
      .unit
      .accept(NamespaceCollector());

  if (namespaces.isEmpty) {
    return sourceFileContents;
  }

  _assignCommentsInFileToNamespaceDirective(sourceFileContents, namespaces);

  final firstNamespaceStartIdx = namespaces.first.start();
  final lastNamespaceEndIdx = namespaces.last.end();
  final imports = namespaces
      .where((element) => element.directive is ImportDirective)
      .toList();
  final exports = namespaces
      .where((element) => element.directive is ExportDirective)
      .toList();
  imports.sort(_namespaceComparator);
  exports.sort(_namespaceComparator);
  final sortedImportString =
      _getSortedNamespaceString(sourceFileContents, imports);
  final sortedExportString =
      _getSortedNamespaceString(sourceFileContents, exports);
  final sortedDirectives = [
    if (sortedImportString.isNotEmpty) sortedImportString,
    if (sortedExportString.isNotEmpty) sortedExportString
  ].join('\n');
  return sourceFileContents.replaceRange(
    firstNamespaceStartIdx,
    lastNamespaceEndIdx + 1,
    sortedDirectives,
  );
}

/// Puts comments in a source file with the correct namespace directive so they
/// can be moved with the directive when sorted.
///
/// The parser puts "precedingComments" on each token. However, an import's
/// precedingComments shouldn't necessarily be the comments that move with the
/// import during a sort. If an import has a trailing comment on the same line
/// as an import, it will be attached to the next Token's "precedingComments".
///
/// For this reason, we go thru all imports (and the first token after the last
/// import), look at their precedingComments, and determine which import they
/// belong to.
void _assignCommentsInFileToNamespaceDirective(
  String sourceFileContents,
  List<Namespace> namespaces,
) {
  Namespace prevNamespace;
  for (var namespace in namespaces) {
    final currNamespace = namespace;

    _assignCommentsBeforeTokenToNamespace(
      currNamespace.directive.beginToken,
      sourceFileContents,
      prevNamespace,
      currNamespace: currNamespace,
    );

    prevNamespace = currNamespace;
  }

  /// Assign comments after the last import to the last import if they are on
  /// the same line.
  _assignCommentsBeforeTokenToNamespace(
    prevNamespace.directive.endToken.next,
    sourceFileContents,
    prevNamespace,
  );
}

/// Assigns comments before [token] to [prevNamespace] if on the same line as
/// [prevNamespace]. Else it assigns the comment to [currNamespace], if it exists.
void _assignCommentsBeforeTokenToNamespace(
  Token token,
  String sourceFileContents,
  Namespace prevNamespace, {
  Namespace currNamespace,
}) {
  // `precedingComments` returns the first comment before token.
  // Calling `comment.next` returns the next comment.
  // Returns null when there are no more comments left.
  for (Token comment = token.precedingComments;
      comment != null;
      comment = comment.next) {
    if (_commentIsOnSameLineAsNamespace(
        comment, prevNamespace, sourceFileContents)) {
      prevNamespace.afterComments.add(comment);
    } else if (currNamespace != null) {
      currNamespace.beforeComments.add(comment);
    }
  }
}

/// Checks if a given comment is on the same line as an import.
/// It's expected that import end is before comment start.
bool _commentIsOnSameLineAsNamespace(
    Token comment, Namespace namespace, String sourceFileContents) {
  return namespace != null &&
      !sourceFileContents
          .substring(namespace.directive.endToken.end, comment.charOffset)
          .contains('\n');
}

/// Converts a list of sorted namespaces into a plain text string.
String _getSortedNamespaceString(
  String sourceFileContents,
  List<Namespace> namespaces,
) {
  final sortedReplacement = StringBuffer();
  final firstRelativeImportIdx =
      namespaces.indexWhere((import) => import.isRelativeImport);
  final firstPkgImportIdx =
      namespaces.indexWhere((import) => import.isExternalPkgImport);
  for (var importIndex = 0; importIndex < namespaces.length; importIndex++) {
    final import = namespaces[importIndex];
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
int _namespaceComparator(Namespace first, Namespace second) {
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
