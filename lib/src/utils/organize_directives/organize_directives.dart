import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'namespace.dart';
import 'namespace_collector.dart';

/// Takes in a file as a string and organizes the imports and exports.
/// Sorts imports/exports and removes double quotes.
///
/// Throws an ArgumentError if [sourceFileContents] cannot be parsed.
String organizeDirectives(String sourceFileContents) {
  final directives = parseString(content: sourceFileContents)
      .unit
      .accept(NamespaceCollector())!;

  if (directives.isEmpty) {
    return sourceFileContents;
  }

  final namespaces = _assignCommentsInFileToNamespaceDirective(
    sourceFileContents,
    directives,
  );
  final sortedDirectives = _organizeDirectives(sourceFileContents, namespaces);
  return _replaceDirectives(sourceFileContents, namespaces, sortedDirectives);
}

/// Replaces the namespace directives in a source file with a given string.
///
/// Namespaces should be sorted in the order they appear in the source file.
String _replaceDirectives(
  String sourceFileContents,
  List<Namespace> namespaces,
  String replaceString,
) {
  final firstNamespaceStartIdx = namespaces.first.start();
  final lastNamespaceEndIdx = namespaces.last.end();
  return sourceFileContents.replaceRange(
    firstNamespaceStartIdx,
    lastNamespaceEndIdx + 1,
    replaceString,
  );
}

/// Returns a sorted string of namespace directives.
String _organizeDirectives(
  String sourceFileContents,
  List<Namespace> namespaces,
) {
  final sortedImports = _organizeDirectivesOfType<ImportDirective>(
    sourceFileContents,
    namespaces,
  );
  final sortedExports = _organizeDirectivesOfType<ExportDirective>(
    sourceFileContents,
    namespaces,
  );

  return [
    if (sortedImports.isNotEmpty) sortedImports,
    if (sortedExports.isNotEmpty) sortedExports
  ].join('\n');
}

/// Returns a sorted string of namespace directives of a given type.
String _organizeDirectivesOfType<T>(
  String sourceFileContents,
  List<Namespace> namespaces,
) {
  final directives =
      namespaces.where((element) => element.directive is T).toList();

  directives.sort(_namespaceComparator);

  return _getSortedNamespaceString(sourceFileContents, directives);
}

/// Puts comments in a source file with the correct namespace directive so they
/// can be moved with the directive when sorted.
///
/// The parser puts "precedingComments" on each token. However, a directive's
/// precedingComments shouldn't necessarily be the comments that move with the
/// directive during a sort. If a directive has a trailing comment on the same
/// line as a directive, it will be attached to the next Token's
/// "precedingComments".
///
/// For this reason, we go thru all directives (and the first token after the
/// last directive), look at their precedingComments, and determine which
/// directive they belong to.
List<Namespace> _assignCommentsInFileToNamespaceDirective(
  String sourceFileContents,
  List<NamespaceDirective> directives,
) {
  final namespaces = <Namespace>[];

  Namespace? prevNamespace;
  for (var directive in directives) {
    final currNamespace = Namespace(directive);
    namespaces.add(currNamespace);

    _assignCommentsBeforeTokenToNamespace(
      currNamespace.directive.beginToken,
      sourceFileContents,
      prevNamespace,
      currNamespace: currNamespace,
    );

    prevNamespace = currNamespace;
  }

  // Assign comments after the last directive to the last directive if they are
  // on the same line.
  _assignCommentsBeforeTokenToNamespace(
    prevNamespace!.directive.endToken.next!,
    sourceFileContents,
    prevNamespace,
  );
  return namespaces;
}

/// Assigns comments before [token] to [prevNamespace] if on the same line as
/// [prevNamespace]. Else it assigns the comment to [currNamespace], if it exists.
void _assignCommentsBeforeTokenToNamespace(
  Token token,
  String sourceFileContents,
  Namespace? prevNamespace, {
  Namespace? currNamespace,
}) {
  // `precedingComments` returns the first comment before token.
  // Calling `comment.next` returns the next comment.
  // Returns null when there are no more comments left.
  for (Token? comment = token.precedingComments;
      comment != null;
      comment = comment.next) {
    if (_commentIsOnSameLineAsNamespace(
        comment, prevNamespace, sourceFileContents)) {
      prevNamespace!.afterComments.add(comment);
    } else if (currNamespace != null) {
      currNamespace.beforeComments.add(comment);
    }
  }
}

/// Checks if a given comment is on the same line as a directive.
/// It's expected that directive end is before comment start.
bool _commentIsOnSameLineAsNamespace(
    Token comment, Namespace? namespace, String sourceFileContents) {
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
  final firstRelativeNamespaceIdx =
      namespaces.indexWhere((namespace) => namespace.isRelative);
  final firstPkgDirectiveIdx =
      namespaces.indexWhere((namespace) => namespace.isExternalPkg);
  for (var nsIndex = 0; nsIndex < namespaces.length; nsIndex++) {
    final namespace = namespaces[nsIndex];
    if (nsIndex != 0 &&
        (nsIndex == firstRelativeNamespaceIdx ||
            nsIndex == firstPkgDirectiveIdx)) {
      sortedReplacement.write('\n');
    }
    final namespaceWithQuotesReplaced = sourceFileContents
        .substring(namespace.statementStart, namespace.statementEnd)
        .replaceAll('"', "'");

    final source = sourceFileContents
        .replaceRange(
          namespace.statementStart,
          namespace.statementEnd,
          namespaceWithQuotesReplaced,
        )
        .substring(namespace.start(), namespace.end());
    sortedReplacement
      ..write(source)
      ..write('\n');
  }
  return sortedReplacement.toString();
}

/// A comparator that will sort dart directives first, then package directives,
/// then relative directives.
int _namespaceComparator(Namespace first, Namespace second) {
  if (first.isDart && second.isDart) {
    return first.target.compareTo(second.target);
  }

  if (first.isDart && !second.isDart) {
    return -1;
  }

  if (!first.isDart && second.isDart) {
    return 1;
  }

  // Neither are dart directives
  final firstIsPkg = first.isExternalPkg;
  final secondIsPkg = second.isExternalPkg;
  if (firstIsPkg && secondIsPkg) {
    return first.target.compareTo(second.target);
  }

  if (firstIsPkg && !secondIsPkg) {
    return -1;
  }

  if (!firstIsPkg && secondIsPkg) {
    return 1;
  }

  // Neither are dart directives or pkg directives. Must be relative path directives...
  return first.target.compareTo(second.target);
}
