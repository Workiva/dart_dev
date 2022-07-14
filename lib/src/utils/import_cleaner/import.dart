import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

/// A representation of an import.
///
/// Capable of tracking comments that should be associated with an import during a sort (which cannot be
/// represented by the AST)
class Import {
  /// The AST node that represents an import in a file.
  final ImportDirective directive;

  /// Comments that appear before the import that should stay with the import when sorted.
  List<Token> beforeComments = [];

  /// Comments that appear after the import that should stay with the import when sorted.
  List<Token> afterComments = [];

  /// The file being imported.
  String get target {
    return directive.uri.stringValue;
  }

  /// If the import is a dart import. Memoized for performance.
  bool _isDartImport;
  bool get isDartImport {
    return _isDartImport ??= target.startsWith('dart:');
  }

  /// If the import is an external package import. Memoized for performance.
  bool _isExternalPkgImport;
  bool get isExternalPkgImport {
    return _isExternalPkgImport ??= target.startsWith('package:');
  }

  /// If the import is a relative import. Memoized for performance.
  bool _isRelativeImport;
  bool get isRelativeImport {
    return _isRelativeImport ??= !isExternalPkgImport && !isDartImport;
  }

  Import(this.directive);

  /// The character offset of the end of this import in source text (includes comments associated with this import).
  int end() {
    var end = directive.endToken.end;
    for (final afterComment in afterComments) {
      if (afterComment.end > end) {
        end = afterComment.end;
      }
    }
    return end;
  }

  /// The character offset of the start of this import in source text (includes comments associated with this import).
  int charOffset() {
    var charOffset = directive.beginToken.charOffset;
    for (final beforeComment in beforeComments) {
      if (beforeComment.charOffset < charOffset) {
        charOffset = beforeComment.charOffset;
      }
    }
    return charOffset;
  }
}
