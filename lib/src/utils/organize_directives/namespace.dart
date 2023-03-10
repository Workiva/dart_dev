import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

/// A representation of an namespace directive.
///
/// Capable of tracking comments that should be associated with an namespace
/// during organization (which cannot be represented by the AST)
class Namespace {
  /// The AST node that represents an namespace in a file.
  final NamespaceDirective directive;

  /// Comments that appear before the namespace that should stay with the
  /// namespace when organized.
  List<Token> beforeComments = [];

  /// Comments that appear after the namespace that should stay with the
  /// namespace when organized.
  List<Token> afterComments = [];

  /// The file being imported/exported.
  String get target {
    return directive.uri.stringValue!;
  }

  /// If the namespace is a dart namespace. Memoized for performance.
  bool? _isDart;
  bool get isDart {
    return _isDart ??= target.startsWith('dart:');
  }

  /// If the namespace is an external package namespace. Memoized for performance.
  bool? _isExternalPkg;
  bool get isExternalPkg {
    return _isExternalPkg ??= target.startsWith('package:');
  }

  /// If the namespace is a relative namespace. Memoized for performance.
  bool? _isRelative;
  bool get isRelative {
    return _isRelative ??= !isExternalPkg && !isDart;
  }

  Namespace(this.directive);

  /// The character offset of the start of the namespace statement in source text.
  /// Excludes comments associated with this namespace.
  int get statementStart => directive.beginToken.charOffset;

  /// The character offset of the end of the namespace statement in source text.
  /// Excludes comments associated with this namespace.
  int get statementEnd => directive.endToken.end;

  /// The character offset of the end of this namespace in source text.
  /// Includes comments associated with this namespace.
  int end() {
    var end = directive.endToken.end;
    for (final afterComment in afterComments) {
      if (afterComment.end > end) {
        end = afterComment.end;
      }
    }
    return end;
  }

  /// The character offset of the start of this namespace in source text.
  /// Includes comments associated with this namespace.
  int start() {
    var charOffset = directive.beginToken.charOffset;
    for (final beforeComment in beforeComments) {
      if (beforeComment.charOffset < charOffset) {
        charOffset = beforeComment.charOffset;
      }
    }
    return charOffset;
  }
}
